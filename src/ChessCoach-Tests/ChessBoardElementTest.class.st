Class {
	#name : 'ChessBoardElementTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
ChessBoardElementTest >> testSetStateProgrammatically [

	| board |
	board := ChessBoardElement new.
	board state: (Dictionary new
			 at: 'e4' put: 'P';
			 yourself).
	self assert: board notNil.
	self assert: board pieceElements size equals: 1
]
