"
The coach mode of the right pane: the board (from my side) and a dialogue panel over a CoachReview. Board questions are answered by marking moves (arrows); written ones with a text field and quick-answer chips. Slow work (engine evaluation, LLM classification) runs through backgroundRunner; tests pass [ :work | work value ].
"
Class {
	#name : 'CoachElement',
	#superclass : 'ToElement',
	#instVars : [
		'review',
		'game',
		'board',
		'header',
		'history',
		'currentZone',
		'exitButton',
		'markedMoves',
		'message',
		'busy',
		'backgroundRunner',
		'exitBlock',
		'answerField'
	],
	#category : 'ChessCoach-UI-Coach',
	#package : 'ChessCoach-UI',
	#tag : 'Coach'
}

{ #category : 'instance creation' }
CoachElement class >> review: aCoachReview [

	^ self new
		  review: aCoachReview;
		  yourself
]

{ #category : 'accessing' }
CoachElement >> answerField [
	"The text field of the current written question, or nil"

	^ answerField
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
	currentZone addChild: (ToButton new
			 labelText: 'Done';
			 clickAction: [ self submitMoves ];
			 yourself)
]

{ #category : 'building' }
CoachElement >> buildReveal [

	| moment reveal before after |
	moment := review currentMoment.
	reveal := review revealOf: moment.
	before := self positionBefore: moment.
	after := game positionAfterPly: moment ply.
	currentZone addChild:
		(self paragraph: ('Win chance: {1}% → {2}%' format: {
					  ((reveal at: 'winBefore') printShowingDecimalPlaces: 0).
					  ((reveal at: 'winAfter') printShowingDecimalPlaces: 0) })).
	(reveal at: 'candidates') keysAndValuesDo: [ :move :win |
			currentZone addChild: (self paragraph: ('  {1}: {2}%' format: {
							  (before sanForUCI: move).
							  (win printShowingDecimalPlaces: 0) })) ].
	currentZone addChild: (self paragraph: 'Engine line: '
			 , (self lineInSAN: (reveal at: 'bestLine') from: before)).
	(reveal at: 'engineReply') ifNotNil: [ :reply |
			currentZone addChild: (self paragraph:
					 ('Engine''s reply: {1} · you expected: {2}' format: {
							  (after sanForUCI: reply).
							  ((reveal at: 'expectedReply') isEmpty
								   ifTrue: [ 'nothing' ]
								   ifFalse: [
										   ', ' join:
											   ((reveal at: 'expectedReply') collect: [ :each |
												    after sanForUCI: each ]) ]) })) ].
	self buildTagsOf: moment.
	currentZone addChild: (ToButton new
			 labelText: 'Next moment';
			 clickAction: [ self nextMoment ];
			 yourself)
]

{ #category : 'building' }
CoachElement >> buildSummary [

	| counts |
	review mistakeRecords do: [ :record |
			currentZone addChild:
				(self paragraph: ('Move {1} ({2}): −{3}% · {4}' format: {
							  (record ply + 1 // 2).
							  (game moves at: record ply) san.
							  (record winDrop printShowingDecimalPlaces: 0).
							  (', ' join: record tagIds) })) ].
	counts := Bag new.
	review mistakeRecords do: [ :each | counts addAll: each tagIds ].
	counts ifNotEmpty: [
			currentZone addChild:
				(self paragraph: 'Most frequent here: ' , (', ' join:
						  ((counts sortedCounts first: (counts asSet size min: 3))
							   collect: [ :each | each value , ' ×' , each key printString ]))) ].
	review hasMore ifTrue: [
			currentZone addChild: (ToButton new
					 labelText: 'Review more moments';
					 clickAction: [ self reviewMore ];
					 yourself) ].
	currentZone addChild: (ToButton new
			 labelText: 'Back to analysis';
			 clickAction: [ exitBlock value ];
			 yourself)
]

{ #category : 'building' }
CoachElement >> buildTagsOf: aMomentReview [

	currentZone addChild: (self paragraph: 'Tags:').
	aMomentReview isClassifying ifTrue: [
		currentZone addChild: (self paragraph: '  classifying…') ].
	aMomentReview labels do: [ :label |
			currentZone addChild: (ToElement new
					 layout: (BlLinearLayout horizontal cellSpacing: 6);
					 hMatchParent;
					 vFitContent;
					 addChild: (ToLabel text: (label isConfirmed
									   ifTrue: [ '✓ ' , label tagId ]
									   ifFalse: [
											   label tagId , ' ('
											   , (label confidence * 100) rounded printString , '%)' ]));
					 addChild: (ToButton new
							  labelText: 'Confirm';
							  clickAction: [ self confirmTag: label tagId ];
							  yourself);
					 addChild: (ToButton new
							  labelText: 'Drop';
							  clickAction: [ self dropTag: label tagId ];
							  yourself);
					 yourself) ]
]

{ #category : 'building' }
CoachElement >> buildTextAnswer [

	| chips |
	chips := ToElement new
		         layout: BlFlowLayout horizontal;
		         hMatchParent;
		         vFitContent;
		         yourself.
	self quickAnswers do: [ :each |
			chips addChild: (ToButton new
					 labelText: each;
					 clickAction: [ answerField text: each ];
					 yourself) ].
	answerField := ToAlbum new
		               hMatchParent;
		               height: 100;
		               yourself.
	currentZone
		addChild: chips;
		addChild: answerField;
		addChild: (ToButton new
				 labelText: 'Answer';
				 clickAction: [ self submitText ];
				 yourself)
]

{ #category : 'actions' }
CoachElement >> confirmTag: aTagId [

	review confirmTag: aTagId of: review currentMoment.
	self refresh
]

{ #category : 'private' }
CoachElement >> currentQuestionOrNil [

	(review isFinished or: [ review currentMoment isRevealed ]) ifTrue: [
		^ nil ].
	^ review currentQuestion
]

{ #category : 'accessing' }
CoachElement >> currentZone [

	^ currentZone
]

{ #category : 'private' }
CoachElement >> describeMoves: someUCIMoves in: aCoachQuestion [
	"The moves in SAN, in the position the question was asked in"

	| position |
	someUCIMoves ifEmpty: [ ^ 'none' ].
	position := game positionAfterPly:
		            (aCoachQuestion kind = #expectedReply
			             ifTrue: [ review currentMoment ply ]
			             ifFalse: [ review currentMoment ply - 1 ]).
	^ ', ' join:
		  (someUCIMoves collect: [ :each | position sanForUCI: each ])
]

{ #category : 'actions' }
CoachElement >> dropTag: aTagId [

	review dropTag: aTagId of: review currentMoment.
	self refresh
]

{ #category : 'accessing' }
CoachElement >> exitButton [

	^ exitButton
]

{ #category : 'accessing' }
CoachElement >> header [

	^ header
]

{ #category : 'accessing' }
CoachElement >> history [

	^ history
]

{ #category : 'initialization' }
CoachElement >> initialize [

	| panel footer |
	super initialize.
	markedMoves := OrderedCollection new.
	busy := false.
	exitBlock := [ ].
	backgroundRunner := [ :aBlock |
	                    aBlock forkAt: Processor userBackgroundPriority ].
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
	exitButton := ToButton new
		              labelText: 'Exit';
		              clickAction: [ exitBlock value ];
		              yourself.
	footer := ToElement new
		          layout: BlLinearLayout horizontal;
		          hMatchParent;
		          vFitContent;
		          addChild: exitButton;
		          yourself.
	panel := ToElement new
		         layout: (BlLinearLayout vertical cellSpacing: 10);
		         width: 360;
		         vMatchParent;
		         padding: (BlInsets all: 10);
		         yourself.
	panel
		addChild: header;
		addChild: history;
		addChild: currentZone;
		addChild: footer.
	self
		addChild: board;
		addChild: panel
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

{ #category : 'accessing' }
CoachElement >> markedMoves [

	^ markedMoves
]

{ #category : 'accessing' }
CoachElement >> message [
	"Feedback such as 'Illegal move', or nil"

	^ message
]

{ #category : 'actions' }
CoachElement >> moveMarked: aUCIMove [
	"Toggle aUCIMove in the answer being composed; my real move is always a candidate"

	| question |
	question := self currentQuestionOrNil.
	(busy or: [ question isNil or: [ question expectsMoves not ] ])
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

{ #category : 'actions' }
CoachElement >> nextMoment [

	review nextMoment.
	self refresh
]

{ #category : 'private' }
CoachElement >> paragraph: aString [

	^ ToLabel new
		  beMultiLine;
		  hMatchParent;
		  text: aString;
		  yourself
]

{ #category : 'private' }
CoachElement >> playedMove [

	^ game uciMoves at: review currentMoment ply
]

{ #category : 'private' }
CoachElement >> positionBefore: aMomentReview [

	^ game positionAfterPly: aMomentReview ply - 1
]

{ #category : 'private' }
CoachElement >> quickAnswers [

	^ #( 'I didn''t see it' 'I saw it but miscalculated'
	     'No time' 'Intuition' )
]

{ #category : 'updating' }
CoachElement >> refresh [

	self updateHeader.
	self updateHistory.
	self updateBoard.
	self updateCurrentZone
]

{ #category : 'accessing' }
CoachElement >> review [

	^ review
]

{ #category : 'accessing' }
CoachElement >> review: aCoachReview [

	review := aCoachReview.
	game := aCoachReview game.
	self refresh
]

{ #category : 'actions' }
CoachElement >> reviewMore [

	review reviewMore.
	self refresh
]

{ #category : 'private' }
CoachElement >> runInBackground: aBlock then: aUIBlock [

	backgroundRunner value: [
			aBlock value.
			self enqueueTask: (BlTaskAction new action: aUIBlock) ]
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
	busy := true.
	self refresh.
	self runInBackground: [ review answerMoves: moves ] then: [
			busy := false.
			self refresh ]
]

{ #category : 'actions' }
CoachElement >> submitText [

	| text |
	text := answerField text asString trimBoth.
	text ifEmpty: [ ^ self ].
	review answerText: text.
	self refresh.
	self
		runInBackground: [ review classifyPending ]
		then: [ self refresh ]
]

{ #category : 'updating' }
CoachElement >> updateBoard [

	| moment question arrows |
	review isFinished ifTrue: [ ^ board arrows: #(  ) ].
	moment := review currentMoment.
	question := self currentQuestionOrNil.
	board orientation: moment color.
	(question notNil and: [ question kind = #expectedReply ]) ifTrue: [
			board chessPosition: (game positionAfterPly: moment ply).
			^ board arrows: (markedMoves collect: [ :each |
					   ChessArrow uci: each style: #candidate ]) ].
	board chessPosition: (self positionBefore: moment).
	arrows := OrderedCollection new.
	moment isRevealed
		ifTrue: [
				moment candidateWinPercents keysDo: [ :each |
						each = self playedMove ifFalse: [
							arrows add: (ChessArrow uci: each style: #candidate) ] ].
				arrows add: (ChessArrow
						 uci: (review analysis atPly: moment ply - 1) bestLine firstMove
						 style: #engine) ]
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

	| question |
	currentZone removeChildren.
	answerField := nil.
	review isFinished ifTrue: [ ^ self buildSummary ].
	busy ifTrue: [
		^ currentZone addChild: (ToLabel text: 'Analysing your candidates…') ].
	review currentMoment isRevealed ifTrue: [ ^ self buildReveal ].
	question := review currentQuestion.
	currentZone addChild: (self paragraph: question text).
	question expectsMoves
		ifTrue: [ self buildBoardAnswer ]
		ifFalse: [ self buildTextAnswer ].
	message ifNotNil: [ currentZone addChild: (ToLabel text: message) ]
]

{ #category : 'updating' }
CoachElement >> updateHeader [

	| moment move |
	review isFinished ifTrue: [ ^ header text: 'Review summary' ].
	moment := review currentMoment.
	move := game moves at: moment ply.
	header text: ('Moment {1} of {2} · move {3} ({4}) · {5}' format: {
				 (review reviews indexOf: moment).
				 review reviews size.
				 (moment ply + 1 // 2).
				 move san.
				 (', ' join: moment kinds) })
]

{ #category : 'updating' }
CoachElement >> updateHistory [

	history removeChildren.
	review isFinished ifTrue: [ ^ self ].
	review currentMoment answers do: [ :answer |
			history addChild: (ToLabel new
					 beMultiLine;
					 hMatchParent;
					 text: answer question text;
					 yourself).
			history addChild: (ToLabel new
					 beMultiLine;
					 hMatchParent;
					 text: '→ ' , (answer question expectsMoves
								  ifTrue: [
									  self describeMoves: answer moves in: answer question ]
								  ifFalse: [ answer text ]);
					 yourself) ]
]

{ #category : 'accessing' }
CoachElement >> whenExitDo: aBlock [

	exitBlock := aBlock
]
