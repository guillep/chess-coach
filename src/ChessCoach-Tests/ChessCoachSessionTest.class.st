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
ChessCoachSessionTest >> testAFailingCheckIsNotifiedOncePerSite [

	session login.
	session loadMoreGames.
	api error: (LichessError new messageText: 'Lichess is down').
	session checkForNewGames.
	session checkForNewGames.
	self assert: session notifications visible size equals: 1.
	self assert: session notifications visible first kind equals: #error.
	self
		assert: session notifications visible first text
		equals: 'Lichess is down'
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
ChessCoachSessionTest >> testCheckingForNewGamesNotifiesThem [

	session login.
	session loadMoreGames.
	api addNewestGame: (LichessAPIClientStub gameNumber: 26).
	api addNewestGame: (LichessAPIClientStub gameNumber: 27).
	session checkForNewGames.
	self assert: session games first gameId equals: 'g27'.
	self assert: session notifications visible size equals: 1.
	self
		assert: session notifications visible first kind
		equals: #newGames.
	self
		assert: session notifications visible first title
		equals: '2 new games'.
	session checkForNewGames.
	self assert: session notifications visible size equals: 1
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
ChessCoachSessionTest >> testLichessUsernameIsEnoughToLoadGames [

	self deny: session canImport.
	self deny: (session validateLichessUsername: 'nobody').
	self assert: session username isNil.
	self assert: (session validateLichessUsername: 'alice').
	self deny: session isLoggedIn.
	self assert: session canImport.
	session loadMoreGames.
	self assert: session games size equals: 20.
	session lichessUsername: nil.
	self deny: session canImport.
	self assert: session games size equals: 20
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
	"Logging out keeps the username: it is enough to download games"

	self assert: session username isNil.
	session login.
	self assert: session username equals: 'tester'.
	self assert: self newSession username equals: 'tester'.
	session logout.
	self deny: session isLoggedIn.
	self assert: session username equals: 'tester'
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

	| entry game engine marks moments |
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
	marks := {
		         (Dictionary new
			          at: 'ply' put: 1;
			          at: 'note' put: 'felt wrong';
			          yourself).
		         (Dictionary new
			          at: 'ply' put: 2;
			          at: 'note' put: 'my idea';
			          yourself) }.
	moments := session momentsFor: entry marks: marks.
	self
		assert: (moments collect: [ :each | each ply ]) asArray
		equals: #( 1 2 ).
	self assert: (moments first kinds includesAll: #( #blunder #marked )).
	self assert: (moments first notes includes: 'felt wrong').
	self assert: moments second isMarked.
	self assert: engine analysedCount equals: 3.
	session momentsFor: entry marks: marks.
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
ChessCoachSessionTest >> testNDJSONBytesAreDecoded [

	| lines |
	lines := LichessAPIClientBytesStub new getJSONLines:
		         'https://lichess.org/api/games/user/x' asZnUrl.
	self
		assert: (lines collect: [ :each | each at: 'id' ]) asArray
		equals: #( 'a1' 'a2' ).
	self assert: (lines first at: 'name') equals: 'Gö'
]

{ #category : 'tests' }
ChessCoachSessionTest >> testOldReviewAndMarksBecomeReviewOne [

	| entry game engine games review |
	session login.
	session loadMoreGames.
	entry := session games first.
	game := session gameFor: entry.
	engine := StockfishEngineStub new.
	engine at: (game positionAfterPly: 0) fen whiteCentipawns: #( 50 ).
	engine at: (game positionAfterPly: 1) fen whiteCentipawns: #( -400 ).
	session analyser: (GameAnalyser engine: engine).
	session explorer: LichessExplorerClientStub new.
	games := root / 'games'.
	games / (entry gameId , '.marks.json') writeStreamDo: [ :stream |
		stream nextPutAll: '[{"ply":2,"note":"hmm"}]' ].
	games / (entry gameId , '.review.json') writeStreamDo: [ :stream |
			stream nextPutAll: '{"game":"' , entry gameId
				,
				'","current":1,"moments":[{"ply":1,"color":"white","kinds":["blunder"],"pending":[],"answers":[{"question":{"kind":"why","text":"Why?","move":null},"moves":[],"text":"fast","labels":[],"classified":true}],"candidates":{},"labels":[]}],"mistakes":[]}' ].
	review := (session reviewsFor: entry) first.
	self assert: (session reviewsFor: entry) size equals: 1.
	self assert: review number equals: 1.
	self deny: review isMarking.
	self
		assert: (review moments collect: [ :each | each ply ]) asArray
		equals: #( 1 2 ).
	self assert: review moments first isReviewed.
	self assert: review moments second isMarked.
	self deny: (games / (entry gameId , '.review.json')) exists.
	self deny: (games / (entry gameId , '.marks.json')) exists.
	self assert: (games / (entry gameId , '.review-1.json')) exists
]

{ #category : 'tests' }
ChessCoachSessionTest >> testOpeningHeuristicNeedsLichess [

	| entry game engine problems |
	session login.
	session loadMoreGames.
	entry := session games first.
	game := session gameFor: entry.
	engine := StockfishEngineStub new.
	session analyser: (GameAnalyser engine: engine).
	session logout.
	problems := OrderedCollection new.
	session momentsFor: entry marks: #(  ) problems: problems.
	self
		assert: problems asArray
		equals:
		#( 'Log in to Lichess to compare your opening moves with its database.' )
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

	| entry game engine review database restored second |
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
	review := session newReviewFor: entry.
	self assert: review number equals: 1.
	review mark: 1 note: 'felt wrong'.
	self assert: (session reviewsFor: entry) first isMarking.
	session finishMarking: review of: entry.
	review start: review moments first.
	self assert: review currentMoment ply equals: 1.
	review answerMoves: #(  ).
	review answerText: 'It looked natural'.
	review answerMoves: { game uciMoves second }.
	[ review currentMoment isRevealed ] whileFalse: [
		review answerText: 'I moved too fast' ].
	review classifyPending.
	review confirmTag: 'no-blunder-check' of: review currentMoment.
	review leaveMoment.
	database := session mistakeDatabase.
	self assert: database records size equals: 1.
	self
		assert: (database tagFrequencies at: 'no-blunder-check')
		equals: 1.
	restored := (session reviewsFor: entry) first.
	self deny: restored isMarking.
	self assert: restored moments first isReviewed.
	self assert: restored moments first labels first isConfirmed.
	self assert: restored marks size equals: 1.
	"A second review of the same moment replaces the first one in the database"
	second := session newReviewFor: entry.
	self assert: second number equals: 2.
	session finishMarking: second of: entry.
	second start: second moments first.
	second answerMoves: #(  ).
	second answerText: 'Again'.
	second answerMoves: { game uciMoves second }.
	[ second currentMoment isRevealed ] whileFalse: [
		second answerText: 'Same' ].
	second classifyPending.
	second leaveMoment.
	database := session mistakeDatabase.
	self assert: database records size equals: 1.
	self assert: database records first explanation equals: 'Again'.
	self
		assert:
		((session reviewsFor: entry) collect: [ :each | each number ])
			asArray
		equals: #( 1 2 )
]

{ #category : 'tests' }
ChessCoachSessionTest >> testShutDownStopsTheScheduledChecks [

	session startScheduledChecks.
	session shutDown.
	self deny: (Process allInstances anySatisfy: [ :each |
			 each name = 'Chess Coach scheduler' and: [ each isTerminated not ] ])
]

{ #category : 'tests' }
ChessCoachSessionTest >> testStartsLoggedOutWithNoGames [

	self deny: session isLoggedIn.
	self assert: session games isEmpty
]

{ #category : 'tests' }
ChessCoachSessionTest >> testTheGamesCheckIntervalIsASetting [

	session settings at: 'gamesCheckMinutes' put: 10.
	session startScheduledChecks.
	self
		assert: session scheduler intervals asArray
		equals: { 10 minutes }.
	session settings at: 'gamesCheckMinutes' put: 45.
	self
		assert: session scheduler intervals asArray
		equals: { 45 minutes }.
	self assert: session scheduler isRunning.
	session shutDown
]

{ #category : 'tests' }
ChessCoachSessionTest >> testWithoutStockfishMomentsComeFromMarksAndClocks [

	| entry engine problems moments |
	session login.
	session loadMoreGames.
	entry := session games first.
	engine := StockfishEngineStub new.
	engine beMissing.
	session analyser: (GameAnalyser engine: engine).
	session classifier: (AnswerClassifier
			 client: OllamaClientStub new
			 taxonomy: MistakeTaxonomy default).
	problems := OrderedCollection new.
	moments := session
		           momentsFor: entry
		           marks: { (Dictionary new
				            at: 'ply' put: 1;
				            at: 'note' put: '';
				            yourself) }
		           problems: problems.
	self
		assert: (moments collect: [ :each | each ply ]) asArray
		equals: #( 1 ).
	self assert: (problems includes:
			 'Stockfish not found: moments come only from your marks and long thinks.').
	self deny: (session isAnalysed: entry).
	self assert:
		(session degradedModeNotes first beginsWith: 'Stockfish not found')
]
