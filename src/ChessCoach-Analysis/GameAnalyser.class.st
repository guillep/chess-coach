"
I analyse every position of a game once with an engine (a StockfishEngine), answering a GameAnalysis. Defaults: depth 18, 3 lines.
"
Class {
	#name : 'GameAnalyser',
	#superclass : 'Object',
	#instVars : [
		'engine',
		'depth',
		'multiPV'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
GameAnalyser class >> engine: anEngine [

	^ self new
		  setEngine: anEngine;
		  yourself
]

{ #category : 'analysing' }
GameAnalyser >> analyse: aGame [

	^ GameAnalysis
		  depth: depth
		  plies: ((0 to: aGame moves size) collect: [ :ply |
					   | fen |
					   fen := (aGame positionAfterPly: ply) fen.
					   PlyAnalysis
						   ply: ply
						   fen: fen
						   lines: (engine analyse: fen multiPV: multiPV depth: depth) ])
]

{ #category : 'accessing' }
GameAnalyser >> depth [

	^ depth
]

{ #category : 'accessing' }
GameAnalyser >> depth: aNumber [

	depth := aNumber
]

{ #category : 'accessing' }
GameAnalyser >> multiPV: aNumber [

	multiPV := aNumber
]

{ #category : 'initialization' }
GameAnalyser >> setEngine: anEngine [

	engine := anEngine.
	depth := 18.
	multiPV := 3
]
