Class {
	#name : 'ChessBoardElementTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
ChessBoardElementTest >> testAnArrowFollowsADrag [

	| board scripter |
	board := ChessBoardElement new.
	scripter := BlDevScripter new.
	scripter element: board.
	scripter space extent: 400 @ 400.
	scripter pulse.
	board pressedOn: 'e2'.
	board enteredOn: 'e4'.
	self assert: board arrowLayer childrenCount equals: 1.
	board cancelDrag.
	self assert: board arrowLayer childrenCount equals: 0
]

{ #category : 'tests' }
ChessBoardElementTest >> testCoordinatesAreLightOnDarkSquares [

	| board squares |
	board := ChessBoardElement new.
	squares := board instVarNamed: 'squares'.
	self assert: (board coordinateColorOn: squares first) equals: (Color black alpha: 0.6).
	self assert: (board coordinateColorOn: squares second) equals: (Color white alpha: 0.8)
]

{ #category : 'tests' }
ChessBoardElementTest >> testMoveListTakesGameAndAnnounces [

	| list selectedPly |
	list := MoveListElement new.
	list game: (PGNParser new parse: '1. e4 e5').
	selectedPly := nil.
	list whenMoveSelectedDo: [ :ply | selectedPly := ply ].
	list selectMoveAt: 1.
	self assert: selectedPly equals: 1.
	self assert: list layoutMode equals: #rigid
]

{ #category : 'tests' }
ChessBoardElementTest >> testPieceMatchesSquareExtent [

	| board piece |
	board := ChessBoardElement new.
	board extent: 600 @ 600.
	board chessPosition:
		(ChessPosition fromFEN: '8/8/8/8/4P3/8/8/8 w - - 0 1').
	board forceLayout.
	piece := board pieceElements at: 'e4'.
	self assert: piece extent equals: piece parent extent.
	self assert: piece extent equals: 75 @ 75.
	self assert: piece background image extent equals: 75 @ 75
]

{ #category : 'tests' }
ChessBoardElementTest >> testPositionShowsAllPieces [

	| board |
	board := ChessBoardElement new.
	board chessPosition: ChessPosition initial.
	self assert: board pieceElements size equals: 32.
	board chessPosition: (ChessPosition initial move: 'e4').
	self assert: board pieceElements size equals: 32.
	self assert: (board pieceElements includesKey: 'e4').
	self deny: (board pieceElements includesKey: 'e2')
]

{ #category : 'tests' }
ChessBoardElementTest >> testSetLiviusPieceSetProgrammatically [

	| board |
	board := ChessBoardElement new.
	board pieceSet: LiviusPieceSet new.
	board chessPosition:
		(ChessPosition fromFEN: '8/8/8/8/4P3/8/8/8 w - - 0 1').
	self assert: board pieceSet notNil.
	self assert: board pieceElements size equals: 1
]

{ #category : 'tests' }
ChessBoardElementTest >> testSetPieceSetProgrammatically [

	| board |
	board := ChessBoardElement new.
	board pieceSet: MadwareChessPieceSet new.
	board chessPosition:
		(ChessPosition fromFEN: '8/8/8/8/4P3/8/8/8 w - - 0 1').
	self assert: board pieceSet notNil.
	self assert: board pieceElements size equals: 1
]

{ #category : 'tests' }
ChessBoardElementTest >> testSetStateProgrammatically [

	| board |
	board := ChessBoardElement new.
	board pieceSet: MadwareChessPieceSet new.
	board chessPosition:
		(ChessPosition fromFEN: '8/8/8/8/4P3/8/8/8 w - - 0 1').
	self assert: board pieceElements size equals: 1
]

{ #category : 'tests' }
ChessBoardElementTest >> testTheme [

	| board |
	board := ChessBoardElement new.
	self assert: board theme equals: 'Brown'.
	board theme: 'Green'.
	self assert: board theme equals: 'Green'.
	"The squares are the first children, from a8; the 57th is a1, a dark square"
	self
		assert: (board children at: 57) background paint color
		equals: (Color fromHexString: '#769656').
	self
		assert: (board children at: 64) background paint color
		equals: (Color fromHexString: '#eeeed2').
	board theme: 'Unknown'.
	self assert: board theme equals: 'Brown'
]
