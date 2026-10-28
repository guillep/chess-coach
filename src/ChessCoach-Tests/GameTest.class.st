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
GameTest >> testPGNCommentsClocksNagsAndVariations [

	| game moves |
	game := PGNParser new parse: '[Event "Rated blitz game"]
[TimeControl "180+2"]

1. e4 { [%eval 0.2] [%clk 0:03:00] } 1... e5 { [%clk 0:02:59.4] Solid. } 2. Nf3!? $14 Nc6 ; a classic
3. Bc4 (3. Bb5 a6 { Ruy Lopez } (3... Nf6) 4. Ba4) 3... Nf6?? { [%clk 0:02:30] Two knights } 4. Ng5 1-0'.
	moves := game moves.
	self
		assert: (moves collect: [ :each | each san ]) asArray
		equals: #( 'e4' 'e5' 'Nf3' 'Nc6' 'Bc4' 'Nf6' 'Ng5' ).
	self
		assert: (moves collect: [ :each | each color ]) asArray
		equals: #( 'w' 'b' 'w' 'b' 'w' 'b' 'w' ).
	self
		assert: (moves collect: [ :each | each moveNumber ]) asArray
		equals: #( 1 1 2 2 3 3 4 ).
	self assert: moves first timestamp equals: 3 minutes.
	self assert: moves first comment isNil.
	self
		assert: moves second timestamp
		equals: (Duration milliSeconds: 179400).
	self assert: moves second comment equals: 'Solid.'.
	self assert: moves third nags asArray equals: #( 5 14 ).
	self assert: (moves at: 4) comment equals: 'a classic'.
	self assert: (moves at: 6) nags asArray equals: #( 4 ).
	self assert: (moves at: 6) comment equals: 'Two knights'.
	self assert: (moves at: 7) timestamp isNil.
	self assert: (game metadata at: 'Result') equals: '1-0'.
	self assert: game uciMoves last equals: 'f3g5'
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
