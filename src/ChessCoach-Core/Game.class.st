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

{ #category : 'positions' }
Game >> uciMoves [
	"The moves in UCI notation. The first call replays the game once and stores each move's UCI."

	(moves allSatisfy: [ :move | move uci notNil ]) ifFalse: [
			| position |
			position := self initialPosition.
			moves do: [ :move |
					position := position move: move san.
					move uci: position lastMoveUCI ] ].
	^ moves collect: [ :move | move uci ]
]
