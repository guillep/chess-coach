"
One coach review of a game (games/<id>.review-<n>.json); a game can have several.

First a manual marking pass (mark:note:, showPly: records the time on each ply), then finishMarkingWith:moments: merges my marks with the heuristic moments. Then the Socratic stage: start: a moment, answer its CoachQuestions (each answer records its time), see the reveal, leaveMoment. Unreviewed moments can be started at any time. Produces MistakeRecords and round-trips through JSON.
"
Class {
	#name : 'CoachReview',
	#superclass : 'Object',
	#instVars : [
		'gameId',
		'game',
		'analysis',
		'engine',
		'classifier',
		'number',
		'date',
		'marks',
		'plySeconds',
		'shownPly',
		'shownAt',
		'reviews',
		'current',
		'momentStartedAt',
		'questionShownAt',
		'depth',
		'clock',
		'changedBlock',
		'momentClosedBlock',
		'timeBox',
		'planned',
		'plannedSeconds',
		'classifierUnavailable',
		'pausedAt',
		'pausedTime'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'instance creation' }
CoachReview class >> gameId: anId game: aGame engine: aStockfishEngine classifier: anAnswerClassifier [
	"A new review, starting with the manual marking pass"

	^ self new
		  setGameId: anId
		  game: aGame
		  engine: aStockfishEngine
		  classifier: anAnswerClassifier
]

