"
I am the engine analysis of the position after ply half-moves (ply 0 is the initial position): its FEN and the engine's best lines, best first.
"
Class {
	#name : 'PlyAnalysis',
	#superclass : 'Object',
	#instVars : [
		'ply',
		'fen',
		'lines'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
PlyAnalysis class >> fromDictionary: aDictionary [

	^ self
		  ply: (aDictionary at: 'ply')
		  fen: (aDictionary at: 'fen')
		  lines: ((aDictionary at: 'lines') collect: [ :each |
				   EngineLine fromDictionary: each ])
]

{ #category : 'instance creation' }
PlyAnalysis class >> ply: aNumber fen: aFEN lines: aCollection [

	^ self new setPly: aNumber fen: aFEN lines: aCollection
]

{ #category : 'converting' }
PlyAnalysis >> asDictionary [

	^ Dictionary new
		  at: 'ply' put: ply;
		  at: 'fen' put: fen;
		  at: 'lines' put: (lines collect: [ :each | each asDictionary ]);
		  yourself
]

{ #category : 'accessing' }
PlyAnalysis >> bestLine [

	^ lines first
]

{ #category : 'accessing' }
PlyAnalysis >> fen [

	^ fen
]

{ #category : 'accessing' }
PlyAnalysis >> lines [
	"Engine lines, best first"

	^ lines
]

{ #category : 'accessing' }
PlyAnalysis >> ply [

	^ ply
]

{ #category : 'accessing' }
PlyAnalysis >> sanOf: aUCIMove [
	"aUCIMove, legal in this position, in SAN"

	^ (ChessPosition fromFEN: fen) sanForUCI: aUCIMove
]

{ #category : 'initialization' }
PlyAnalysis >> setPly: aNumber fen: aFEN lines: aCollection [

	ply := aNumber.
	fen := aFEN.
	lines := aCollection asArray
]

{ #category : 'accessing' }
PlyAnalysis >> sideToMove [

	^ (fen substrings at: 2) = 'w'
		  ifTrue: [ #white ]
		  ifFalse: [ #black ]
]

{ #category : 'accessing' }
PlyAnalysis >> winPercentFor: aColor [
	"aColor's winning chance with best play from here"

	^ self bestLine winPercentFor: aColor
]
