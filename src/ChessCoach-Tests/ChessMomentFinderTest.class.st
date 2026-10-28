Class {
	#name : 'ChessMomentFinderTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
ChessMomentFinderTest >> analysisWithWhiteCentipawns: lineScores [
	"lineScores holds, per position from ply 0, the engine lines' scores in centipawns from White's point of view"

	^ GameAnalysis
		  depth: 18
		  plies: (lineScores withIndexCollect: [ :scores :index |
					   | ply |
					   ply := index - 1.
					   PlyAnalysis
						   ply: ply
						   fen: '8/8/8/8/8/8/8/8 ' , (ply even
								    ifTrue: [ 'w' ]
								    ifFalse: [ 'b' ]) , ' - - 0 1'
						   lines: (scores collect: [ :cp |
								    EngineLine
									    moves: #( 'a2a3' )
									    centipawns: cp
									    sideToMove: #white ]) ])
]

{ #category : 'tests' }
ChessMomentFinderTest >> testBlunderIsAWinChanceDropOfThirtyPoints [
	"+0.50 is 54.6% for White and -4.00 is 18.7%: a 36 point drop"

	| moments |
	moments := (EvaluationJumpFinder on:
		            (self analysisWithWhiteCentipawns:
			             #( #( 50 ) #( -400 ) #( -400 ) ))) moments.
	self assert: moments size equals: 1.
	self assert: moments first ply equals: 1.
	self assert: moments first color equals: #white.
	self assert: moments first kinds asArray equals: #( #blunder )
]

{ #category : 'tests' }
ChessMomentFinderTest >> testGameAnalysisRoundTripsThroughJSON [

	| analysis copy |
	analysis := self analysisWithWhiteCentipawns:
		            #( #( 35 -10 ) #( 40 ) ).
	copy := GameAnalysis fromJSON: analysis asJSON.
	self assert: copy depth equals: 18.
	self assert: copy moveCount equals: 1.
	self
		assert: ((copy atPly: 0) lines second winPercentFor: #white)
		equals: ((analysis atPly: 0) lines second winPercentFor: #white).
	self assert: (copy atPly: 1) sideToMove equals: #black
]

{ #category : 'tests' }
ChessMomentFinderTest >> testNoOnlyMoveWhenSeveralMovesAreGoodOrTheGameIsDecided [

	self assert: (OnlyMoveFinder on:
			 (self analysisWithWhiteCentipawns: #( #( 0 -20 -40 )
			     #( 0 ) ))) moments isEmpty.
	self assert: (OnlyMoveFinder on:
			 (self analysisWithWhiteCentipawns: #( #( 900 600 ) #( 900 ) )))
			moments isEmpty
]

{ #category : 'tests' }
ChessMomentFinderTest >> testOnlyMoveFound [

	| moments |
	moments := (OnlyMoveFinder on:
		            (self analysisWithWhiteCentipawns:
			             #( #( 0 -300 -400 ) #( 0 ) ))) moments.
	self assert: moments size equals: 1.
	self assert: (moments first kinds includes: #onlyMoveFound)
]

{ #category : 'tests' }
ChessMomentFinderTest >> testOnlyMoveMissed [

	| moments |
	moments := (OnlyMoveFinder on:
		            (self analysisWithWhiteCentipawns:
			             #( #( 0 -300 -400 ) #( -300 ) ))) moments.
	self assert: moments size equals: 1.
	self assert: (moments first kinds includes: #onlyMoveMissed)
]

{ #category : 'tests' }
ChessMomentFinderTest >> testSmallDropsAreIgnoredAndBlackDropsCount [

	| moments |
	moments := (EvaluationJumpFinder on:
		            (self analysisWithWhiteCentipawns:
			             #( #( 20 ) #( 0 ) #( 150 ) ))) moments.
	self assert: moments size equals: 1.
	self assert: moments first ply equals: 2.
	self assert: moments first color equals: #black.
	self assert: (moments first kinds includes: #inaccuracy)
]
