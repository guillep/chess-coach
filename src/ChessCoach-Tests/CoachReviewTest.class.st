Class {
	#name : 'CoachReviewTest',
	#superclass : 'TestCase',
	#instVars : [
		'game',
		'analysis',
		'engine',
		'client',
		'now'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
CoachReviewTest >> analysisForTests [

	^ analysis
]

{ #category : 'helpers' }
CoachReviewTest >> answerFirstMoment: review [

	review start: (review moments detect: [ :each | each ply = 7 ]).
	review answerMoves: #( 'f3g5' 'd2d3' ).
	review answerText: 'I wanted to attack f7'.
	review answerMoves: #( 'h7h6' ).
	[ review currentMoment isRevealed ] whileFalse: [
		review answerText: 'I did not see it' ].
	review classifyPending
]

{ #category : 'helpers' }
CoachReviewTest >> line: aUCIMove whiteCentipawns: aNumber [

	^ EngineLine
		  moves: { aUCIMove }
		  centipawns: aNumber
		  sideToMove: #white
]

{ #category : 'helpers' }
CoachReviewTest >> momentsForTests [
	"Moments at ply 3 (only move found) and 7 (mistake)"

	^ {
		  (ChessMoment
			   ply: 3
			   color: #white
			   kind: #onlyMoveFound
			   source: #engine
			   note: nil).
		  (ChessMoment
			   ply: 7
			   color: #white
			   kind: #mistake
			   source: #engine
			   note: nil) }
]

{ #category : 'helpers' }
CoachReviewTest >> newReview [
	"A review whose marking pass is done: moments at ply 3 (only move found) and 7 (mistake)"

	^ self newReviewMarking
		  finishMarkingWith: analysis moments: self momentsForTests;
		  yourself
]

{ #category : 'helpers' }
CoachReviewTest >> newReviewMarking [

	now := DateAndTime year: 2026 month: 10 day: 29.
	^ (CoachReview
		   gameId: 'g1'
		   game: game
		   engine: engine
		   classifier:
			   (AnswerClassifier
				    client: client
				    taxonomy: MistakeTaxonomy default))
		  clock: [ now ];
		  yourself
]

{ #category : 'running' }
CoachReviewTest >> setUp [

	super setUp.
	game := PGNParser new parse: '[UTCDate "2026.10.20"]

1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. Ng5'.
	"White is fine until 4. Ng5 (ply 7), which the engine thinks drops from +0.50 to -1.50"
	analysis := GameAnalysis
		            depth: 18
		            plies: ((0 to: 7) collect: [ :ply |
					             PlyAnalysis
						             ply: ply
						             fen: (game positionAfterPly: ply) fen
						             lines: (ply = 6
								              ifTrue: [
										              {
											              (self line: 'd2d4' whiteCentipawns: 50).
											              (self line: 'b1c3' whiteCentipawns: 40) } ]
								              ifFalse: [
										              { (self
											               line: (ply even
													                ifTrue: [ 'a2a3' ]
													                ifFalse: [ 'a7a6' ])
											               whiteCentipawns: (ply = 7
													                ifTrue: [ -150 ]
													                ifFalse: [ 50 ])) } ]) ]).
	engine := StockfishEngineStub new
		          move: 'f3g5' whiteCentipawns: -150;
		          move: 'd2d3' whiteCentipawns: 30;
		          yourself.
	client := OllamaClientStub new replyContent:
		          '{"tags":[{"tag":"missed-opponent-threat","confidence":0.7}]}'
]

{ #category : 'tests' }
CoachReviewTest >> testClassificationWaitsForOllamaAndSavesEveryChange [

	| review saves |
	client replyContent: nil.
	review := self newReview.
	saves := 0.
	review whenChangedDo: [ saves := saves + 1 ].
	self answerFirstMoment: review.
	self assert: saves equals: 7.
	self assert: review currentMoment isClassifying.
	self assert: review currentMoment labels isEmpty.
	client replyContent:
		'{"tags":[{"tag":"hope-chess","confidence":0.6}]}'.
	review classifyPending.
	self deny: review currentMoment isClassifying.
	self
		assert:
		(review currentMoment labels collect: [ :each | each tagId ])
			asArray
		equals: #( 'hope-chess' ).
	self assert: saves equals: 7 + 4
]

{ #category : 'tests' }
CoachReviewTest >> testDialogue [

	| review moment reveal |
	review := self newReview.
	self
		assert: (review moments collect: [ :each | each ply ]) asArray
		equals: #( 3 7 ).
	self deny: (review moments anySatisfy: [ :each | each isStarted ]).
	moment := review moments second.
	review start: moment.
	self assert: review currentQuestion kind equals: #candidates.
	self assert:
		(review currentQuestion text beginsWith: 'Your move was bad.').
	review answerMoves: #( 'f3g5' 'd2d3' ).
	self
		assert: review currentQuestion text
		equals: 'Why did you play Ng5?'.
	review answerText: 'I wanted to attack f7'.
	self assert: review currentQuestion kind equals: #expectedReply.
	review answerMoves: #( 'h7h6' ).
	self
		assert:
		(moment pending collect: [ :each | each kind -> each move ]) asArray
		equals: {
				(#whyNotConsidered -> 'd2d4').
				(#whyNotConsidered -> 'b1c3').
				(#whyNotBetter -> 'd2d3') }.
	self
		assert: moment pending first text
		equals: 'You didn''t consider d4. Why?'.
	self
		assert: moment pending last text
		equals:
		'You discarded d3, which was better than Ng5. Why did you discard it?'.
	3 timesRepeat: [ review answerText: 'I did not see it' ].
	self assert: moment isReviewed.
	self assert: moment isClassifying.
	review classifyPending.
	self deny: moment isClassifying.
	reveal := review revealOf: moment.
	self assert: (reveal at: 'bestLine') equals: #( 'd2d4' ).
	self assert: (reveal at: 'expectedReply') equals: #( 'h7h6' ).
	self assert: ((reveal at: 'candidates') at: 'd2d3')
		> ((reveal at: 'candidates') at: 'f3g5').
	self
		assert: (moment labels collect: [ :each | each tagId ]) asArray
		equals: #( 'missed-opponent-threat' ).
	review confirmTag: 'hope-chess' of: moment.
	review leaveMoment.
	self assert: review currentMoment isNil.
	self assert: (review nextMomentAfter: 7) isNil.
	self assert: (review nextMomentAfter: 0) ply equals: 3
]

{ #category : 'tests' }
CoachReviewTest >> testDiscardedBadCandidatesAreNotQuestioned [
	"Candidates are considered before calculating: a bad one I discarded was discarded rightly. Only moves I missed and a better move I discarded are asked about"

	| review moment |
	review := self newReview.
	moment := review moments second.
	review start: moment.
	review answerMoves: #( 'f3g5' 'b1a3' 'd2d3' ).
	review answerText: 'I wanted to attack f7'.
	review answerMoves: #( 'h7h6' ).
	self assert:
		((moment pending collect: [ :each | each kind ]) asSet includesAll:
			 #( #whyNotConsidered #whyNotBetter )).
	self assert: ((moment pending collect: [ :each | each kind ]) asSet
			 copyWithoutAll: #( #whyNotConsidered #whyNotBetter )) isEmpty.
	self
		assert:
		(moment pending count: [ :each | each kind = #whyNotBetter ])
		equals: 1
]

{ #category : 'tests' }
CoachReviewTest >> testFoundOnlyMoveIsNotAMistake [

	| review |
	review := self newReview.
	self answerFirstMoment: review.
	review leaveMoment.
	review start: (review nextMomentAfter: 0).
	self assert: review currentMoment ply equals: 3.
	self assert: review currentQuestion kind equals: #whatDidYouSee.
	review answerText: 'The knight fork'.
	self assert: review currentMoment isReviewed.
	self assert: review mistakeRecords size equals: 1
]

{ #category : 'tests' }
CoachReviewTest >> testIllegalCandidate [

	| review |
	review := self newReview.
	review start: review moments last.
	self
		should: [ review answerMoves: #( 'e1e3' ) ]
		raise: CoachIllegalMove.
	self assert: review currentQuestion kind equals: #candidates
]

{ #category : 'tests' }
CoachReviewTest >> testMarkingPass [

	| review restored |
	review := self newReviewMarking.
	self assert: review isMarking.
	review showPly: 1.
	self wait: 4.
	review showPly: 2.
	self wait: 6.
	review mark: 3 note: 'not sure'.
	review mark: 5 note: ''.
	review unmark: 5.
	review showPly: 1.
	self wait: 2.
	self assert: (review isMarked: 3).
	self deny: (review isMarked: 5).
	review finishMarkingWith: analysis moments: {
			(ChessMoment
				 ply: 3
				 color: #white
				 kind: #marked
				 source: #marks
				 note: 'not sure').
			(ChessMoment
				 ply: 5
				 color: #white
				 kind: #inaccuracy
				 source: #engine
				 note: nil).
			(ChessMoment
				 ply: 7
				 color: #white
				 kind: #mistake
				 source: #engine
				 note: nil) }.
	self deny: review isMarking.
	self assert: (review plySeconds at: 1) equals: 6.
	self assert: (review plySeconds at: 2) equals: 6.
	self assert: review markingSeconds equals: 12.
	self
		assert:
		(review moments collect: [ :each | each ply ])
			asArray
		equals: #( 3 5 7 ).
	self assert: (review moments last winDrop between: 17 and: 19).
	restored := self newReviewMarking
		            restoreFromJSON: review asJSON analysis: [ analysis ];
		            yourself.
	self assert: restored marks size equals: 1.
	self assert: restored markingSeconds equals: 12
]

{ #category : 'tests' }
CoachReviewTest >> testMistakeRecordsAndJSON [

	| review record restored |
	review := self newReview.
	self answerFirstMoment: review.
	review currentMoment confirmTag: 'missed-opponent-threat'.
	review leaveMoment.
	record := review mistakeRecords first.
	self assert: review mistakeRecords size equals: 1.
	self assert: record playedMove equals: 'f3g5'.
	self assert: record bestMove equals: 'd2d4'.
	self assert: record phase equals: 'opening'.
	self assert: record date equals: (Date year: 2026 month: 10 day: 20).
	self assert: record explanation equals: 'I wanted to attack f7'.
	self assert: (record winDrop between: 17 and: 19).
	self assert: record labels first isConfirmed.
	restored := self newReviewMarking
		            restoreFromJSON: review asJSON analysis: [ analysis ];
		            yourself.
	self deny: restored isMarking.
	self assert: restored moments size equals: 2.
	self deny: restored moments first isStarted.
	self assert: restored moments last isReviewed.
	self
		assert:
		(restored mistakeRecords collect: [ :each | each asDictionary ])
		equals:
		(review mistakeRecords collect: [ :each | each asDictionary ])
]

{ #category : 'tests' }
CoachReviewTest >> testPausedTimeIsNotCounted [

	| time start review |
	start := time := DateAndTime year: 2026 month: 10 day: 29.
	review := CoachReview new.
	review clock: [ time ].
	review pauseClock.
	time := time + 30 seconds.
	review resumeClock.
	time := time + 5 seconds.
	self assert: review now - start equals: 5 seconds
]

{ #category : 'tests' }
CoachReviewTest >> testTagsMoreThanUsual [

	| review others database |
	review := self newReview.
	self answerFirstMoment: review.
	review leaveMoment.
	others := (1 to: 6) collect: [ :each |
			          MistakeRecord new
				          gameId: 'other' , each printString;
				          ply: 3;
				          date: Date today;
				          labels: { (MistakeLabel
						           tagId: (each = 1
								            ifTrue: [ 'missed-opponent-threat' ]
								            ifFalse: [ 'hope-chess' ])
						           confidence: 1) };
				          yourself ].
	database := MistakeDatabase withRecords: others.
	self
		assert: (review tagsMoreThanUsualComparedTo: database)
		equals: #( 'missed-opponent-threat' ).
	self assert: (review tagsMoreThanUsualComparedTo:
			 (MistakeDatabase withRecords: (others first: 2))) isNil.
	self
		assert: (review tagCounts occurrencesOf: 'missed-opponent-threat')
		equals: 1.
	self assert: (review kindCounts occurrencesOf: #mistake) equals: 1
]

{ #category : 'tests' }
CoachReviewTest >> testTimeBoxIsATimer [

	| review |
	review := self newReview.
	review timeBox: 1.
	self deny: review isOverTime.
	self assert: review leftOutMoments isEmpty.
	review timeBox: 0.
	self wait: 1.
	review start: review moments first.
	self wait: 1.
	review leaveMoment.
	self assert: review isOverTime.
	self assert: review leftOutMoments size equals: review moments size
]

{ #category : 'tests' }
CoachReviewTest >> testTimings [

	| review moment |
	review := self newReview.
	moment := review moments last.
	review start: moment.
	self wait: 30.
	review answerMoves: #( 'f3g5' ).
	self wait: 45.
	review answerText: 'attack'.
	self wait: 10.
	review leaveMoment.
	self
		assert: (moment answers collect: [ :each | each seconds ]) asArray
		equals: #( 30 45 ).
	self assert: moment seconds equals: 85.
	self assert: review reviewingSeconds equals: 85.
	review start: moment.
	self wait: 5.
	review leaveMoment.
	self assert: moment seconds equals: 90.
	self
		assert:
		(CoachMomentReview fromDictionary: moment asDictionary) seconds
		equals: 90
]

{ #category : 'tests' }
CoachReviewTest >> testWithoutOllama [

	| review |
	client replyContent: nil.
	review := self newReview.
	self answerFirstMoment: review.
	self assert: review isClassifierUnavailable.
	self assert: review currentMoment isClassifying.
	client replyContent: '{"tags":[]}'.
	review classifyPending.
	self deny: review isClassifierUnavailable
]

{ #category : 'tests' }
CoachReviewTest >> testWithoutStockfish [

	| review moment record |
	review := self newReviewMarking.
	review mark: 7 note: 'unsure'.
	review
		finishMarkingWith: (GameAnalysis withoutEngineFor: game)
		moments: { (ChessMoment
				 ply: 7
				 color: #white
				 kind: #marked
				 source: #marks
				 note: 'unsure') }.
	self deny: review hasEngine.
	moment := review moments first.
	review start: moment.
	self
		deny: review currentQuestion kind = #candidates
		description: 'a marked move is not known to be bad: no candidates'.
	review answerText: 'attack'.
	review answerMoves: #( 'h7h6' ).
	self
		assert: moment isReviewed
		description: 'no engine questions are added'.
	self assert: ((review revealOf: moment) at: 'bestLine') isEmpty.
	review classifyPending.
	record := review mistakeRecords first.
	self assert: record bestMove isNil.
	self assert: record winDrop equals: 0
]

{ #category : 'helpers' }
CoachReviewTest >> wait: seconds [

	now := now + seconds seconds
]
