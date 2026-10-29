"
The coach mode of the right pane: the board (from my side) and a dialogue panel over a CoachReview. Board questions are answered by marking moves (arrows); written ones with a text field and quick-answer chips. Slow work (engine evaluation, LLM classification) runs through backgroundRunner; tests pass [ :work | work value ].
"
Class {
	#name : 'CoachElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'entry',
		'review',
		'game',
		'board',
		'header',
		'history',
		'currentZone',
		'markedMoves',
		'message',
		'busy',
		'backgroundRunner',
		'exitBlock',
		'answerField',
		'mode',
		'shownPly',
		'shownMoment',
		'walking',
		'noteField',
		'addingTag',
		'replay',
		'draft',
		'draftQuestion',
		'panelScroller'
	],
	#category : 'ChessCoach-UI-Coach',
	#package : 'ChessCoach-UI',
	#tag : 'Coach'
}

{ #category : 'instance creation' }
CoachElement class >> session: aChessCoachSession entry: aGameIndexEntry review: aCoachReview [

	^ self new
		  session: aChessCoachSession
		  entry: aGameIndexEntry
		  review: aCoachReview;
		  yourself
]

{ #category : 'actions' }
CoachElement >> addQuickAnswer: aString [
	"Append aString as a sentence, ending with a dot and a space so that typing can continue"

	| text |
	text := answerField text asString trimRight.
	(text notEmpty and: [ ('.!?' includes: text last) not ]) ifTrue: [
		text := text , '.' ].
	answerField text: (text isEmpty
			 ifTrue: [ aString , '. ' ]
			 ifFalse: [ text , ' ' , aString , '. ' ])
]

{ #category : 'accessing' }
CoachElement >> answerField [
	"The text field of the current written question, or nil"

	^ answerField
]

{ #category : 'actions' }
CoachElement >> backToList [

	review leaveMoment.
	markedMoves := OrderedCollection new.
	message := nil.
	shownMoment := nil.
	mode := #list.
	self refresh
]

{ #category : 'accessing' }
CoachElement >> backgroundRunner: aBlock [
	"aBlock receives the work block to run; tests pass [ :work | work value ]"

	backgroundRunner := aBlock
]

{ #category : 'accessing' }
CoachElement >> board [

	^ board
]

{ #category : 'building' }
CoachElement >> buildBoardAnswer [

	currentZone addChild: (self paragraph: 'Marked: '
			 , (self describeMoves: markedMoves in: review currentQuestion)).
	review currentQuestion kind = #candidates ifTrue: [
			currentZone addChild: (self paragraph:
					 'Your move is already marked in blue. Mark a move again to remove it.') ].
	currentZone addChild: (ChessCoachWidgets
			 primaryButton: 'Done'
			 icon: 'filled_arrowforward'
			 do: [ self submitMoves ])
]

{ #category : 'building' }
CoachElement >> buildEngineRevealOf: reveal before: before after: after [
	"Win chances, my candidates, the engine line, the line after my move to compare with it, and the reply I missed"

	| line myLine |
	line := (review analysis atPly: shownMoment ply - 1) bestLine.
	currentZone addChild: ((self paragraph:
				  ('Win chance: {1}% before your move, {2}% after it' format: {
							   ((reveal at: 'winBefore') printShowingDecimalPlaces: 0).
							   ((reveal at: 'winAfter') printShowingDecimalPlaces: 0) }))
			 tooltipString:
				 'Your chance of winning, from the engine evaluation (Lichess formula: +1.00 is about 59%, +3.00 about 75%). It shows how much a move changes the game better than pawns do.';
			 yourself).
	(reveal at: 'candidates') ifNotEmpty: [
			currentZone addChild:
				(self paragraph: 'Your candidates (win chance after each):') ].
	(reveal at: 'candidates') keysAndValuesDo: [ :move :win |
			currentZone addChild: (self paragraph: ('  {1}: {2}%' format: {
							  (before sanForUCI: move).
							  (win printShowingDecimalPlaces: 0) })) ].
	currentZone addChild:
		(self paragraph: ('Engine line ({1}): {2}' format: {
					  line scoreString.
					  (self lineInSAN: (reveal at: 'bestLine') from: before) })).
	(review analysis atPly: shownMoment ply) lines ifNotEmpty: [ :lines |
			myLine := lines first.
			currentZone addChild:
				(self paragraph: ('Your move {1} ({2}): {1} {3}' format: {
							  (before sanForUCI: self playedMove).
							  myLine scoreString.
							  (self lineInSAN: myLine moves from: after) })) ].
	(reveal at: 'engineReply') ifNotNil: [ :reply |
			currentZone addChild: (self paragraph:
					 ('Engine''s reply: {1} · you expected: {2}' format: {
							  (after sanForUCI: reply).
							  ((reveal at: 'expectedReply') isEmpty
								   ifTrue: [ 'nothing' ]
								   ifFalse: [
										   ', ' join:
											   ((reveal at: 'expectedReply') collect: [ :each |
												    after sanForUCI: each ]) ]) })) ]
]

{ #category : 'building' }
CoachElement >> buildList [

	| moments |
	currentZone addChild:
		(self row: (#( #all #mistakes #blunders ) collect: [ :each |
					  self
						  button: (each = self filter
								   ifTrue: [ '[' , (self filterLabel: each) , ']' ]
								   ifFalse: [ self filterLabel: each ])
						  do: [ self filter: each ] ])).
	self buildTimeBox.
	moments := review momentsPassing: self filter.
	moments ifEmpty: [
		currentZone addChild:
			(self paragraph: 'No moments with this filter.') ].
	moments do: [ :each |
			currentZone addChild: (self
					 button: (self describeMoment: each) , ((review isPlanned: each)
							  ifTrue: [ '' ]
							  ifFalse: [ ' · not planned' ])
					 icon: (self stateIconNameOf: each)
					 do: [ self showMoment: each ]) ].
	currentZone addChild:
		(self paragraph: ('Marking {1} · moments {2}' format: {
					  (self minutes: review markingSeconds).
					  (self minutes: review reviewingSeconds) })).
	currentZone addChild: (self row: {
				 (self
					  button: 'Continue review'
					  icon: 'outlined_playarrow'
					  do: [ self continueReview ]).
				 (self button: 'Summary' do: [ self showSummary ]).
				 (self button: 'Back' do: [ exitBlock value ]) })
]

{ #category : 'building' }
CoachElement >> buildMarking [

	| marked |
	currentZone addChild: (self paragraph:
			 'Go through the game and mark the moves you want to talk about. The engine''s view stays hidden. Keys: left/right arrows to move, Enter or Space to mark or unmark.').
	currentZone addChild: (self row: {
				 (self
					  button: ''
					  icon: 'outlined_chevronleft'
					  do: [ self showPly: shownPly - 1 ]).
				 (self
					  button: ''
					  icon: 'outlined_chevronright'
					  do: [ self showPly: shownPly + 1 ]) }).
	shownPly > 0 ifTrue: [
			marked := review isMarked: shownPly.
			currentZone addChild:
				(self paragraph: ('Move {1}: {2}{3}' format: {
							  (shownPly + 1 // 2).
							  (game moves at: shownPly) san.
							  (marked
								   ifTrue: [ ' (marked)' ]
								   ifFalse: [ '' ]) })).
			marked
				ifTrue: [
						currentZone addChild:
							(self
								 button: 'Unmark'
								 icon: 'outlined_flag'
								 do: [ self unmarkShown ]) ]
				ifFalse: [
						noteField := ChessCoachWidgets prose: (ToTextField new
								              hMatchParent;
								              yourself).
						currentZone
							addChild: (self paragraph: 'Note (optional):');
							addChild: noteField;
							addChild:
								(self
									 button: 'Mark'
									 icon: 'outlined_flag'
									 do: [ self markShown ]) ] ].
	currentZone addChild: (self paragraph: 'Marked: '
			 , (review marks ifEmpty: [ 'nothing yet' ] ifNotEmpty: [ :marks |
						  ', ' join:
							  (marks collect: [ :each |
								   (game moves at: (each at: 'ply')) san ]) ])).
	currentZone addChild: ChessCoachWidgets separator.
	currentZone addChild: (self row: {
				 (ChessCoachWidgets
					  primaryButton: 'Done marking'
					  icon: 'filled_arrowforward'
					  do: [ self doneMarking ]).
				 (self button: 'Back' do: [ exitBlock value ]) })
]

{ #category : 'building' }
CoachElement >> buildMoment [

	| question |
	(self isActive: shownMoment) ifFalse: [
			shownMoment isReviewed ifTrue: [ ^ self buildReveal ].
			currentZone addChild: (self paragraph: (shownMoment isStarted
						  ifTrue: [ 'You started this moment but did not finish it.' ]
						  ifFalse: [ 'Not reviewed yet.' ])).
			^ currentZone addChild: (self row: {
						   (self button: 'Review this moment' do: [ self reviewShown ]).
						   (self button: 'Back to list' do: [ self backToList ]) }) ].
	review isOverTime ifTrue: [
		currentZone addChild: (self paragraph: 'Time box reached.') ].
	shownMoment isRevealed ifTrue: [ ^ self buildReveal ].
	question := review currentQuestion.
	currentZone addChild: (self questionTitle: question).
	question expectsMoves
		ifTrue: [ self buildBoardAnswer ]
		ifFalse: [ self buildTextAnswer ].
	message ifNotNil: [ currentZone addChild: (self paragraph: message) ].
	currentZone addChild: ChessCoachWidgets separator.
	currentZone addChild: (self row: {
				 (self button: 'Stop' do: [ self stop ]).
				 (self button: 'Pause' do: [ self pause ]) })
]

{ #category : 'building' }
CoachElement >> buildReplay [
	"The marking pass shows the game with its move list: arrow keys step through it, Enter or Space marks the selected move"

	replay := GameAnalysisElement new.
	replay boardElement pieceSet: board pieceSet.
	replay boardElement orientation: self myColor.
	replay game: game.
	replay moveList markedPlies:
		(review marks collect: [ :each | each at: 'ply' ]).
	replay moveList whenMoveSelectedDo: [ :ply | self markingShows: ply ].
	replay moveList whenMarkRequestedDo: [ :ply | self toggleMarkAt: ply ]
]

{ #category : 'building' }
CoachElement >> buildReportComparison [

	| tags |
	tags := review tagsMoreThanUsualComparedTo: session mistakeDatabase.
	tags ifNil: [
			^ currentZone addChild:
				  (self paragraph:
					   'Not enough earlier reviews to compare with yet.') ].
	currentZone addChild: (self paragraph:
			 (tags ifEmpty: [ 'Nothing more than usual.' ] ifNotEmpty: [
					  'More than usual: ' , (', ' join:
						   (tags collect: [ :each |
							    (MistakeTaxonomy default tagAt: each) name ])) ]))
]

{ #category : 'building' }
CoachElement >> buildReportMistakes [
	"Counted tags grouped by category"

	| taxonomy counts |
	taxonomy := MistakeTaxonomy default.
	counts := review tagCounts.
	counts ifEmpty: [
		^ currentZone addChild: (self paragraph: 'No tagged mistakes.') ].
	taxonomy categories do: [ :category |
			| tags |
			tags := (taxonomy tagsInCategory: category) select: [ :tag |
				        (counts occurrencesOf: tag id) > 0 ].
			tags ifNotEmpty: [
					currentZone addChild: (self paragraph:
							 category capitalized , ': '
							 , (', ' join: (tags collect: [ :tag |
										   tag name , ' ×'
										   , (counts occurrencesOf: tag id) printString ]))) ] ]
]

{ #category : 'building' }
CoachElement >> buildReportNumbers [

	| kinds |
	kinds := review kindCounts.
	currentZone addChild:
		(self paragraph: ('Reviewed {1} of {2} moments' format: {
					  review reviewedMoments size.
					  (review momentsPassing: self filter) size })).
	currentZone addChild: (self paragraph: (' · ' join: ({
					   ('Blunders' -> #blunder).
					   ('Mistakes' -> #mistake).
					   ('Inaccuracies' -> #inaccuracy).
					   ('Only moves found' -> #onlyMoveFound).
					   ('Only moves missed' -> #onlyMoveMissed).
					   ('Long thinks' -> #longThink).
					   ('Opening choices' -> #openingChoice).
					   ('Your marks' -> #marked) }
					   select: [ :each | (kinds occurrencesOf: each value) > 0 ]
					   thenCollect: [ :each |
						   each key , ' '
						   , (kinds occurrencesOf: each value) printString ])))
]

{ #category : 'building' }
CoachElement >> buildReportTime [

	| times reviewed |
	times := session reviewTimes.
	reviewed := review reviewedMoments size.
	currentZone addChild:
		(self paragraph: ('Total {1} · marking {2}' format: {
					  (self minutes: review totalSeconds).
					  (self minutes: review markingSeconds) })).
	reviewed > 0 ifTrue: [
			currentZone addChild:
				(self paragraph:
					 ('Per moment: {1} here, {2} on average' format: {
							  (self minutes: review reviewingSeconds / reviewed).
							  (self minutes: times secondsPerMoment) })) ].
	review timeBox ifNotNil: [ :minutes |
			currentZone addChild:
				(self paragraph: ('Time box: {1} min planned, {2} used' format: {
							  minutes.
							  (self minutes: review totalSeconds) })) ]
]

{ #category : 'building' }
CoachElement >> buildReveal [
	"What the engine says, the time spent and the tags, in sections"

	| reveal before after |
	reveal := review revealOf: shownMoment.
	before := self positionBefore: shownMoment.
	after := game positionAfterPly: shownMoment ply.
	currentZone addChild: (self heading: 'The engine''s view').
	review hasEngine
		ifTrue: [
		self buildEngineRevealOf: reveal before: before after: after ]
		ifFalse: [
				currentZone addChild: (self paragraph:
						 'Stockfish isn''t available, so there is no engine evaluation for this moment.') ].
	currentZone addChild: (self paragraph:
			 'Time on this moment: ' , (self minutes: shownMoment seconds)).
	currentZone addChild: ChessCoachWidgets separator.
	currentZone addChild: (self heading: 'Mistakes').
	self buildTagsOf: shownMoment.
	currentZone addChild: ChessCoachWidgets separator.
	currentZone addChild:
		(self row: ((walking and: [ self isActive: shownMoment ])
				  ifTrue: [
						  {
							  (ChessCoachWidgets
								   primaryButton: 'Next moment'
								   icon: 'filled_arrowforward'
								   do: [ self nextMoment ]).
							  (self button: 'Stop' do: [ self stop ]).
							  (self button: 'Pause' do: [ self pause ]) } ]
				  ifFalse: [
				  { (self button: 'Back to list' do: [ self backToList ]) } ]))
]

{ #category : 'building' }
CoachElement >> buildSummary [
	"The review report: numbers, mistakes by category, tags more frequent than usual, time and the reviewed moments"

	currentZone addChild: (self heading: 'Numbers').
	self buildReportNumbers.
	currentZone addChild: (self heading: 'Mistakes').
	self buildReportMistakes.
	currentZone addChild:
		(self heading: 'Compared with your other games').
	self buildReportComparison.
	currentZone addChild: (self heading: 'Time').
	self buildReportTime.
	currentZone addChild: (self heading: 'Moments').
	review reviewedMoments do: [ :moment |
			currentZone addChild: (self
					 button: (self describeMoment: moment) , ' · '
						 , (', ' join: (moment countedLabels collect: [ :each |
									   (MistakeTaxonomy default tagAt: each tagId) name ]))
					 icon: (self stateIconNameOf: moment)
					 do: [ self showMoment: moment ]) ].
	currentZone addChild: (self row: {
				 (self button: 'Back to list' do: [ self backToList ]).
				 (self button: 'Back to the game' do: [ exitBlock value ]) })
]

{ #category : 'building' }
CoachElement >> buildTagPickerFor: aMomentReview [
	"Every tag not proposed yet, by category, with its description as tooltip"

	| taxonomy proposed |
	taxonomy := MistakeTaxonomy default.
	proposed := aMomentReview labels collect: [ :each | each tagId ].
	(taxonomy tags collect: [ :each | each category ]) asSet asArray sort
		do: [ :category |
				currentZone addChild: (self paragraph: category capitalized , ':').
				currentZone addChild: (self row: ((taxonomy tags select: [ :tag |
							   tag category = category and: [
								   (proposed includes: tag id) not ] ]) collect: [ :tag |
								  (self button: tag name do: [
											   addingTag := false.
											   self toggleTag: tag id ])
									  tooltipString: tag description;
									  yourself ])) ].
	currentZone addChild: (self button: 'Cancel' do: [
				 addingTag := false.
				 self refresh ])
]

{ #category : 'building' }
CoachElement >> buildTagsOf: aMomentReview [
	"Each proposed tag is a toggle with a check box icon: checked counts as a mistake, unchecked doesn't. Its label never changes: the percentage is how sure the model was, shown whether or not the tag is checked. The tag's description is its tooltip. When time trouble counts, it is shown as the main cause. Without the local model, the tag picker opens so the tags are chosen by hand."

	| taxonomy labels manual |
	(review isSuccess: aMomentReview) ifTrue: [
			^ currentZone addChild: (self paragraph: (aMomentReview isSuccess
						    ifTrue: [ 'Well found: no mistake to tag.' ]
						    ifFalse: [
						    'Your move was as good as the best one: no mistake to tag.' ])) ].
	taxonomy := MistakeTaxonomy default.
	manual := review isClassifierUnavailable and: [
		          aMomentReview isClassifying ].
	currentZone addChild: ((self paragraph:
				  'Checked tags count as mistakes in your stats; click one to change it. The percentage is how sure the coach model is that the tag fits your answers.')
			 tooltipString: 'Hover over a tag for its description.';
			 yourself).
	manual
		ifTrue: [
				currentZone addChild: (self paragraph:
						 'Ollama isn''t available, so your answers can''t be classified: choose the tags yourself.') ]
		ifFalse: [
				aMomentReview isClassifying ifTrue: [
					currentZone addChild: (self paragraph: '  classifying…') ] ].
	labels := aMomentReview labels asArray sort: [ :a :b |
			          a tagId = 'clock-management' or: [
				          b tagId ~= 'clock-management' and: [
					          a confidence >= b confidence ] ] ].
	(aMomentReview countedLabels anySatisfy: [ :each |
		 each tagId = 'clock-management' ]) ifTrue: [
			currentZone addChild: (self paragraph:
					 'Time trouble looks like the main cause; the other tags may matter less.') ].
	labels do: [ :label |
			| tag |
			tag := taxonomy tagAt: label tagId.
			currentZone addChild: ((self
					  button: tag name , ' · ' , tag category , ' ('
						  , (label confidence * 100) rounded printString , '%)'
					  icon: (label isRejected
							   ifTrue: [ 'outlined_checkboxoutlineblank' ]
							   ifFalse: [ 'outlined_checkbox' ])
					  do: [ self toggleTag: label tagId ])
					 tooltipString: tag description;
					 yourself) ].
	(manual or: [ addingTag == true ])
		ifTrue: [ self buildTagPickerFor: aMomentReview ]
		ifFalse: [
				currentZone addChild: (self button: 'Add a tag' do: [
							 addingTag := true.
							 self refresh ]) ]
]

{ #category : 'building' }
CoachElement >> buildTextAnswer [
	"Quick answers that fit the question; clicking one adds it to the field. The field starts with the draft of this question, if any. Shift+Enter answers, as the Answer button does."

	| chips |
	chips := ToElement new
		         layout: BlFlowLayout horizontal;
		         hMatchParent;
		         vFitContent;
		         yourself.
	(self quickAnswersFor: review currentQuestion) do: [ :each |
			chips addChild: (ToButton new
					 labelText: each;
					 clickAction: [ self addQuickAnswer: each ];
					 yourself) ].
	draftQuestion == review currentQuestion ifFalse: [
			draftQuestion := review currentQuestion.
			draft := '' ].
	answerField := ChessCoachWidgets prose: (ToAlbum new
			                hMatchParent;
			                height: 100;
			                text: draft;
			                yourself).
	answerField addShortcut: (BlShortcutWithAction new
			 combination: BlKeyCombination shiftReturn;
			 action: [ self submitText ]).
	currentZone
		addChild: chips;
		addChild: answerField;
		addChild: (ChessCoachWidgets
				 primaryButton: 'Answer'
				 icon: 'filled_arrowforward'
				 do: [ self submitText ])
]

{ #category : 'building' }
CoachElement >> buildTimeBox [
	"'≈ 18 of 20 min planned · 7 min so far', and a warning past the limit"

	review timeBox ifNil: [ ^ self ].
	currentZone addChild:
		(self paragraph: ('≈ {1} of {2} min planned · {3} so far' format: {
					  review plannedMinutes rounded.
					  review timeBox.
					  (self minutes: review totalSeconds) })).
	review isOverTime ifTrue: [
		currentZone addChild: (self paragraph: 'Time box reached.') ]
]

{ #category : 'private' }
CoachElement >> busy: aString while: aBlock then: aUIBlock [
	"Show aString while aBlock runs in the background, then run aUIBlock with aBlock's result and refresh. An error is logged and shown in the panel instead of opening a debugger."

	busy := aString.
	self refresh.
	backgroundRunner value: [
			| result failed |
			failed := false.
			result := [ aBlock value ]
				          on: Error
				          do: [ :error |
						          failed := true.
						          session logError: error.
						          'Something went wrong: ' , error class name , ': '
						          , (error messageText ifNil: [ '' ]) asString
						          , ' (details in errors.log)' ].
			self inUIDo: [
					busy := nil.
					failed
						ifTrue: [ message := result ]
						ifFalse: [ aUIBlock cull: result ].
					self refresh ] ]
]

{ #category : 'private' }
CoachElement >> button: aString do: aBlock [

	^ ToButton new
		  labelText: aString;
		  clickAction: aBlock;
		  yourself
]

{ #category : 'private' }
CoachElement >> button: aString icon: anIconName do: aBlock [
	"A button with a Material Design icon before its label"

	^ (self button: aString do: aBlock)
		  icon: ((ToMaterialDesignIconProvider iconNamed: anIconName)
				   extent: 18 @ 18;
				   yourself);
		  yourself
]

{ #category : 'private' }
CoachElement >> clockTextBefore: aPly [
	"' · 2:31 on your clock': the time I had left when I had to play the move at aPly (my clock after my previous move), or '' when the game has no clock times"

	| clock seconds |
	aPly <= 2 ifTrue: [ ^ '' ].
	clock := (game moves at: aPly - 2) timestamp ifNil: [ ^ '' ].
	seconds := clock asSeconds.
	^ ' · {1}:{2} on your clock' format: {
			  (seconds // 60).
			  (seconds \\ 60 printPaddedWith: $0 to: 2) }
]

{ #category : 'actions' }
CoachElement >> continueReview [
	"Walk through the moments not reviewed yet, in move order"

	walking := true.
	self startNextAfter: 0
]

{ #category : 'private' }
CoachElement >> currentQuestionOrNil [

	(mode = #moment and: [
		 (self isActive: shownMoment) and: [ shownMoment isRevealed not ] ])
		ifFalse: [ ^ nil ].
	^ review currentQuestion
]

{ #category : 'accessing' }
CoachElement >> currentZone [

	^ currentZone
]

{ #category : 'private' }
CoachElement >> describeMoment: aMomentReview [
	"'Move 14 (Ng5) · mistake · −18%'"

	^ 'Move {1} ({2}) · {3} · −{4}%' format: {
			  (aMomentReview ply + 1 // 2).
			  (game moves at: aMomentReview ply) san.
			  (', ' join: aMomentReview kinds).
			  (aMomentReview winDrop printShowingDecimalPlaces: 0) }
]

{ #category : 'private' }
CoachElement >> describeMoves: someUCIMoves in: aCoachQuestion [
	"The moves in SAN, in the position the question was asked in"

	| position |
	someUCIMoves ifEmpty: [ ^ 'none' ].
	position := game positionAfterPly:
		            (aCoachQuestion kind = #expectedReply
			             ifTrue: [ shownMoment ply ]
			             ifFalse: [ shownMoment ply - 1 ]).
	^ ', ' join:
		  (someUCIMoves collect: [ :each | position sanForUCI: each ])
]

{ #category : 'actions' }
CoachElement >> doneMarking [
	"Merge my marks with the heuristic moments (analysing the game if needed, with its progress), then walk through the moments"

	busy ifNotNil: [ ^ self ].
	self
		busy: 'Finding the important moments…'
		while: [
				session
					finishMarking: review
					of: entry
					onProgress: [ :done :total |
							self showBusy:
								('Analysing the game… move {1} of {2}' format: {
										 (done + 1 // 2).
										 (total + 1 // 2) }) ]
					onStep: [ :description | self showBusy: description ] ]
		then: [ :problems |
				self continueReview.
				problems ifNotEmpty: [
						message := ' ' join: problems.
						self refresh ] ]
]

{ #category : 'private' }
CoachElement >> filter [

	^ session settings momentFilter
]

{ #category : 'actions' }
CoachElement >> filter: aFilter [

	session settings at: 'momentFilter' put: aFilter asString.
	self refresh
]

{ #category : 'private' }
CoachElement >> filterLabel: aFilter [

	aFilter = #all ifTrue: [ ^ 'All' ].
	aFilter = #mistakes ifTrue: [ ^ 'Mistakes+' ].
	^ 'Blunders only'
]

{ #category : 'accessing' }
CoachElement >> header [

	^ header
]

{ #category : 'private' }
CoachElement >> heading: aString [
	"A section title in the panel"

	^ ToLabel new
		  text: (aString asRopedText
				   bold;
				   fontSize: 15;
				   yourself);
		  margin: (BlInsets top: 4);
		  yourself
]

{ #category : 'accessing' }
CoachElement >> history [

	^ history
]

{ #category : 'building' }
CoachElement >> iconButton: anIconName tooltip: aString do: aBlock [

	^ ToButton new
		  icon: ((ToMaterialDesignIconProvider iconNamed: anIconName)
				   extent: 18 @ 18;
				   yourself);
		  tooltipString: aString;
		  clickAction: aBlock;
		  yourself
]

{ #category : 'private' }
CoachElement >> inUIDo: aBlock [
	"Run aBlock in the UI thread"

	self enqueueTask: (BlTaskAction new action: aBlock)
]

{ #category : 'initialization' }
CoachElement >> initialize [
	"The panel has a fixed width so that its multi-line labels wrap, inside a scrollable column with a scrollbar. Report a problem and Close are small buttons on the first row, on the right; Close pauses the review and closes its page. Review time counts only while the coach is shown."

	| panel |
	super initialize.
	markedMoves := OrderedCollection new.
	walking := false.
	exitBlock := [ ].
	backgroundRunner := [ :aBlock |
	                    aBlock forkAt: Processor userBackgroundPriority ].
	self
		addEventHandlerOn: BlElementRemovedFromSceneGraphEvent
		do: [ :event | review ifNotNil: [ review pauseClock ] ].
	self
		addEventHandlerOn: BlElementAddedToSceneGraphEvent
		do: [ :event | review ifNotNil: [ review resumeClock ] ].
	self layout: BlLinearLayout horizontal.
	self matchParent.
	board := ChessBoardElement new
		         matchParent;
		         yourself.
	board whenMoveMarkedDo: [ :uci | self moveMarked: uci ].
	header := ToLabel new
		          beMultiLine;
		          hMatchParent;
		          yourself.
	history := ToElement new
		           layout: (BlLinearLayout vertical cellSpacing: 4);
		           hMatchParent;
		           vFitContent;
		           yourself.
	currentZone := ToElement new
		               layout: (BlLinearLayout vertical cellSpacing: 6);
		               hMatchParent;
		               vFitContent;
		               yourself.
	panel := ToElement new
		         layout: (BlLinearLayout vertical cellSpacing: 10);
		         width: 360;
		         vFitContent;
		         padding: (BlInsets all: 10);
		         yourself.
	panel
		addChild: (ToElement new
				 layout: (BlLinearLayout horizontal cellSpacing: 4);
				 hMatchParent;
				 vFitContent;
				 addChild: (BlElement new
						  constraintsDo: [ :c |
								  c horizontal matchParent.
								  c vertical exact: 1 ];
						  yourself);
				 addChild: (self
						  iconButton: 'outlined_bugreport'
						  tooltip:
						  'Report a problem: save the game, its analysis and this review for a bug report'
						  do: [ self reportProblem ]);
				 addChild: (self
						  iconButton: 'outlined_close'
						  tooltip:
						  'Close the coach; the review is saved and continues next time'
						  do: [ self pause ]);
				 yourself);
		addChild: header;
		addChild: history;
		addChild: currentZone.
	self
		addChild: board;
		addChild: (ToElement new
				 layout: BlFrameLayout new;
				 width: 380;
				 vMatchParent;
				 addChild: (ChessCoachWidgets scrollable: panel);
				 yourself).
	panelScroller := panel parent
]

{ #category : 'private' }
CoachElement >> isActive: aMomentReview [
	"Whether the coach is asking about aMomentReview right now"

	^ aMomentReview notNil and: [ review currentMoment == aMomentReview ]
]

{ #category : 'private' }
CoachElement >> lineInSAN: someUCIMoves from: aChessPosition [
	"The first moves of an engine line, in SAN"

	| position sans |
	position := aChessPosition.
	sans := (someUCIMoves first: (someUCIMoves size min: 4)) collect: [
			        :each |
			        | san |
			        san := position sanForUCI: each.
			        position := position move: san.
			        san ].
	^ ' ' join: sans
]

{ #category : 'actions' }
CoachElement >> markShown [

	review mark: shownPly note: noteField text asString trimBoth.
	self marksChanged
]

{ #category : 'accessing' }
CoachElement >> markedMoves [

	^ markedMoves
]

{ #category : 'actions' }
CoachElement >> markingShows: aPly [

	shownPly := aPly.
	review showPly: aPly.
	self refresh
]

{ #category : 'private' }
CoachElement >> marksChanged [

	replay moveList markedPlies:
		(review marks collect: [ :each | each at: 'ply' ]).
	replay moveList requestFocus.
	self refresh
]

{ #category : 'accessing' }
CoachElement >> message [
	"Feedback such as 'Illegal move', or nil"

	^ message
]

{ #category : 'private' }
CoachElement >> minutes: seconds [

	^ seconds < 60
		  ifTrue: [ seconds rounded printString , ' s' ]
		  ifFalse: [ (seconds / 60) rounded printString , ' min' ]
]

{ #category : 'accessing' }
CoachElement >> mode [
	"#marking, #list, #moment or #summary"

	^ mode
]

{ #category : 'actions' }
CoachElement >> moveMarked: aUCIMove [
	"Toggle aUCIMove in the answer being composed; my real move is always a candidate"

	| question |
	question := self currentQuestionOrNil.
	(busy notNil or: [ question isNil or: [ question expectsMoves not ] ])
		ifTrue: [ ^ self ].
	(board chessPosition isLegalUCI: aUCIMove) ifFalse: [
			message := 'Illegal move'.
			^ self refresh ].
	message := nil.
	(question kind = #candidates and: [ aUCIMove = self playedMove ])
		ifTrue: [ ^ self refresh ].
	(markedMoves includes: aUCIMove)
		ifTrue: [ markedMoves remove: aUCIMove ]
		ifFalse: [ markedMoves add: aUCIMove ].
	self refresh
]

{ #category : 'private' }
CoachElement >> myColor [

	| colors |
	colors := session myColorsIn: game.
	^ colors size = 1
		  ifTrue: [ colors first ]
		  ifFalse: [ #white ]
]

{ #category : 'actions' }
CoachElement >> nextMoment [

	| ply |
	ply := shownMoment ply.
	review leaveMoment.
	self startNextAfter: ply
]

{ #category : 'accessing' }
CoachElement >> noteField [

	^ noteField
]

{ #category : 'private' }
CoachElement >> paragraph: aString [

	^ ChessCoachWidgets paragraph: aString
]

{ #category : 'actions' }
CoachElement >> pause [
	"Close the review; everything is saved, and it continues from the list next time"

	walking := false.
	review leaveMoment.
	exitBlock value
]

{ #category : 'private' }
CoachElement >> playedMove [

	^ game uciMoves at: shownMoment ply
]

{ #category : 'private' }
CoachElement >> positionBefore: aMomentReview [

	^ game positionAfterPly: aMomentReview ply - 1
]

{ #category : 'building' }
CoachElement >> questionTitle: aCoachQuestion [
	"The current question, set apart with an icon and in bold, so that a new question is noticed"

	^ ToElement new
		  layout: (BlLinearLayout horizontal cellSpacing: 8);
		  hMatchParent;
		  vFitContent;
		  padding: (BlInsets all: 8);
		  background: (Color blue alpha: 0.12);
		  geometry: (BlRoundedRectangleGeometry cornerRadius: 6);
		  addChild:
			  ((ToMaterialDesignIconProvider iconNamed: 'filled_livehelp')
				   extent: 22 @ 22;
				   yourself);
		  addChild: (ToTextField new
				   wrappingMode: true;
				   hMatchParent;
				   vFitContent;
				   text: (aCoachQuestion text asRopedText
						    bold;
						    yourself);
				   beReadonlyWithSelection;
				   background: Color transparent;
				   yourself);
		  yourself
]

{ #category : 'private' }
CoachElement >> quickAnswersFor: aCoachQuestion [
	"Answers that fit the question: why I played a move, why I missed or discarded another, or what I saw"

	| kind |
	kind := aCoachQuestion kind.
	kind = #whyNotConsidered ifTrue: [
			^ #( 'I didn''t see it' 'I saw it but thought it was worse'
			     'I saw it but miscalculated it'
			     'No time' ) ].
	kind = #whyNotBetter ifTrue: [
			^ #( 'I miscalculated it' 'I missed a resource in that line'
			     'I thought my move was better' 'No time' ) ].
	kind = #whatDidYouSee ifTrue: [
			^ #( 'I calculated the line' 'It was the only move that didn''t lose'
			     'Intuition' ) ].
	^ #( 'It looked natural' 'I calculated it and it looked good'
	     'Intuition' 'No time' )
]

{ #category : 'updating' }
CoachElement >> refresh [

	self updateLeftPane.
	self updateHeader.
	self updateHistory.
	self updateBoard.
	self updateCurrentZone
]

{ #category : 'accessing' }
CoachElement >> replay [
	"The game with its move list, during the marking pass"

	^ replay
]

{ #category : 'actions' }
CoachElement >> reportProblem [
	"Save a report folder with the game, its analysis, this review and the error log"

	| directory |
	directory := session
		             writeReportFor: entry
		             review: review
		             note:
			             ('mode: {1}, moment: {2}, message: {3}' format: {
					              mode.
					              (shownMoment
						               ifNil: [ '-' ]
						               ifNotNil: [ :m | m ply ]).
					              (message ifNil: [ '-' ]) }).
	message := 'Report saved in ' , directory fullName.
	self refresh
]

{ #category : 'accessing' }
CoachElement >> review [

	^ review
]

{ #category : 'actions' }
CoachElement >> reviewShown [
	"Ask about the shown moment only"

	review start: shownMoment.
	self refresh
]

{ #category : 'private' }
CoachElement >> row: someElements [

	^ ToElement new
		  layout: BlFlowLayout horizontal;
		  hMatchParent;
		  vFitContent;
		  addChildren: someElements;
		  yourself
]

{ #category : 'private' }
CoachElement >> runInBackground: aBlock then: aUIBlock [

	backgroundRunner value: [
			aBlock value.
			self enqueueTask: (BlTaskAction new action: aUIBlock) ]
]

{ #category : 'updating' }
CoachElement >> scrollToNewest [
	"Once the panel is laid out again, scroll to its end: the new question and the answer field. scrollBy: clamps to the content"

	panelScroller ifNil: [ ^ self ].
	currentZone whenLayoutedDoOnce: [ panelScroller scrollBy: 0 @ 100000 ]
]

{ #category : 'accessing' }
CoachElement >> session: aChessCoachSession entry: aGameIndexEntry review: aCoachReview [
	"Open on the marking pass when it is not done, on the list of moments otherwise"

	session := aChessCoachSession.
	entry := aGameIndexEntry.
	review := aCoachReview.
	game := aCoachReview game.
	shownPly := 0.
	review isMarking
		ifTrue: [
				mode := #marking.
				self buildReplay.
				review showPly: 0 ]
		ifFalse: [ mode := #list ].
	self refresh
]

{ #category : 'private' }
CoachElement >> showBusy: aString [
	"From a background process: show aString as the progress of the running work"

	self inUIDo: [
			busy ifNotNil: [
					busy := aString.
					self updateCurrentZone ] ]
]

{ #category : 'actions' }
CoachElement >> showMoment: aMomentReview [
	"Look at one moment: its history and reveal when reviewed, a button to review it otherwise"

	(self isActive: aMomentReview) ifFalse: [ review leaveMoment ].
	markedMoves := OrderedCollection new.
	message := nil.
	walking := false.
	shownMoment := aMomentReview.
	mode := #moment.
	self refresh
]

{ #category : 'actions' }
CoachElement >> showMomentAtPly: aPly [
	"Show the moment of the review at aPly (from the dashboard)"

	review moments
		detect: [ :each | each ply = aPly ]
		ifFound: [ :moment | self showMoment: moment ]
]

{ #category : 'actions' }
CoachElement >> showPly: aPly [
	"Marking pass: show the position after aPly, as selecting it in the move list does"

	replay selectPly: ((aPly max: 0) min: game moves size)
]

{ #category : 'actions' }
CoachElement >> showSummary [

	review leaveMoment.
	shownMoment := nil.
	mode := #summary.
	self refresh
]

{ #category : 'accessing' }
CoachElement >> shownMoment [

	^ shownMoment
]

{ #category : 'private' }
CoachElement >> startNextAfter: aPly [

	(review nextMomentAfter: aPly passing: self filter)
		ifNil: [
				walking := false.
				mode := #summary ]
		ifNotNil: [ :moment |
				review start: moment.
				shownMoment := moment.
				mode := #moment ].
	self refresh
]

{ #category : 'private' }
CoachElement >> stateIconNameOf: aMomentReview [
	"Reviewed, started or still to do"

	aMomentReview isReviewed ifTrue: [ ^ 'outlined_checkcircle' ].
	aMomentReview isStarted ifTrue: [ ^ 'outlined_timelapse' ].
	^ 'outlined_radiobuttonunchecked'
]

{ #category : 'actions' }
CoachElement >> stop [
	"Leave the Socratic stage; unreviewed moments stay in the list"

	walking := false.
	self backToList
]

{ #category : 'actions' }
CoachElement >> submitMoves [
	"The expected reply triggers the engine evaluation of my candidates, so it runs in the background"

	| moves |
	moves := markedMoves asArray.
	markedMoves := OrderedCollection new.
	message := nil.
	review currentQuestion kind = #expectedReply ifFalse: [
			review answerMoves: moves.
			^ self refresh ].
	self
		busy: 'Analysing your candidates…'
		while: [ review answerMoves: moves ]
		then: [ ]
]

{ #category : 'actions' }
CoachElement >> submitText [

	| text |
	text := answerField text asString trimBoth.
	text ifEmpty: [ ^ self ].
	answerField text: ''.
	draftQuestion := nil.
	review answerText: text.
	self refresh.
	self
		runInBackground: [ review classifyPending ]
		then: [ self refresh ]
]

{ #category : 'actions' }
CoachElement >> toggleMarkAt: aPly [
	"Enter or Space: mark the move (with the note being written), or unmark it"

	(review isMarked: aPly)
		ifTrue: [ review unmark: aPly ]
		ifFalse: [
				review mark: aPly note: (noteField
						 ifNil: [ '' ]
						 ifNotNil: [ noteField text asString trimBoth ]) ].
	self marksChanged
]

{ #category : 'actions' }
CoachElement >> toggleTag: aTagId [

	review toggleTag: aTagId of: shownMoment.
	self refresh
]

{ #category : 'actions' }
CoachElement >> unmarkShown [

	review unmark: shownPly.
	self marksChanged
]

{ #category : 'updating' }
CoachElement >> updateBoard [
	"The list of moments and the summary show the game's final position"

	| question arrows |
	mode = #marking ifTrue: [
			^ replay boardElement arrows: (shownPly = 0
					   ifTrue: [ #(  ) ]
					   ifFalse: [
					   { (ChessArrow uci: (game uciMoves at: shownPly) style: #played) } ]) ].
	mode = #moment ifFalse: [
			board chessPosition: (game positionAfterPly: game moves size).
			^ board arrows: #(  ) ].
	question := self currentQuestionOrNil.
	board orientation: shownMoment color.
	(question notNil and: [ question kind = #expectedReply ]) ifTrue: [
			board chessPosition: (game positionAfterPly: shownMoment ply).
			^ board arrows: (markedMoves collect: [ :each |
					   ChessArrow uci: each style: #candidate ]) ].
	board chessPosition: (self positionBefore: shownMoment).
	arrows := OrderedCollection new.
	shownMoment isReviewed
		ifTrue: [
				shownMoment candidateWinPercents keysDo: [ :each |
						each = self playedMove ifFalse: [
							arrows add: (ChessArrow uci: each style: #candidate) ] ].
				review hasEngine ifTrue: [
						arrows add: (ChessArrow
								 uci:
								 (review analysis atPly: shownMoment ply - 1) bestLine
									 firstMove
								 style: #engine) ] ]
		ifFalse: [
				markedMoves do: [ :each |
					arrows add: (ChessArrow uci: each style: #candidate) ].
				(question notNil and: [ question move notNil ]) ifTrue: [
					arrows add: (ChessArrow uci: question move style: #subject) ] ].
	arrows add: (ChessArrow uci: self playedMove style: #played).
	board arrows: arrows
]

{ #category : 'updating' }
CoachElement >> updateCurrentZone [
	"Rebuild the panel below the history and scroll down to it. The answer being typed is kept as a draft of its question, so that a refresh (a classification finishing, a progress update) doesn't empty the field."

	answerField ifNotNil: [ draft := answerField text asString ].
	currentZone removeChildren.
	answerField := nil.
	noteField := nil.
	self scrollToNewest.
	busy ifNotNil: [ ^ currentZone addChild: (self paragraph: busy) ].
	mode = #marking ifTrue: [ self buildMarking ].
	mode = #list ifTrue: [ self buildList ].
	mode = #summary ifTrue: [ self buildSummary ].
	mode = #moment ifTrue: [ self buildMoment ].
	(mode ~= #moment and: [ message notNil ]) ifTrue: [
		currentZone addChild: (self paragraph: message) ]
]

{ #category : 'updating' }
CoachElement >> updateHeader [

	| move |
	mode = #marking ifTrue: [
			^ header text:
				  ('Analysis {1} · mark the interesting moves · move {2} of {3}'
					   format: {
							   review number.
							   (shownPly + 1 // 2).
							   (game moves size + 1 // 2) }) ].
	mode = #list ifTrue: [
			^ header text:
				  ('Analysis {1} · {2} · {3}/{4} moments reviewed · {5}' format:
					   {
						   review number.
						   review date yyyymmdd.
						   review reviewedMoments size.
						   (review momentsPassing: self filter) size.
						   (self minutes: review totalSeconds) }) ].
	mode = #summary ifTrue: [ ^ header text: 'Review summary' ].
	move := game moves at: shownMoment ply.
	header text:
		('Moment {1} of {2} · move {3} ({4}) · {5}{6}' format: {
				 ((review momentsPassing: self filter) indexOf: shownMoment).
				 (review momentsPassing: self filter) size.
				 (shownMoment ply + 1 // 2).
				 move san.
				 (', ' join: shownMoment kinds).
				 (self clockTextBefore: shownMoment ply) })
]

{ #category : 'updating' }
CoachElement >> updateHistory [
	"My earlier answers on this moment, under a title, as text I can select and copy"

	history removeChildren.
	mode = #moment ifFalse: [ ^ self ].
	shownMoment answers ifEmpty: [ ^ self ].
	history addChild: (self heading: 'Your answers').
	shownMoment answers do: [ :answer |
			history addChild:
				(ChessCoachWidgets selectableParagraph: answer question text).
			history addChild: (ChessCoachWidgets selectableParagraph:
					 '→ ' , (answer question expectsMoves
						  ifTrue: [
						  self describeMoves: answer moves in: answer question ]
						  ifFalse: [ answer text ])) ].
	history addChild: ChessCoachWidgets separator
]

{ #category : 'updating' }
CoachElement >> updateLeftPane [
	"The marking pass shows the game with its move list; the other modes show the coach's board"

	| wanted |
	wanted := mode = #marking
		          ifTrue: [ replay ]
		          ifFalse: [ board ].
	self children first == wanted ifTrue: [ ^ self ].
	self children first removeFromParent.
	self addChildFirst: wanted.
	mode = #marking ifTrue: [ replay moveList requestFocus ]
]

{ #category : 'accessing' }
CoachElement >> whenExitDo: aBlock [

	exitBlock := aBlock
]
