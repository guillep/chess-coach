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
ChessCoachSessionTest >> gameNumber: i [
	"A Lichess API game dictionary created at i seconds after the epoch"

	^ Dictionary new
		  at: 'id' put: 'g' , (i printPaddedWith: $0 to: 2);
		  at: 'createdAt' put: i * 1000;
		  at: 'status' put: 'mate';
		  at: 'winner' put: 'white';
		  at: 'players' put: (Dictionary new
				   at: 'white' put: (Dictionary new
						    at: 'user' put: (Dictionary new
								     at: 'name' put: 'alice';
								     yourself);
						    yourself);
				   at: 'black' put: (Dictionary new
					    at: 'aiLevel' put: 3;
					    yourself);
				   yourself);
		  at: 'pgn' put: '[White "alice"]
[Black "Stockfish"]
[Result "1-0"]

1. e4 e5 1-0';
		  yourself
]

{ #category : 'helpers' }
ChessCoachSessionTest >> newSession [

	^ ChessCoachSession importer: (LichessGameImporter
			   oauthClient:
			   (LichessOAuth2ClientStub onTokenFile: root / 'lichess-token')
			   apiClient: api
			   directory: root)
]

{ #category : 'running' }
ChessCoachSessionTest >> setUp [

	super setUp.
	root := FileSystem memory root.
	api := LichessAPIClientStub new games:
		       ((25 to: 1 by: -1) collect: [ :i | self gameNumber: i ]).
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
ChessCoachSessionTest >> testRefreshFetchesNewerGames [

	session login.
	session loadMoreGames.
	api addNewestGame: (self gameNumber: 26).
	session refresh.
	self assert: session games size equals: 21.
	self assert: session games first gameId equals: 'g26'
]

{ #category : 'tests' }
ChessCoachSessionTest >> testStartsLoggedOutWithNoGames [

	self deny: session isLoggedIn.
	self assert: session games isEmpty
]
