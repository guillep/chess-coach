Class {
	#name : 'ChessBoardElementTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
ChessBoardElementTest >> testSetPieceSetProgrammatically [

	| board set state |
	set := MadwareChessPieceSet new.
	board := ChessBoardElement new.
	board pieceSet: set.
	state := Dictionary new.
	state at: 'e4' put: 'P'.
	board state: state.
	self assert: board pieceSet notNil.
	self assert: board pieceElements size equals: 1
]

{ #category : 'tests' }
ChessBoardElementTest >> testSetStateProgrammatically [

	| board |
	board := ChessBoardElement new.
	board pieceSet: MadwareChessPieceSet new.
	board state: (Dictionary new
			 at: 'e4' put: 'P';
			 yourself).
	self assert: board notNil.
	self assert: board pieceElements size equals: 1
]
