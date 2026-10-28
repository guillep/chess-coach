Class {
	#name : 'GameTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
GameTest >> testInitialPositionFromFENHeader [

	| game |
	game := PGNParser new parse: '[SetUp "1"]
[FEN "8/P7/8/8/8/8/8/k6K w - - 0 1"]

1. a8=Q'.
	self
		assert: game initialPosition fen
		equals: '8/P7/8/8/8/8/8/k6K w - - 0 1'.
	self
		assert: (game positionAfterPly: 1) fen
		equals: 'Q7/8/8/8/8/8/8/k6K b - - 0 1'
]

{ #category : 'tests' }
GameTest >> testPositionAfterPly [

	| game |
	game := PGNParser new parse: '1. e4 e5 2. Nf3'.
	self
		assert: (game positionAfterPly: 2) fen
		equals:
		'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2'.
	self
		assert: (game positionAfterPly: 3) fen
		equals:
		'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2'
]

{ #category : 'tests' }
GameTest >> testPositionAfterPlyZeroIsInitialPosition [

	| game |
	game := PGNParser new parse: '1. e4 e5 2. Nf3'.
	self
		assert: (game positionAfterPly: 0) fen
		equals: ChessPosition initial fen
]
