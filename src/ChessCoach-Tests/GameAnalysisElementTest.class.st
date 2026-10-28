Class {
	#name : 'GameAnalysisElementTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
GameAnalysisElementTest >> testArrowKeysStepThroughPositions [

	| analysis scripter |
	analysis := GameAnalysisElement fromPGN: '1. e4 e5 2. Nf3'.
	scripter := BlDevScripter new.
	scripter element: analysis.
	scripter requestFocus onChildFromBlock: [ :element |
		analysis moveList ].
	scripter keyClick: KeyboardKey right.
	scripter syncPlay.
	self
		assert: analysis chessPosition fen
		equals:
		'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'
]

{ #category : 'tests' }
GameAnalysisElementTest >> testArrowKeysWorkWithoutClickingFirst [

	| analysis scripter |
	analysis := GameAnalysisElement fromPGN: '1. e4 e5 2. Nf3'.
	scripter := BlDevScripter new.
	scripter element: analysis.
	scripter keyClick: KeyboardKey right.
	scripter syncPlay.
	self
		assert: analysis chessPosition fen
		equals:
		'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'
]

{ #category : 'tests' }
GameAnalysisElementTest >> testBoardStaysSquareAndListIsFixedWidth [

	| analysis |
	analysis := GameAnalysisElement fromPGN: '1. e4 e5'.
	analysis extent: 900 @ 600.
	analysis forceLayout.
	self assert: analysis boardElement extent equals: 600 @ 600.
	self assert: analysis moveList width equals: 200
]

{ #category : 'tests' }
GameAnalysisElementTest >> testFromPGNShowsInitialPosition [

	| analysis |
	analysis := GameAnalysisElement fromPGN: '1. e4 e5 2. Nf3'.
	self
		assert: analysis chessPosition fen
		equals: ChessPosition initial fen
]

{ #category : 'tests' }
GameAnalysisElementTest >> testLongMoveListScrollsInsteadOfGrowing [

	| analysis |
	analysis := GameAnalysisElement fromPGN: (String
			             new: 0
			             streamContents: [ :s |
			             30 timesRepeat: [ s nextPutAll: 'Nf3 Nf6 Ng1 Ng8 ' ] ]).
	analysis extent: 900 @ 300.
	analysis forceLayout.
	self assert: analysis moveList height > 300.
	self assert: analysis moveList parent height equals: 300
]

{ #category : 'tests' }
GameAnalysisElementTest >> testNewGameResetsToPlyZero [

	| analysis |
	analysis := GameAnalysisElement fromPGN: '1. e4 e5'.
	analysis selectPly: 2.
	analysis game: (PGNParser new parse: '1. d4').
	self
		assert: analysis chessPosition fen
		equals: ChessPosition initial fen
]

{ #category : 'tests' }
GameAnalysisElementTest >> testOperaGameLastPly [

	| analysis |
	analysis := GameAnalysisElement fromPGN:
		            '1. e4 e5 2. Nf3 d6 3. d4 Bg4 4. dxe5 Bxf3 5. Qxf3 dxe5 6. Bc4 Nf6 7. Qb3 Qe7
8. Nc3 c6 9. Bg5 b5 10. Nxb5 cxb5 11. Bxb5+ Nbd7 12. O-O-O Rd8 13. Rxd7 Rxd7
14. Rd1 Qe6 15. Bxd7+ Nxd7 16. Qb8+ Nxb8 17. Rd8# 1-0'.
	analysis selectPly: 33.
	self
		assert: analysis chessPosition fen
		equals: '1n1Rkb1r/p4ppp/4q3/4p1B1/4P3/8/PPP2PPP/2K5 b k - 1 17'
]

{ #category : 'tests' }
GameAnalysisElementTest >> testSelectingAMoveShowsThePositionAfterIt [

	| analysis |
	analysis := GameAnalysisElement fromPGN: '1. e4 e5 2. Nf3'.
	analysis selectPly: 3.
	self
		assert: analysis chessPosition fen
		equals:
		'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2'.
	analysis selectPly: 1.
	self
		assert: analysis chessPosition fen
		equals:
		'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'
]
