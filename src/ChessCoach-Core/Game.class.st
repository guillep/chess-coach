Class {
	#name : 'Game',
	#superclass : 'Object',
	#instVars : [
		'metadata',
		'moves'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'positions' }
Game >> initialPosition [
	"Honour the PGN FEN header for games that do not start from the standard position"

	^ metadata
		  at: 'FEN'
		  ifPresent: [ :fen | ChessPosition fromFEN: fen ]
		  ifAbsent: [ ChessPosition initial ]
]

{ #category : 'initialization' }
Game >> initialize [

	super initialize.
	metadata := Dictionary new.
	moves := OrderedCollection new
]

{ #category : 'accessing' }
Game >> metadata [

	^ metadata
]

{ #category : 'accessing' }
Game >> moves [

	^ moves
]

{ #category : 'positions' }
Game >> positionAfterPly: aNumber [
	"Ply 0 is the initial position; ply N is the position after the Nth half-move"

	^ self initialPosition moves:
		  ((moves first: aNumber) collect: [ :move | move san ])
]
