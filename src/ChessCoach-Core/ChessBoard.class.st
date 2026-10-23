"
Represents the current state of a chess board. Maintains position in Forsyth-Edwards Notation (FEN) and provides methods to play/unplay moves and compute legal moves.
"
Class {
	#name : 'ChessBoard',
	#superclass : 'Object',
	#instVars : [
		'fen',
		'position',
		'halfMoveClock',
		'fullMoveNumber'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'accessing' }
ChessBoard >> fen [

	^ fen
]

{ #category : 'initialization' }
ChessBoard >> initializeWithFEN: aFENString [

	fen := aFENString.
	"Initialize position array from FEN (8x8 board)"
	position := Array new: 8.
	halfMoveClock := 0.
	fullMoveNumber := 1
]

{ #category : 'accessing' }
ChessBoard >> position [

	^ position
]
