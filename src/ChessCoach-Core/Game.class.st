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

{ #category : 'time control' }
Game class >> speedForTimeControl: aString [
	"The speed of a PGN TimeControl, as Lichess counts it: estimated duration = base + 40 × increment.
	'-' (Lichess) and 'moves/seconds' such as '1/259200' (Chess.com daily) are correspondence."

	| parts estimate |
	(aString isEmptyOrNil or: [
		 aString = '-' or: [ aString includes: $/ ] ]) ifTrue: [
		^ 'correspondence' ].
	parts := aString substrings: '+'.
	estimate := parts first asInteger + (40 * (parts size > 1
		              ifTrue: [ parts second asInteger ]
		              ifFalse: [ 0 ])).
	estimate < 30 ifTrue: [ ^ 'ultraBullet' ].
	estimate < 180 ifTrue: [ ^ 'bullet' ].
	estimate < 480 ifTrue: [ ^ 'blitz' ].
	estimate < 1500 ifTrue: [ ^ 'rapid' ].
	^ 'classical'
]

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

{ #category : 'accessing' }
Game >> speed [
	"ultraBullet, bullet, blitz, rapid, classical or correspondence, from the TimeControl header"

	^ self class speedForTimeControl:
		  (metadata at: 'TimeControl' ifAbsent: [ nil ])
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
