Class {
	#name : 'AnalysisBoardElementTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
AnalysisBoardElementTest >> testMovesBackAndEngine [

	| session engine analysisBoard |
	session := (LichessAPIClientStub withGames: 0) newSessionOn:
		           FileSystem memory root.
	engine := StockfishEngineStub new.
	engine
		at: ChessPosition initial fen whiteCentipawns: #( 30 20 );
		at: (ChessPosition initial move: 'e4') fen whiteCentipawns: #( 25 ).
	session analyser: (GameAnalyser engine: engine).
	analysisBoard := AnalysisBoardElement
		                 session: session
		                 position: ChessPosition initial
		                 runner: [ :aBlock | aBlock value ].
	self assert: session analysisQueue isPaused.
	self assert: analysisBoard board arrows size equals: 1.
	analysisBoard play: 'e2e5'.
	self assert: analysisBoard message equals: 'Illegal move'.
	analysisBoard play: 'e2e4'.
	self assert: analysisBoard message isNil.
	self assert: (analysisBoard chessPosition pieceAt: 'e4') equals: 'P'.
	self assert: analysisBoard movesText equals: 'Moves: e4'.
	analysisBoard play: 'e7e5'.
	self assert: analysisBoard movesText equals: 'Moves: e4 e5'.
	analysisBoard back.
	analysisBoard back.
	analysisBoard back.
	self
		assert: analysisBoard chessPosition fen
		equals: ChessPosition initial fen.
	analysisBoard close.
	self deny: session analysisQueue isPaused
]
