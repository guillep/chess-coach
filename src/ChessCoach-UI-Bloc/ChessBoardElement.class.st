"
Custom Bloc element that renders an 8x8 chess board with pieces. Handles mouse clicks for piece selection and move input, and highlights legal moves.
"
Class {
	#name : 'ChessBoardElement',
	#superclass : 'Object',
	#instVars : [
		'board',
		'selectedSquare',
		'highlightedSquares'
	],
	#category : 'ChessCoach-UI-Bloc',
	#package : 'ChessCoach-UI-Bloc'
}

{ #category : 'accessing' }
ChessBoardElement >> board [

	^ board
]

{ #category : 'accessing' }
ChessBoardElement >> board: aChessBoard [

	board := aChessBoard.
	^ self
]

{ #category : 'rendering' }
ChessBoardElement >> displayBoard [
	"Render the chess board (8x8 grid with pieces). TODO: Implement rendering with Bloc"

	^ self
]

{ #category : 'action' }
ChessBoardElement >> highlightSquares: squareList [

	highlightedSquares := squareList
]

{ #category : 'initialization' }
ChessBoardElement >> initialize [

	super initialize.
	board := nil.
	selectedSquare := nil.
	highlightedSquares := #(  ).
	^ self
]

{ #category : 'initialization' }
ChessBoardElement >> initializeWithBoard: aChessBoard [

	board := aChessBoard.
	selectedSquare := nil.
	highlightedSquares := #(  )
]

{ #category : 'action' }
ChessBoardElement >> selectSquare: squareCoordinates [

	selectedSquare := squareCoordinates
]
