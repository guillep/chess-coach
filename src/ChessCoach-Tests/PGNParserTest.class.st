Class {
	#name : 'PGNParserTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
PGNParserTest >> testArbitraryStartMoveNumber [

	| p game moves |
	p := '[Event "Test"]

15... e5 15. d4'.
	game := PGNParser new parse: p.
	moves := game moves.
	self assert: moves size equals: 2.
	self assert: moves first color equals: 'b'.
	self assert: moves first moveNumber equals: 15.
	self assert: moves second color equals: 'w'.
	self assert: moves second moveNumber equals: 15
]

{ #category : 'tests' }
PGNParserTest >> testBlankLinesBetweenMoveLines [

	| game |
	game := PGNParser new parse: '[Event "Test"]

1. e4

1... e5'.
	self
		assert: (game moves collect: [ :m | m san ]) asArray
		equals: #( 'e4' 'e5' )
]

{ #category : 'tests' }
PGNParserTest >> testChessMoveFields [

	| game move |
	game := PGNParser new parse: '1. e4'.
	move := game moves first.
	self assert: move san equals: 'e4'.
	self assert: move uci equals: 'e4'.
	self assert: move color equals: 'w'.
	self assert: move moveNumber equals: 1.
	self assert: move timestamp isNil
]

{ #category : 'tests' }
PGNParserTest >> testCompleteGame [

	| p game moves |
	p := '[Event "Casual Game"]
[Site "Paris FRA"]
[Date "1858.??.??"]
[White "Morphy, Paul"]
[Black "Duke Karl / Count Isouard"]
[Result "1-0"]

1. e4 e5 2. Nf3 d6 3. d4 Bg4 4. dxe5 Bxf3 5. Qxf3 dxe5
6. Bc4 Nf6 7. Qb3 Qe7 8. Nc3 c6 9. Bg5 b5 10. Nxb5 cxb5
11. Bxb5+ Nbd7 12. O-O-O Rd8 13. Rxd7 Rxd7 14. Rd1 Qe6
15. Bxd7+ Nxd7 16. Qb8+ Nxb8 17. Rd8# 1-0'.
	game := PGNParser new parse: p.
	moves := game moves.
	self assert: (game metadata at: 'White') equals: 'Morphy, Paul'.
	self assert: (game metadata at: 'Result') equals: '1-0'.
	self assert: moves size equals: 33.
	self assert: moves first san equals: 'e4'.
	self assert: moves last san equals: 'Rd8#'.
	self assert: moves last color equals: 'w'.
	self assert: moves last moveNumber equals: 17.
	self assert: (moves count: [ :m | m san = 'O-O-O' ]) equals: 1
]

{ #category : 'tests' }
PGNParserTest >> testHeaders [

	| p game |
	p := '[Event "F/S Return Match"]
[Site "Belgrade, Serbia JUG"]
[Date "1992.11.04"]
[Round "29"]
[White "Fischer, Robert J."]
[Black "Spassky, Boris V."]
[Result "1/2-1/2"]

1. e4 e5'.
	game := PGNParser new parse: p.
	self assert: (game metadata at: 'Event') equals: 'F/S Return Match'.
	self assert: (game metadata at: 'White') equals: 'Fischer, Robert J.'.
	self assert: (game metadata at: 'Result') equals: '1/2-1/2'.
	self assert: game moves size equals: 2
]

{ #category : 'tests' }
PGNParserTest >> testIgnoreCommentsVariationsNags [

	| p game moves |
	p := '[Event "Test"]

1. e4 {good} (1... c5 2. Nf3) e5 $1 1-0'.
	game := PGNParser new parse: p.
	moves := game moves.
	self assert: moves size equals: 2.
	self assert: moves first san equals: 'e4'.
	self assert: moves second san equals: 'e5'.
	self assert: (game metadata at: 'Result') equals: '1-0'
]

{ #category : 'tests' }
PGNParserTest >> testIgnoreMultilineCommentsAndNestedVariations [

	| game moves |
	game := PGNParser new parse: '[Event "Test"]

1. e4 {a comment
spanning lines} e5 (1... c5 (2. Nf3)) 2. Nf3 $2 Nc6'.
	moves := game moves.
	self
		assert: (moves collect: [ :m | m san ]) asArray
		equals: #( 'e4' 'e5' 'Nf3' 'Nc6' )
]

{ #category : 'tests' }
PGNParserTest >> testMoveNumberOnSeparateToken [

	| p game moves |
	p := '[Event "Test"]

1. e4 e5 2. Nf3'.
	game := PGNParser new parse: p.
	moves := game moves.
	self assert: moves size equals: 3.
	self assert: moves third san equals: 'Nf3'.
	self assert: moves third color equals: 'w'.
	self assert: moves third moveNumber equals: 2
]

{ #category : 'tests' }
PGNParserTest >> testMovePair [

	| p game moves |
	p := '[Event "Test"]

1. e4 e5'.
	game := PGNParser new parse: p.
	moves := game moves.
	self assert: moves size equals: 2.
	self assert: moves first san equals: 'e4'.
	self assert: moves first color equals: 'w'.
	self assert: moves first moveNumber equals: 1.
	self assert: moves second san equals: 'e5'.
	self assert: moves second color equals: 'b'.
	self assert: moves second moveNumber equals: 1
]

{ #category : 'tests' }
PGNParserTest >> testMultiLineMoves [

	| game moves |
	game := PGNParser new parse: '[Event "Test"]

1. e4 e5
2. Nf3 Nc6
3. Bb5'.
	moves := game moves.
	self assert: moves size equals: 5.
	self
		assert: (moves collect: [ :m | m san ]) asArray
		equals: #( 'e4' 'e5' 'Nf3' 'Nc6' 'Bb5' ).
	self assert: moves third color equals: 'w'.
	self assert: moves third moveNumber equals: 2.
	self assert: moves fourth color equals: 'b'.
	self assert: moves fourth moveNumber equals: 2
]

{ #category : 'tests' }
PGNParserTest >> testPGNGameStructure [

	| game |
	game := PGNParser new parse: '[Event "Test"]

1. e4'.
	self assert: (game isKindOf: PGNGame).
	self assert: (game metadata isKindOf: Dictionary).
	self assert: (game metadata at: 'Event') equals: 'Test'.
	self assert: (game moves isKindOf: OrderedCollection)
]

{ #category : 'tests' }
PGNParserTest >> testParseFromStream [

	| p stream game |
	p := '[Event "Test"]

1. e4 e5'.
	stream := ReadStream on: p.
	game := PGNParser new parse: stream.
	self assert: game moves size equals: 2
]

{ #category : 'tests' }
PGNParserTest >> testResultTokenWithoutHeaders [

	| game |
	game := PGNParser new parse: '1. e4 e5 1-0'.
	self assert: (game metadata at: 'Result') equals: '1-0'.
	self assert: game moves size equals: 2
]

{ #category : 'tests' }
PGNParserTest >> testSingleMove [

	| p game |
	p := '[Event "Test"]

1. e4'.
	game := PGNParser new parse: p.
	self
		assert: (game moves collect: [ :m | m san ]) asArray
		equals: #( 'e4' ).
	self assert: game moves first moveNumber equals: 1.
	self assert: game moves first color equals: 'w'
]
