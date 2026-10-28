"
Represents a single move in a chess game. Stores both SAN (Standard Algebraic Notation) and UCI formats, along with metadata like move number and time taken.
"
Class {
	#name : 'ChessMove',
	#superclass : 'Object',
	#instVars : [
		'moveNumber',
		'color',
		'san',
		'timestamp',
		'uci',
		'comment',
		'nags'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'accessing' }
ChessMove >> addComment: aString [
	"PGN allows several comments after a move; keep them in order"

	aString ifEmpty: [ ^ self ].
	comment := comment
		           ifNil: [ aString ]
		           ifNotNil: [ comment , ' ' , aString ]
]

{ #category : 'accessing' }
ChessMove >> addNag: anInteger [

	nags := self nags copyWith: anInteger
]

{ #category : 'accessing' }
ChessMove >> color [

	^ color
]

{ #category : 'accessing' }
ChessMove >> comment [
	"The move's PGN comment without [%...] commands, or nil"

	^ comment
]

{ #category : 'accessing' }
ChessMove >> moveNumber [

	^ moveNumber
]

{ #category : 'initialization' }
ChessMove >> moveNumber: aNumber color: aColor san: aSAN [

	moveNumber := aNumber.
	color := aColor.
	san := aSAN.
	timestamp := nil.
	^ self
]

{ #category : 'initialization' }
ChessMove >> moveNumber: aNumber color: aColor san: aSAN timestamp: aDuration [

	moveNumber := aNumber.
	color := aColor.
	san := aSAN.
	timestamp := aDuration.
	^ self
]

{ #category : 'accessing' }
ChessMove >> nags [
	"Numeric annotation glyphs: 1 !, 2 ?, 3 !!, 4 ??, 5 !?, 6 ?!, and any $n"

	^ nags ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
ChessMove >> san [

	^ san
]

{ #category : 'accessing' }
ChessMove >> timestamp [
	"The mover's remaining clock after the move ([%clk] in the PGN), as a Duration; nil when the PGN has none"

	^ timestamp
]

{ #category : 'accessing' }
ChessMove >> timestamp: aDuration [

	timestamp := aDuration
]

{ #category : 'accessing' }
ChessMove >> uci [
	"The move in UCI notation, filled in by Game>>uciMoves; nil until then"

	^ uci
]

{ #category : 'accessing' }
ChessMove >> uci: aString [

	uci := aString
]
