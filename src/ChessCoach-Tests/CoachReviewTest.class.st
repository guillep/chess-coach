Class {
	#name : 'CoachReviewTest',
	#superclass : 'TestCase',
	#instVars : [
		'game',
		'analysis',
		'engine',
		'client'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
CoachReviewTest >> answerFirstMoment: review [

	review answerMoves: #( 'f3g5' 'd2d3' ).
	review answerText: 'I wanted to attack f7'.
	review answerMoves: #( 'h7h6' ).
	[ review currentMoment isRevealed ] whileFalse: [
		review answerText: 'I did not see it' ]
]

{ #category : 'helpers' }
CoachReviewTest >> line: aUCIMove whiteCentipawns: aNumber [

	^ EngineLine
		  moves: { aUCIMove }
		  centipawns: aNumber
		  sideToMove: #white
]

{ #category : 'helpers' }
CoachReviewTest >> newReview [

	^ (CoachReview
		   gameId: 'g1'
		   game: game
		   analysis: analysis
		   moments: {
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
		   engine: engine
		   classifier:
			   (AnswerClassifier
				    client: client
				    taxonomy: MistakeTaxonomy default))
		  batchSize: 1;
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
											               line: 'a2a3'
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
CoachReviewTest >> testDialogue [

	| review moment reveal |
	review := self newReview.
	review reviewMore.
	self
		assert: (review reviews collect: [ :each | each ply ]) asArray
		equals: #( 7 ).
	self assert: review hasMore.
	self assert: review currentQuestion kind equals: #candidates.
	review answerMoves: #( 'f3g5' 'd2d3' ).
	self
		assert: review currentQuestion text
		equals: 'Why did you play Ng5?'.
	review answerText: 'I wanted to attack f7'.
	self assert: review currentQuestion kind equals: #expectedReply.
	review answerMoves: #( 'h7h6' ).
	moment := review currentMoment.
	self
		assert:
		(moment pending collect: [ :each | each kind -> each move ]) asArray
		equals: {
				(#whyNotConsidered -> 'd2d4').
				(#whyNotConsidered -> 'b1c3').
				(#whyNotBetter -> 'd2d3') }.
	3 timesRepeat: [ review answerText: 'I did not see it' ].
	self assert: moment isRevealed.
	reveal := review revealOf: moment.
	self assert: (reveal at: 'bestLine') equals: #( 'd2d4' ).
	self assert: (reveal at: 'expectedReply') equals: #( 'h7h6' ).
	self assert: ((reveal at: 'candidates') at: 'd2d3')
		> ((reveal at: 'candidates') at: 'f3g5').
	self
		assert: (moment labels collect: [ :each | each tagId ]) asArray
		equals: #( 'missed-opponent-threat' ).
	moment confirmTag: 'hope-chess'.
	review nextMoment.
	self assert: review isFinished
]

{ #category : 'tests' }
CoachReviewTest >> testIllegalCandidate [

	| review |
	review := self newReview.
	review reviewMore.
	self
		should: [ review answerMoves: #( 'e1e3' ) ]
		raise: CoachIllegalMove.
	self assert: review currentQuestion kind equals: #candidates
]

{ #category : 'tests' }
CoachReviewTest >> testMistakeRecordsAndJSON [

	| review record restored |
	review := self newReview.
	review reviewMore.
	self answerFirstMoment: review.
	review currentMoment confirmTag: 'missed-opponent-threat'.
	record := review mistakeRecords first.
	self assert: review mistakeRecords size equals: 1.
	self assert: record playedMove equals: 'f3g5'.
	self assert: record bestMove equals: 'd2d4'.
	self assert: record phase equals: 'opening'.
	self assert: record date equals: (Date year: 2026 month: 10 day: 20).
	self assert: record explanation equals: 'I wanted to attack f7'.
	self assert: (record winDrop between: 17 and: 19).
	self assert: record labels first isConfirmed.
	restored := self newReview
		            restoreFromJSON: review asJSON;
		            yourself.
	self assert: restored reviews size equals: 1.
	self assert: restored hasMore.
	self
		assert:
		(restored mistakeRecords collect: [ :each | each asDictionary ])
		equals:
		(review mistakeRecords collect: [ :each | each asDictionary ])
]

{ #category : 'tests' }
CoachReviewTest >> testReviewMoreAddsTheNextMoments [

	| review |
	review := self newReview.
	review reviewMore.
	self answerFirstMoment: review.
	review nextMoment.
	review reviewMore.
	self deny: review hasMore.
	self deny: review isFinished.
	self assert: review currentMoment ply equals: 3.
	self assert: review currentQuestion kind equals: #whatDidYouSee.
	review answerText: 'The knight fork'.
	self assert: review currentMoment isRevealed.
	self assert: review mistakeRecords size equals: 1
]
