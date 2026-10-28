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
GameTest >> testLegalUCIMoves [

	| position |
	position := ChessPosition initial.
	self assert: (position isLegalUCI: 'e2e4').
	self assert: (position isLegalUCI: 'g1f3').
	self deny: (position isLegalUCI: 'e2e5').
	self deny: (position isLegalUCI: 'e7e5').
	self deny: (position isLegalUCI: 'e1g1').
	position := position moves: #( 'e4' 'e5' 'Nf3' 'Nc6' 'Bc4' 'Nf6' ).
	self assert: (position isLegalUCI: 'e1g1').
	self deny: (position isLegalUCI: 'e1c1')
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

{ #category : 'tests' }
GameTest >> testUCIMoves [

	| game |
	game := PGNParser new parse:
		        '1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. O-O Nxe4 5. d4 exd4'.
	self
		assert: game uciMoves asArray
		equals:
			#( 'e2e4' 'e7e5' 'g1f3' 'b8c6' 'f1c4' 'g8f6' 'e1g1' 'f6e4' 'd2d4'
			   'e5d4' ).
	self assert: game moves first uci equals: 'e2e4'
]
