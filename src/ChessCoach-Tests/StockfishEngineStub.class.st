"
I answer canned engine lines per FEN (centipawns from White's point of view; one equal line for unknown positions) without starting Stockfish, and count the positions analysed.
"
Class {
	#name : 'StockfishEngineStub',
	#superclass : 'StockfishEngine',
	#instVars : [
		'scores',
		'analysedCount',
		'moveScores'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'analysing' }
StockfishEngineStub >> analyse: aFEN multiPV: lineCount depth: aDepth searchMoves: someUCIMoves [
	"Lines start with a rook-pawn move of the side to move, legal in the opening positions the tests use"

	analysedCount := analysedCount + 1.
	someUCIMoves ifNotEmpty: [
			^ someUCIMoves asArray collect: [ :move |
					  EngineLine
						  moves: { move }
						  centipawns: (moveScores at: move ifAbsent: [ 0 ])
						  sideToMove: #white ] ].
	^ (scores at: aFEN ifAbsent: [ #( 0 ) ]) collect: [ :cp |
			  EngineLine
				  moves: ((aFEN substrings at: 2) = 'w'
						   ifTrue: [ #( 'a2a3' ) ]
						   ifFalse: [ #( 'a7a6' ) ]) copy
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
	moveScores := Dictionary new.
	analysedCount := 0
]

{ #category : 'accessing' }
StockfishEngineStub >> move: aUCIMove whiteCentipawns: aNumber [
	"Score answered for aUCIMove when it is analysed with searchmoves"

	moveScores at: aUCIMove put: aNumber
]
