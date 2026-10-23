Class {
	#name : 'MoveReplayControllerTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
MoveReplayControllerTest >> testMoveListFromBlackStart [

	| p game ctrl |
	p := '[Event "Test"]

15... e5 15. d4'.
	game := PGNParser new parse: p.
	ctrl := MoveReplayController new game: game.
	self assert: ctrl moveList equals: '15... e5 15. d4'
]

{ #category : 'tests' }
MoveReplayControllerTest >> testMoveListFromPGNGame [

	| p game ctrl |
	p := '[Event "Test"]

1. e4 e5 2. Nf3 Nc6'.
	game := PGNParser new parse: p.
	ctrl := MoveReplayController new game: game.
	self assert: ctrl moveList equals: '1. e4 e5 2. Nf3 Nc6'
]