{ #category : 'accessing' }
CoachReview >> analysis [

	^ analysis
]

{ #category : 'accessing' }
CoachReview >> analysis: aGameAnalysis [
	"The Stockfish analysis, known once the marking pass is done"

	analysis := aGameAnalysis
]

{ #category : 'answering' }
CoachReview >> answerMoves: someUCIMoves [
	"Answer a board question with the moves I marked"

	| question position |
	question := self currentQuestion.
	self assert: question expectsMoves.
	position := game positionAfterPly: (question kind = #candidates
			             ifTrue: [ self currentMoment ply - 1 ]
			             ifFalse: [ self currentMoment ply ]).
	someUCIMoves do: [ :move |
		(position isLegalUCI: move) ifFalse: [
			CoachIllegalMove signal: move ] ].
	self currentMoment answer:
		((CoachAnswer question: question moves: someUCIMoves)
			 seconds: self takeAnswerSeconds;
			 yourself).
	question kind = #expectedReply ifTrue: [ self askAboutCandidates ].
	self changed
]

{ #category : 'answering' }
CoachReview >> answerText: aString [
	"Answer a written question at once; classifyPending tags it later. Answers about a success (see isSuccess:) are not classified: there is no mistake."

	| question answer |
	question := self currentQuestion.
	self assert: question expectsMoves not.
	answer := (self isSuccess: self currentMoment)
		          ifTrue: [
		          CoachAnswer question: question text: aString labels: #(  ) ]
		          ifFalse: [ CoachAnswer question: question text: aString ].
	self currentMoment answer: (answer
			 seconds: self takeAnswerSeconds;
			 yourself).
	self changed
]

{ #category : 'converting' }
CoachReview >> asJSON [
	"The review file content (games/<id>.review-<n>.json): marks, moments with my answers, timings, the time box and the mistake records derived from them"

	^ STONJSON toString: (Dictionary new
			   at: 'game' put: gameId;
			   at: 'number' put: number;
			   at: 'date' put: date yyyymmdd;
			   at: 'marking' put: self isMarking;
			   at: 'marks' put: self marks;
			   at: 'plySeconds'
			   put: (plySeconds associations asArray collect: [ :each |
						    Array with: each key with: each value ]);
			   at: 'timeBox' put: timeBox;
			   at: 'planned' put: (planned ifNotNil: [ planned asArray sort ]);
			   at: 'plannedSeconds' put: plannedSeconds;
			   at: 'moments'
			   put: (reviews collect: [ :each | each asDictionary ]) asArray;
			   at: 'mistakes' put: (self isMarking
					    ifTrue: [ #(  ) ]
					    ifFalse: [
						    (self mistakeRecords collect: [ :each | each asDictionary ])
							    asArray ]);
			   yourself)
]

{ #category : 'private - questions' }
CoachReview >> askAboutCandidates [
	"Evaluate my candidates with the engine and ask about good moves I missed, bad candidates and better alternatives. The played move's win % comes from the stored analysis, so the engine only runs for my other candidates. Without Stockfish there is nothing to compare with."

	| moment before played others best playedWin questions better |
	self hasEngine ifFalse: [ ^ self ].
	moment := self currentMoment.
	before := analysis atPly: moment ply - 1.
	played := game uciMoves at: moment ply.
	others := ((moment answerTo: #candidates) moves reject: [ :each |
		           each = played ]) asSet asArray.
	moment
		candidate: played
		winPercent:
		((analysis atPly: moment ply) winPercentFor: moment color).
	others ifNotEmpty: [
			(engine
				 analyse: before fen
				 multiPV: others size
				 depth: depth
				 searchMoves: others) do: [ :line |
					moment
						candidate: line firstMove
						winPercent: (line winPercentFor: moment color) ] ].
	best := before winPercentFor: moment color.
	playedWin := moment candidateWinPercents at: played.
	questions := OrderedCollection new.
	before lines do: [ :line |
			((line winPercentFor: moment color) >= (best - 10) and: [
				 line firstMove ~= played and: [
					 (others includes: line firstMove) not ] ]) ifTrue: [
					questions add: (CoachQuestion
							 kind: #whyNotConsidered
							 text:
							 'You didn''t consider ' , (before sanOf: line firstMove)
							 , '. Why?'
							 move: line firstMove) ] ].
	moment candidateWinPercents keysAndValuesDo: [ :move :win |
			(move ~= played and: [ win <= (best - 10) ]) ifTrue: [
					questions add: (CoachQuestion
							 kind: #whyBadCandidate
							 text:
							 (before sanOf: move)
							 , ' was a bad candidate. Why did it look good?'
							 move: move) ] ].
	better := (moment candidateWinPercents associations reject: [ :each |
		           each key = played ]) detectMax: [ :each | each value ].
	(better notNil and: [ better value > playedWin ]) ifTrue: [
			questions add: (CoachQuestion
					 kind: #whyNotBetter
					 text: 'You also considered ' , (before sanOf: better key)
						 , ', which was better. Why did you choose '
						 , (before sanOf: played) , '?'
					 move: better key) ].
	moment ask: questions
]

{ #category : 'saving' }
CoachReview >> changed [
	"Every answer, tag change and move to the next moment is saved at once"

	changedBlock value
]

{ #category : 'answering' }
CoachReview >> classifyPending [
	"Classify every written answer not classified yet. Slow (local LLM): call it off the UI thread.
	When Ollama or its model is not available the answers stay unclassified and isClassifierUnavailable is true until a later call succeeds."

	reviews do: [ :moment |
			moment answers
				reject: [ :each | each isClassified ]
				thenDo: [ :answer |
						| labels |
						labels := [
							          classifier
								          classify: answer text
								          question: answer question text
								          context: (self contextOf: moment) ]
							          on: NetworkError , ZnHttpUnsuccessful
							          do: [
									          classifierUnavailable := true.
									          ^ self ].
						classifierUnavailable := false.
						answer classifiedAs: labels.
						moment proposeLabels: labels.
						self changed ] ]
]

{ #category : 'accessing' }
CoachReview >> clock: aBlock [
	"aBlock answers the current DateAndTime; tests replace it"

	clock := aBlock
]

{ #category : 'labels' }
CoachReview >> confirmTag: aTagId of: aMomentReview [

	aMomentReview confirmTag: aTagId.
	self changed
]

{ #category : 'private - questions' }
CoachReview >> contextOf: aMomentReview [
	"A short description of the moment for the classifier"

	| before |
	before := analysis atPly: aMomentReview ply - 1.
	^ 'Position (FEN): {1}. I played {2} ({3}){4}.' format: {
			  before fen.
			  (game moves at: aMomentReview ply) san.
			  (', ' join: aMomentReview kinds).
			  (before lines ifEmpty: [ '' ] ifNotEmpty: [
					   '; the engine''s best move was '
					   , (before sanOf: before bestLine firstMove) ]) }
]

{ #category : 'navigating' }
CoachReview >> currentMoment [
	"The moment being asked about, or nil"

	^ current
]

{ #category : 'navigating' }
CoachReview >> currentQuestion [

	^ self currentMoment currentQuestion
]

{ #category : 'accessing' }
CoachReview >> date [
	"The day the review started"

	^ date
]

{ #category : 'accessing' }
CoachReview >> depth: anInteger [
	"Engine depth used to evaluate my candidates"

	depth := anInteger
]

{ #category : 'labels' }
CoachReview >> dropTag: aTagId of: aMomentReview [

	aMomentReview dropTag: aTagId.
	self changed
]

{ #category : 'marking' }
CoachReview >> finishMarkingWith: aGameAnalysis moments: someChessMoments [
	"End the marking pass: someChessMoments are the heuristic moments merged with my marks. Moments already in the review keep their answers."

	| prioritizer |
	self recordShownPly.
	analysis := aGameAnalysis.
	prioritizer := MomentPrioritizer on: analysis.
	someChessMoments do: [ :moment |
			| review |
			review := (reviews
				           detect: [ :each | each ply = moment ply ]
				           ifNone: [ nil ]) ifNil: [
					          reviews add: (CoachMomentReview
							           ply: moment ply
							           color: moment color
							           kinds: moment kinds) ].
			review
				kinds: (review kinds asSet
						 addAll: moment kinds;
						 yourself) asArray;
				score: (prioritizer scoreOf: moment);
				winDrop: (self winDropAt: moment ply for: moment color) ].
	reviews := (reviews asArray sort: [ :a :b | a ply < b ply ])
		           asOrderedCollection.
	self changed
]

{ #category : 'accessing' }
CoachReview >> game [

	^ game
]

{ #category : 'mistakes' }
CoachReview >> gameDate [
	"The game's date from its PGN tags (yyyy.mm.dd); today, the day of the review, when the game has no known date"

	| numbers |
	numbers := ((game metadata
		             at: 'UTCDate'
		             ifAbsent: [ game metadata at: 'Date' ifAbsent: [ '' ] ])
		            substrings: '.') collect: [ :each | each asInteger ].
	(numbers size = 3 and: [ numbers allSatisfy: [ :each | each notNil ] ])
		ifFalse: [ ^ Date today ].
	^ Date year: numbers first month: numbers second day: numbers third
]

{ #category : 'accessing' }
CoachReview >> gameId [

	^ gameId
]

{ #category : 'testing' }
CoachReview >> hasEngine [
	"Whether the game was analysed by Stockfish; without it there are no evaluations or engine questions"

	^ analysis notNil and: [ analysis hasEngineLines ]
]

{ #category : 'testing' }
CoachReview >> isClassifierUnavailable [
	"Whether the last classification failed because Ollama or its model was not available"

	^ classifierUnavailable == true
]

{ #category : 'marking' }
CoachReview >> isMarked: aPly [

	^ marks anySatisfy: [ :each | (each at: 'ply') = aPly ]
]

{ #category : 'testing' }
CoachReview >> isMarking [
	"Whether the manual marking pass is not done yet"

	^ analysis isNil
]

{ #category : 'time box' }
CoachReview >> isOverTime [

	^ timeBox notNil and: [ self totalSeconds > (timeBox * 60) ]
]

{ #category : 'time box' }
CoachReview >> isPlanned: aMomentReview [
	"Whether the time box leaves room for aMomentReview (always, without a time box)"

	^ planned isNil or: [ planned includes: aMomentReview ply ]
]

{ #category : 'testing' }
CoachReview >> isSuccess: aMomentReview [
	"Nothing to tag as a mistake: a found only move, or, with the engine, a move that lost less than 5 win-% points (the best move, or one as good)"

	aMomentReview isSuccess ifTrue: [ ^ true ].
	self hasEngine ifFalse: [ ^ false ].
	^ (self winDropAt: aMomentReview ply for: aMomentReview color) < 5
]

{ #category : 'report' }
CoachReview >> kindCounts [
	"How many reviewed moments of each kind"

	| counts |
	counts := Bag new.
	self reviewedMoments do: [ :each | counts addAll: each kinds ].
	^ counts
]

{ #category : 'navigating' }
CoachReview >> leaveMoment [
	"Stop working on the current moment, answered or not. Its time is recorded."

	current ifNil: [ ^ self ].
	current addSeconds: (self secondsSince: momentStartedAt).
	current := nil.
	self changed.
	momentClosedBlock value
]

{ #category : 'marking' }
CoachReview >> mark: aPly note: aString [
	"Mark the ply-th half-move as interesting, replacing any earlier mark on it"

	self unmarkSilently: aPly.
	marks add: (Dictionary new
			 at: 'ply' put: aPly;
			 at: 'note' put: aString;
			 yourself).
	self changed
]

{ #category : 'timing' }
CoachReview >> markingSeconds [

	^ plySeconds inject: 0 into: [ :sum :each | sum + each ]
]

{ #category : 'marking' }
CoachReview >> marks [
	"My marks from the manual pass: dictionaries with 'ply' and 'note', sorted by ply"

	^ marks asArray sort: [ :a :b | (a at: 'ply') < (b at: 'ply') ]
]

{ #category : 'mistakes' }
CoachReview >> mistakeRecordFor: aMomentReview [
	"Rejected tags are left out. Without Stockfish there is no best move or win drop."

	| before after explanation move |
	before := analysis atPly: aMomentReview ply - 1.
	after := analysis atPly: aMomentReview ply.
	move := game moves at: aMomentReview ply.
	explanation := (aMomentReview answers
		                detect: [ :each | each question kind = #why ]
		                ifNone: [ nil ]) ifNotNil: [ :answer | answer text ].
	^ MistakeRecord new
		  gameId: gameId;
		  ply: aMomentReview ply;
		  date: self gameDate;
		  phase: (self phaseOf: before fen ply: aMomentReview ply);
		  kinds: aMomentReview kinds;
		  playedMove: (game uciMoves at: aMomentReview ply);
		  bestMove: (before lines
				   ifEmpty: [ nil ]
				   ifNotEmpty: [ before bestLine firstMove ]);
		  winDrop: ((before winPercentFor: aMomentReview color)
			   - (after winPercentFor: aMomentReview color) max: 0);
		  explanation: explanation;
		  labels: aMomentReview countedLabels asArray;
		  clock: (move timestamp ifNotNil: [ :duration |
					   duration asMilliSeconds / 1000.0 ]);
		  yourself
]

{ #category : 'mistakes' }
CoachReview >> mistakeRecords [
	"One record per reviewed moment that was not a success (see isSuccess:)"

	^ reviews
		  select: [ :each |
		  each isReviewed and: [ (self isSuccess: each) not ] ]
		  thenCollect: [ :each | self mistakeRecordFor: each ]
]

{ #category : 'accessing' }
CoachReview >> moments [
	"Every moment of the review, in move order"

	^ reviews
]

{ #category : 'accessing' }
CoachReview >> momentsPassing: aFilter [

	^ reviews select: [ :each | each passes: aFilter ]
]

{ #category : 'navigating' }
CoachReview >> nextMomentAfter: aPly passing: aFilter [
	"The first planned moment after aPly not reviewed yet, or nil when none is left"

	^ reviews
		  detect: [ :each |
				  each ply > aPly and: [
						  each isReviewed not and: [
							  (each passes: aFilter) and: [ self isPlanned: each ] ] ] ]
		  ifNone: [ nil ]
]

{ #category : 'private - timing' }
CoachReview >> now [
	"The clock's time minus the time spent paused, so that pauses don't count as review time"

	^ (pausedAt ifNil: [ clock value ])
	  - (pausedTime ifNil: [ Duration zero ])
]

{ #category : 'accessing' }
CoachReview >> number [
	"Which review of the game this is: 1 for the first"

	^ number
]

{ #category : 'accessing' }
CoachReview >> number: anInteger [

	number := anInteger
]

{ #category : 'private - questions' }
CoachReview >> openingQuestionsFor: aMoment [

	| played |
	played := (game moves at: aMoment ply) san.
	(aMoment kinds includesAny:
		 #( #inaccuracy #mistake #blunder #onlyMoveMissed #longThink
		    #marked )) ifTrue: [
			^ {
				  (CoachQuestion
					   kind: #candidates
					   text:
					   'Which candidate moves did you consider? Mark them on the board.').
				  (CoachQuestion
					   kind: #why
					   text: 'Why did you play ' , played , '?').
				  (CoachQuestion
					   kind: #expectedReply
					   text:
					   'After ' , played
					   , ', what did you expect your opponent to play?') } ].
	(aMoment kinds includes: #onlyMoveFound) ifTrue: [
			^ { (CoachQuestion
				   kind: #whatDidYouSee
				   text:
					   'Only one move kept the balance and you found it: ' , played
					   , '. What did you see?') } ].
	^ { (CoachQuestion
		   kind: #why
		   text: 'Why did you play ' , played , '?') }
]

{ #category : 'timing' }
CoachReview >> pauseClock [
	"Stop counting time, as when the coach is hidden"

	pausedAt ifNil: [ pausedAt := clock value ]
]

{ #category : 'mistakes' }
CoachReview >> phaseOf: aFEN ply: aPly [
	"Opening for the first 12 moves, endgame with 6 or fewer queens, rooks and minor pieces left, middlegame otherwise"

	| pieces |
	pieces := aFEN substrings first count: [ :each |
		          'QRBNqrbn' includes: each ].
	pieces <= 6 ifTrue: [ ^ 'endgame' ].
	aPly <= 24 ifTrue: [ ^ 'opening' ].
	^ 'middlegame'
]

{ #category : 'time box' }
CoachReview >> planWith: aReviewTimes [
	"Choose the moments that fit the time box: the time already spent marking is taken out, my marks go first, then the most important moments, each costing my average time for its kind"

	| budget ordered |
	timeBox ifNil: [ ^ self ].
	budget := timeBox * 60 - self markingSeconds.
	ordered := (reviews select: [ :each | each isMarked ]) asArray
	           ,
		           ((reviews reject: [ :each | each isMarked ]) asArray
			            sort: [ :a :b | a score > b score ]).
	planned := Set new.
	plannedSeconds := 0.
	ordered do: [ :moment |
			| cost |
			cost := aReviewTimes expectedSecondsFor: moment kinds.
			(moment isMarked or: [ plannedSeconds + cost <= budget ]) ifTrue: [
					planned add: moment ply.
					plannedSeconds := plannedSeconds + cost ] ].
	self changed
]

{ #category : 'time box' }
CoachReview >> plannedMinutes [
	"The expected time of the planned moments plus the marking pass, in minutes"

	^ (plannedSeconds ifNil: [ 0 ]) + self markingSeconds / 60
]

{ #category : 'timing' }
CoachReview >> plySeconds [
	"Seconds spent on each ply during the marking pass"

	^ plySeconds
]

{ #category : 'private - timing' }
CoachReview >> recordShownPly [

	shownPly ifNil: [ ^ self ].
	plySeconds
		at: shownPly
		put: (plySeconds at: shownPly ifAbsent: [ 0 ])
			+ (self secondsSince: shownAt).
	shownPly := nil
]

{ #category : 'converting' }
CoachReview >> restoreFromJSON: aString analysis: aBlock [
	"Continue a saved review. A review saved before reviews had numbers (review.json) has no marks or timings.
	aBlock answers the game's analysis; it is evaluated only when the marking pass was done."

	| dictionary |
	dictionary := STONJSON fromString: aString.
	number := dictionary at: 'number' ifAbsent: [ 1 ].
	date := (dictionary at: 'date' ifAbsent: [ nil ])
		        ifNil: [ Date today ]
		        ifNotNil: [ :string | string asDate ].
	marks := (dictionary at: 'marks' ifAbsent: [ #(  ) ])
		         asOrderedCollection.
	plySeconds := Dictionary new.
	(dictionary at: 'plySeconds' ifAbsent: [ #(  ) ]) do: [ :pair |
		plySeconds at: pair first put: pair second ].
	timeBox := dictionary at: 'timeBox' ifAbsent: [ nil ].
	planned := (dictionary at: 'planned' ifAbsent: [ nil ]) ifNotNil: [
		           :plies | plies asSet ].
	plannedSeconds := dictionary at: 'plannedSeconds' ifAbsent: [ nil ].
	reviews := ((dictionary at: 'moments') collect: [ :each |
		            CoachMomentReview fromDictionary: each ])
		           asOrderedCollection.
	current := nil.
	(dictionary at: 'marking' ifAbsent: [ false ]) ifFalse: [
		analysis := aBlock value ]
]

{ #category : 'timing' }
CoachReview >> resumeClock [

	pausedAt ifNil: [ ^ self ].
	pausedTime := (pausedTime ifNil: [ Duration zero ])
	              + (clock value - pausedAt).
	pausedAt := nil
]

{ #category : 'revealing' }
CoachReview >> revealOf: aMomentReview [
	"What the engine says about a finished moment: my candidates' win %, the best line, the reply I missed and the proposed tags. Without Stockfish only my expected reply and the tags."

	| before after |
	self assert: aMomentReview isRevealed.
	before := analysis atPly: aMomentReview ply - 1.
	after := analysis atPly: aMomentReview ply.
	^ Dictionary new
		  at: 'candidates' put: aMomentReview candidateWinPercents;
		  at: 'bestLine'
		  put:
			  (before lines
				   ifEmpty: [ #(  ) ]
				   ifNotEmpty: [ before bestLine moves ]);
		  at: 'winBefore' put: (before winPercentFor: aMomentReview color);
		  at: 'winAfter' put: (after winPercentFor: aMomentReview color);
		  at: 'engineReply'
		  put:
			  (after lines
				   ifEmpty: [ nil ]
				   ifNotEmpty: [ after bestLine firstMove ]);
		  at: 'expectedReply'
		  put: ((aMomentReview answers anySatisfy: [ :each |
					    each question kind = #expectedReply ])
				   ifTrue: [ (aMomentReview answerTo: #expectedReply) moves ]
				   ifFalse: [ #(  ) ]);
		  at: 'labels' put: aMomentReview labels;
		  yourself
]

{ #category : 'accessing' }
CoachReview >> reviewedMoments [

	^ reviews select: [ :each | each isReviewed ]
]

{ #category : 'timing' }
CoachReview >> reviewingSeconds [
	"Time spent on the moments (questions and reveals), including the moment in progress"

	^ (reviews inject: 0 into: [ :sum :each | sum + each seconds ])
	  +
	  (current
		   ifNil: [ 0 ]
		   ifNotNil: [ self secondsSince: momentStartedAt ])
]

{ #category : 'accessing' }
CoachReview >> reviews [
	"The moments selected so far, each round in game order"

	^ reviews
]

{ #category : 'private - timing' }
CoachReview >> secondsSince: aDateAndTime [

	^ (self now - aDateAndTime) asMilliSeconds / 1000 roundTo: 0.1
]

{ #category : 'initialization' }
CoachReview >> setGameId: anId game: aGame engine: aStockfishEngine classifier: anAnswerClassifier [

	gameId := anId.
	game := aGame.
	engine := aStockfishEngine.
	classifier := anAnswerClassifier.
	number := 1.
	date := Date today.
	marks := OrderedCollection new.
	plySeconds := Dictionary new.
	reviews := OrderedCollection new.
	depth := 18.
	clock := [ DateAndTime now ].
	changedBlock := [ ].
	momentClosedBlock := [ ]
]

{ #category : 'marking' }
CoachReview >> showPly: aPly [
	"The marking pass now shows the position after aPly; the time on the previous one is recorded"

	self recordShownPly.
	shownPly := aPly.
	shownAt := self now
]

{ #category : 'navigating' }
CoachReview >> start: aMomentReview [
	"Ask about aMomentReview (or continue it)"

	self assert: self isMarking not.
	current := aMomentReview.
	aMomentReview isStarted ifFalse: [
		aMomentReview ask: (self openingQuestionsFor: aMomentReview) ].
	momentStartedAt := questionShownAt := self now.
	self changed
]

{ #category : 'report' }
CoachReview >> tagCounts [
	"How many times each counted tag appears in this review's mistakes"

	| counts |
	counts := Bag new.
	self mistakeRecords do: [ :each | counts addAll: each tagIds ].
	^ counts
]

{ #category : 'report' }
CoachReview >> tagsMoreThanUsualComparedTo: aMistakeDatabase [
	"Tags whose share of this review's mistakes is at least 1.5 times their share in my other games. Answer nil when there are fewer than 5 mistakes from other games to compare with."

	| mine others otherCounts |
	mine := self mistakeRecords.
	others := aMistakeDatabase records reject: [ :each |
		          each gameId = gameId ].
	others size < 5 ifTrue: [ ^ nil ].
	mine ifEmpty: [ ^ #(  ) ].
	otherCounts := Bag new.
	others do: [ :each | otherCounts addAll: each tagIds ].
	^ (self tagCounts asSet select: [ :tag |
			   (self tagCounts occurrencesOf: tag) / mine size
			   >= ((otherCounts occurrencesOf: tag) / others size * 1.5) ])
		  asArray sort
]

{ #category : 'private - timing' }
CoachReview >> takeAnswerSeconds [
	"Seconds since the current question was shown; the next question is shown now"

	| seconds |
	seconds := self secondsSince: questionShownAt.
	questionShownAt := self now.
	^ seconds
]

{ #category : 'time box' }
CoachReview >> timeBox [
	"Minutes I gave this analysis, or nil"

	^ timeBox
]

{ #category : 'time box' }
CoachReview >> timeBox: minutes [

	timeBox := minutes
]

{ #category : 'labels' }
CoachReview >> toggleTag: aTagId of: aMomentReview [

	aMomentReview toggleTag: aTagId.
	self changed
]

{ #category : 'timing' }
CoachReview >> totalSeconds [

	^ self markingSeconds + self reviewingSeconds
]

{ #category : 'marking' }
CoachReview >> unmark: aPly [

	self unmarkSilently: aPly.
	self changed
]

{ #category : 'private' }
CoachReview >> unmarkSilently: aPly [

	marks removeAllSuchThat: [ :each | (each at: 'ply') = aPly ]
]

{ #category : 'saving' }
CoachReview >> whenChangedDo: aBlock [

	changedBlock := aBlock
]

{ #category : 'saving' }
CoachReview >> whenMomentClosedDo: aBlock [

	momentClosedBlock := aBlock
]

{ #category : 'private' }
CoachReview >> winDropAt: aPly for: aColor [

	| before after |
	before := analysis atPly: aPly - 1.
	after := analysis atPly: aPly.
	(before lines isEmpty or: [ after lines isEmpty ]) ifTrue: [ ^ 0 ].
	^ (before winPercentFor: aColor) - (after winPercentFor: aColor)
		  max: 0
]
