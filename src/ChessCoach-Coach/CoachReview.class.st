"
Headless Socratic review of a game. Goes through my marked moments and the most important automatic ones (batchSize at a time, in game order), asks CoachQuestions, evaluates my candidates with the engine, classifies my text answers and reveals the truth at the end of each moment. Produces MistakeRecords and round-trips through JSON (games/<id>.review.json).
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
		'queue',
		'reviews',
		'current',
		'batchSize',
		'depth',
		'changedBlock',
		'momentClosedBlock'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'instance creation' }
CoachReview class >> gameId: anId game: aGame analysis: aGameAnalysis moments: someMoments engine: aStockfishEngine classifier: anAnswerClassifier [

	^ self new
		  setGameId: anId
		  game: aGame
		  analysis: aGameAnalysis
		  moments: someMoments
		  engine: aStockfishEngine
		  classifier: anAnswerClassifier
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
		(CoachAnswer question: question moves: someUCIMoves).
	question kind = #expectedReply ifTrue: [ self askAboutCandidates ].
	self changed
]

{ #category : 'answering' }
CoachReview >> answerText: aString [
	"Answer a written question at once; classifyPending tags it later"

	| question |
	question := self currentQuestion.
	self assert: question expectsMoves not.
	self currentMoment answer:
		(CoachAnswer question: question text: aString).
	self changed
]

{ #category : 'converting' }
CoachReview >> asJSON [
	"The review file content: my answers per moment plus the mistake records derived from them"

	^ STONJSON toString: (Dictionary new
			   at: 'game' put: gameId;
			   at: 'current' put: current;
			   at: 'moments'
			   put: (reviews collect: [ :each | each asDictionary ]) asArray;
			   at: 'mistakes'
			   put:
				   (self mistakeRecords collect: [ :each | each asDictionary ])
					   asArray;
			   yourself)
]

{ #category : 'private - questions' }
CoachReview >> askAboutCandidates [
	"Evaluate my candidates with the engine and ask about good moves I missed, bad candidates and better alternatives"

	| moment before played candidates best playedWin questions better |
	moment := self currentMoment.
	before := analysis atPly: moment ply - 1.
	played := game uciMoves at: moment ply.
	candidates := ((moment answerTo: #candidates) moves copyWith: played)
		              asSet asArray.
	(engine
		 analyse: before fen
		 multiPV: candidates size
		 depth: depth
		 searchMoves: candidates) do: [ :line |
			moment
				candidate: line firstMove
				winPercent: (line winPercentFor: moment color) ].
	best := before winPercentFor: moment color.
	playedWin := moment candidateWinPercents
		             at: played
		             ifAbsent: [ best ].
	questions := OrderedCollection new.
	before lines do: [ :line |
			((line winPercentFor: moment color) >= (best - 10) and: [
				 (candidates includes: line firstMove) not ]) ifTrue: [
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

{ #category : 'accessing' }
CoachReview >> batchSize: anInteger [
	"How many automatic moments each round reviews (marked moments are always included)"

	batchSize := anInteger
]

{ #category : 'saving' }
CoachReview >> changed [
	"Every answer, tag change and move to the next moment is saved at once"

	changedBlock value
]

{ #category : 'answering' }
CoachReview >> classifyPending [
	"Classify every written answer not classified yet. Slow (local LLM): call it off the UI thread.
	The design keeps answers unclassified while Ollama is not running, so a connection failure stops this round without an error; the next call retries."

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
							          on: NetworkError
							          do: [ ^ self ].
						answer classifiedAs: labels.
						moment proposeLabels: labels.
						self changed ] ]
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
	^ 'Position (FEN): {1}. I played {2} ({3}); the engine''s best move was {4}.'
		  format: {
				  before fen.
				  (game moves at: aMomentReview ply) san.
				  (', ' join: aMomentReview kinds).
				  (before sanOf: before bestLine firstMove) }
]

{ #category : 'navigating' }
CoachReview >> currentMoment [

	^ reviews at: current
]

{ #category : 'navigating' }
CoachReview >> currentQuestion [

	^ self currentMoment currentQuestion
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
CoachReview >> hasMore [
	"Whether reviewMore would select further moments"

	^ queue notEmpty
]

{ #category : 'testing' }
CoachReview >> isFinished [
	"Whether every selected moment has been reviewed and left"

	^ current > reviews size
]

{ #category : 'mistakes' }
CoachReview >> mistakeRecordFor: aMomentReview [

	| before after explanation |
	before := analysis atPly: aMomentReview ply - 1.
	after := analysis atPly: aMomentReview ply.
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
		  bestMove: before bestLine firstMove;
		  winDrop: ((before winPercentFor: aMomentReview color)
			   - (after winPercentFor: aMomentReview color) max: 0);
		  explanation: explanation;
		  labels: aMomentReview labels asArray;
		  yourself
]

{ #category : 'mistakes' }
CoachReview >> mistakeRecords [
	"One record per reviewed moment that was not a success (found only moves are not mistakes)"

	^ reviews
		  select: [ :each |
				  each isRevealed and: [
					  (each kinds copyWithout: #onlyMoveFound) notEmpty ] ]
		  thenCollect: [ :each | self mistakeRecordFor: each ]
]

{ #category : 'navigating' }
CoachReview >> nextMoment [
	"Leave the current moment once its reveal has been seen"

	self assert: self currentMoment isRevealed.
	current := current + 1.
	self changed.
	momentClosedBlock value
]

{ #category : 'private - questions' }
CoachReview >> openingQuestionsFor: aMoment [

	| played |
	played := (game moves at: aMoment ply) san.
	(aMoment kinds includesAny:
		 #( #inaccuracy #mistake #blunder #onlyMoveMissed #marked ))
		ifTrue: [
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

{ #category : 'converting' }
CoachReview >> restoreFromJSON: aString [
	"Continue a saved review: restore the moments already selected and drop them from the queue"

	| dictionary |
	dictionary := STONJSON fromString: aString.
	reviews := ((dictionary at: 'moments') collect: [ :each |
		            CoachMomentReview fromDictionary: each ])
		           asOrderedCollection.
	current := dictionary at: 'current'.
	queue removeAllSuchThat: [ :moment |
		reviews anySatisfy: [ :each | each ply = moment ply ] ]
]

{ #category : 'revealing' }
CoachReview >> revealOf: aMomentReview [
	"What the engine says about a finished moment: my candidates' win %, the best line, the reply I missed and the proposed tags"

	| before after |
	self assert: aMomentReview isRevealed.
	before := analysis atPly: aMomentReview ply - 1.
	after := analysis atPly: aMomentReview ply.
	^ Dictionary new
		  at: 'candidates' put: aMomentReview candidateWinPercents;
		  at: 'bestLine' put: before bestLine moves;
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

{ #category : 'navigating' }
CoachReview >> reviewMore [
	"Select the next round: all remaining marked moments plus the batchSize most important others"

	| marked others |
	marked := queue select: [ :each | each isMarked ].
	others := (queue reject: [ :each | each isMarked ]) first:
		          (batchSize min:
			           (queue count: [ :each | each isMarked not ])).
	queue
		removeAll: marked;
		removeAll: others.
	((marked , others) asArray sort: [ :a :b | a ply < b ply ]) do: [
			:moment |
			reviews add: (CoachMomentReview
					 ply: moment ply
					 color: moment color
					 kinds: moment kinds
					 questions: (self openingQuestionsFor: moment)) ]
]

{ #category : 'accessing' }
CoachReview >> reviews [
	"The moments selected so far, each round in game order"

	^ reviews
]

{ #category : 'initialization' }
CoachReview >> setGameId: anId game: aGame analysis: aGameAnalysis moments: someMoments engine: aStockfishEngine classifier: anAnswerClassifier [

	gameId := anId.
	game := aGame.
	analysis := aGameAnalysis.
	queue := ((MomentPrioritizer on: aGameAnalysis) byImportance:
		          someMoments) asOrderedCollection.
	engine := aStockfishEngine.
	classifier := anAnswerClassifier.
	reviews := OrderedCollection new.
	current := 1.
	batchSize := 5.
	depth := 18.
	changedBlock := [ ].
	momentClosedBlock := [ ]
]

{ #category : 'saving' }
CoachReview >> whenChangedDo: aBlock [

	changedBlock := aBlock
]

{ #category : 'saving' }
CoachReview >> whenMomentClosedDo: aBlock [

	momentClosedBlock := aBlock
]
