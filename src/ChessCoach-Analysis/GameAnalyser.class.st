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

	^ self analyse: aGame onProgress: [ :done :total |  ]
]

{ #category : 'analysing' }
GameAnalyser >> analyse: aGame onProgress: aBlock [
	"aBlock receives the number of positions analysed so far and the total, after each one"

	| total |
	total := aGame moves size + 1.
	^ GameAnalysis
		  depth: depth
		  plies: ((0 to: aGame moves size) collect: [ :ply |
					   | fen analysis |
					   fen := (aGame positionAfterPly: ply) fen.
					   analysis := PlyAnalysis
						               ply: ply
						               fen: fen
						               lines:
						               (engine
							                analyse: fen
							                multiPV: multiPV
							                depth: depth).
					   aBlock value: ply + 1 value: total.
					   analysis ])
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
GameAnalyser >> engine [

	^ engine
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
