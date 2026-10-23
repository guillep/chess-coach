"
Represents a complete chess game with PGN, metadata (players, result, date, etc.), parsed moves, and current board state.
"
Class {
	#name : 'ChessGame',
	#superclass : 'Object',
	#instVars : [
		'gameId',
		'pgn',
		'metadata',
		'moves',
		'board'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'accessing' }
ChessGame >> board [

	^ board
]

{ #category : 'accessing' }
ChessGame >> gameId [

	^ gameId
]

{ #category : 'initialization' }
ChessGame >> gameId: aString pgn: aPGN metadata: aDict moves: aMoveList board: aBoard [

	gameId := aString.
	pgn := aPGN.
	metadata := aDict.
	moves := aMoveList.
	board := aBoard
]

{ #category : 'accessing' }
ChessGame >> metadata [

	^ metadata
]

{ #category : 'accessing' }
ChessGame >> moves [

	^ moves
]

{ #category : 'accessing' }
ChessGame >> pgn [

	^ pgn
]
