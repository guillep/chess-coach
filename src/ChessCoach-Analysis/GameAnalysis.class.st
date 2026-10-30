"
I am the engine analysis of every position of a game, made at a given depth. I read and write myself as JSON.
"
Class {
	#name : 'GameAnalysis',
	#superclass : 'Object',
	#instVars : [
		'depth',
		'plies',
		'multiPV'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
GameAnalysis class >> depth: aNumber plies: aCollection [
	"aCollection holds one PlyAnalysis per position, ply 0 first"

	^ self new setDepth: aNumber plies: aCollection
]

{ #category : 'constants' }
GameAnalysis class >> formatVersion [
	"The version of the analysis file format. A file without one is version 0."

	^ 1
]

{ #category : 'instance creation' }
GameAnalysis class >> fromJSON: aString [

	| dictionary |
	dictionary := STONJSON fromString: aString.
	^ (self
		   depth: (dictionary at: 'depth')
		   plies: ((dictionary at: 'plies') collect: [ :each |
					    PlyAnalysis fromDictionary: each ]))
		  multiPV: (dictionary at: 'multiPV' ifAbsent: [ 3 ]);
		  yourself
]

{ #category : 'instance creation' }
GameAnalysis class >> withoutEngineFor: aGame [
	"An analysis with the positions of aGame but no engine lines, used when Stockfish is not available"

	^ self depth: 0 plies: ((0 to: aGame moves size) collect: [ :ply |
				   PlyAnalysis
					   ply: ply
					   fen: (aGame positionAfterPly: ply) fen
					   lines: #(  ) ])
]

{ #category : 'converting' }
GameAnalysis >> asJSON [

	^ STONJSON toString: (Dictionary new
			   at: 'formatVersion' put: self class formatVersion;
			   at: 'depth' put: depth;
			   at: 'multiPV' put: self multiPV;
			   at: 'plies' put: (plies collect: [ :each | each asDictionary ]);
			   yourself)
]

{ #category : 'accessing' }
GameAnalysis >> atPly: aNumber [
	"The analysis of the position after aNumber half-moves"

	^ plies at: aNumber + 1
]

{ #category : 'accessing' }
GameAnalysis >> depth [

	^ depth
]

{ #category : 'testing' }
GameAnalysis >> hasEngineLines [
	"False for an analysis made without Stockfish"

	^ plies anySatisfy: [ :each | each lines notEmpty ]
]

{ #category : 'accessing' }
GameAnalysis >> moveCount [
	"Number of half-moves analysed"

	^ plies size - 1
]

{ #category : 'accessing' }
GameAnalysis >> multiPV [
	"How many engine lines were asked per position (analyses saved before this was recorded used 3)"

	^ multiPV ifNil: [ 3 ]
]

{ #category : 'accessing' }
GameAnalysis >> multiPV: anInteger [

	multiPV := anInteger
]

{ #category : 'initialization' }
GameAnalysis >> setDepth: aNumber plies: aCollection [

	depth := aNumber.
	plies := aCollection asArray
]
