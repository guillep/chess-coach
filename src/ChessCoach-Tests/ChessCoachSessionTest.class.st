Class {
	#name : 'ChessCoachSessionTest',
	#superclass : 'TestCase',
	#instVars : [
		'root',
		'api',
		'session'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
ChessCoachSessionTest >> newSession [

	^ api newSessionOn: root
]

{ #category : 'running' }
ChessCoachSessionTest >> setUp [

	super setUp.
	root := FileSystem memory root.
	api := LichessAPIClientStub withGames: 25.
	session := self newSession
]

{ #category : 'tests' }
ChessCoachSessionTest >> testChangesAreAnnounced [

	| count |
	count := 0.
	session announcer
		when: ChessCoachSessionChanged
		do: [ :announcement | count := count + 1 ]
		for: self.
	session login.
	session loadMoreGames.
	session refresh.
	session logout.
	self assert: count equals: 4
]

{ #category : 'tests' }
ChessCoachSessionTest >> testGameForParsesStoredPGN [

	| game |
	session login.
	session loadMoreGames.
	game := session gameFor: session games first.
	self assert: (game metadata at: 'White') equals: 'alice'.
	self assert: game moves size equals: 2
]

{ #category : 'tests' }
ChessCoachSessionTest >> testGamesSurviveRestart [

	| entry |
	session login.
	session loadMoreGames.
	entry := self newSession games first.
	self assert: entry gameId equals: 'g25'.
	self
		assert: entry players asArray
		equals: #( 'alice' 'Stockfish level 3' ).
	self assert: entry result equals: '1-0'.
	self assert: entry createdAt equals: 25000
]

{ #category : 'tests' }
ChessCoachSessionTest >> testLichessErrorReachesCaller [

	session login.
	api error: (LichessError new messageText: 'rate limited').
	self should: [ session loadMoreGames ] raise: LichessError.
	self assert: session games isEmpty
]

{ #category : 'tests' }
ChessCoachSessionTest >> testLoadMoreGamesPagesBackwards [

	session login.
	session loadMoreGames.
	self assert: session games size equals: 20.
	self assert: session games first gameId equals: 'g25'.
	self assert: session games last gameId equals: 'g06'.
	session loadMoreGames.
	self assert: session games size equals: 25.
	self assert: session games last gameId equals: 'g01'.
	self assert: (root / 'games' / 'g01.pgn') exists
]

{ #category : 'tests' }
ChessCoachSessionTest >> testLoginRecordsUsernameInTokenFile [

	self assert: session username isNil.
	session login.
	self assert: session username equals: 'tester'.
	self assert: self newSession username equals: 'tester'.
	session logout.
	self assert: session username isNil
]

{ #category : 'tests' }
ChessCoachSessionTest >> testLoginWritesTokenFile [

	self assert: session login.
	self assert: session isLoggedIn.
	self assert: (root / 'lichess-token') exists.
	self assert: self newSession isLoggedIn
]

{ #category : 'tests' }
ChessCoachSessionTest >> testLogoutDeletesTokenAndKeepsGames [

	session login.
	session loadMoreGames.
	session logout.
	self deny: session isLoggedIn.
	self deny: (root / 'lichess-token') exists.
	self assert: session games size equals: 20
]

{ #category : 'tests' }
ChessCoachSessionTest >> testMomentsCombineEngineFindingsAndMarks [

	| entry game engine moments |
	session login.
	session loadMoreGames.
	entry := session games first.
	game := session gameFor: entry.
	engine := StockfishEngineStub new.
	engine at: (game positionAfterPly: 0) fen whiteCentipawns: #( 50 ).
	engine at: (game positionAfterPly: 1) fen whiteCentipawns: #( -400 ).
	engine at: (game positionAfterPly: 2) fen whiteCentipawns: #( -400 ).
	session analyser: (GameAnalyser engine: engine).
	session explorer: LichessExplorerClientStub new.
	session mark: entry ply: 2 note: 'my idea'.
	session mark: entry ply: 1 note: 'felt wrong'.
	moments := session momentsFor: entry.
	self
		assert: (moments collect: [ :each | each ply ]) asArray
		equals: #( 1 2 ).
	self assert: (moments first kinds includesAll: #( #blunder #marked )).
	self assert: (moments first notes includes: 'felt wrong').
	self assert: moments second isMarked.
	self assert: engine analysedCount equals: 3.
	session momentsFor: entry.
	self assert: engine analysedCount equals: 3
]

{ #category : 'tests' }
ChessCoachSessionTest >> testMyColorsComeFromMyUsername [

	session login.
	self
		assert: (session myColorsIn: (PGNParser new parse: '[White "alice"]
[Black "Tester"]

1. e4'))
		equals: #( #black ).
	self
		assert: (session myColorsIn: (PGNParser new parse: '[White "alice"]
[Black "bob"]

1. e4'))
		equals: #( #white #black )
]

{ #category : 'tests' }
ChessCoachSessionTest >> testRefreshFetchesEveryNewerGameWithoutGaps [

	session login.
	session settings at: 'gamesPerLoad' put: 10.
	session loadMoreGames.
	26 to: 50 do: [ :number |
		api addNewestGame: (LichessAPIClientStub gameNumber: number) ].
	session refresh.
	self assert: session games size equals: 35.
	self assert: session games first gameId equals: 'g50'.
	self assert:
		(session games anySatisfy: [ :each | each gameId = 'g26' ])
]

{ #category : 'tests' }
ChessCoachSessionTest >> testRefreshFetchesNewerGames [

	session login.
	session loadMoreGames.
	api addNewestGame: (LichessAPIClientStub gameNumber: 26).
	session refresh.
	self assert: session games size equals: 21.
	self assert: session games first gameId equals: 'g26'
]

{ #category : 'tests' }
ChessCoachSessionTest >> testReviewIsSavedAndFeedsTheMistakeDatabase [

	| entry game engine review database restored |
	session login.
	session loadMoreGames.
	entry := session games first.
	game := session gameFor: entry.
	engine := StockfishEngineStub new.
	engine at: (game positionAfterPly: 0) fen whiteCentipawns: #( 50 ).
	engine at: (game positionAfterPly: 1) fen whiteCentipawns: #( -400 ).
	session analyser: (GameAnalyser engine: engine).
	session explorer: LichessExplorerClientStub new.
	session classifier: (AnswerClassifier
			 client: (OllamaClientStub new replyContent:
					  '{"tags":[{"tag":"no-blunder-check","confidence":0.8}]}')
			 taxonomy: MistakeTaxonomy default).
	session mark: entry ply: 1 note: 'felt wrong'.
	review := session reviewFor: entry.
	self assert: review currentMoment ply equals: 1.
	review answerMoves: #(  ).
	review answerText: 'It looked natural'.
	review answerMoves: { game uciMoves second }.
	[ review currentMoment isRevealed ] whileFalse: [
		review answerText: 'I moved too fast' ].
	self assert: (session reviewFor: entry) currentMoment isRevealed.
	review classifyPending.
	review confirmTag: 'no-blunder-check' of: review currentMoment.
	review nextMoment.
	database := session mistakeDatabase.
	self assert: database records size equals: 1.
	self
		assert: (database tagFrequencies at: 'no-blunder-check')
		equals: 1.
	restored := session reviewFor: entry.
	self assert: restored reviews first labels first isConfirmed.
	self deny: restored currentMoment ply = 1
]

{ #category : 'tests' }
ChessCoachSessionTest >> testStartsLoggedOutWithNoGames [

	self deny: session isLoggedIn.
	self assert: session games isEmpty
]

{ #category : 'tests' }
ChessCoachSessionTest >> testUnmarkRemovesAMark [

	| entry |
	session login.
	session loadMoreGames.
	entry := session games first.
	session mark: entry ply: 2 note: ''.
	session mark: entry ply: 1 note: 'x'.
	session unmark: entry ply: 2.
	self
		assert:
			((session marksFor: entry) collect: [ :each | each at: 'ply' ])
				asArray
		equals: #( 1 )
]
