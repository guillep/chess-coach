"
I answer canned engine lines per FEN (centipawns from White's point of view; one equal line for unknown positions) without starting Stockfish, and count the positions analysed.
"
Class {
	#name : 'StockfishEngineStub',
	#superclass : 'StockfishEngine',
	#instVars : [
		'scores',
		'analysedCount'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'analysing' }
StockfishEngineStub >> analyse: aFEN multiPV: lineCount depth: aDepth [

	analysedCount := analysedCount + 1.
	^ (scores at: aFEN ifAbsent: [ #( 0 ) ]) collect: [ :cp |
		  EngineLine
			  moves: #( 'a2a3' ) copy
			  centipawns: cp
			  sideToMove: #white ]
]

{ #category : 'accessing' }
StockfishEngineStub >> analysedCount [

	^ analysedCount
]

{ #category : 'accessing' }
StockfishEngineStub >> at: aFEN whiteCentipawns: someScores [

	scores at: aFEN put: someScores
]

{ #category : 'initialization' }
StockfishEngineStub >> initialize [

	super initialize.
	scores := Dictionary new.
	analysedCount := 0
]
