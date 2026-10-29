"
Orchestrates the complete Lichess import workflow: OAuth2 login, fetching games from the API, parsing PGN, and storing to disk.
"
Class {
	#name : 'LichessGameImporter',
	#superclass : 'Object',
	#instVars : [
		'oauthClient',
		'apiClient',
		'fileStore',
		'indexManager',
		'pageSize'
	],
	#category : 'ChessCoach-LichessImport',
	#package : 'ChessCoach-LichessImport'
}

{ #category : 'instance creation' }
LichessGameImporter class >> oauthClient: anOAuthClient apiClient: anAPIClient directory: aFileReference [

	| fileStore |
	fileStore := GameFileStore new initializeWithBaseDirectory:
		             aFileReference.
	^ self new
		  initializeWithOAuthClient: anOAuthClient
		  apiClient: anAPIClient
		  fileStore: fileStore
		  indexManager:
		  (GameIndexManager new initializeWithFileStore: fileStore)
]

{ #category : 'instance creation' }
LichessGameImporter class >> onDirectory: aFileReference [
	"Keep the token, the PGN files and the index under aFileReference"

	^ self
		  oauthClient:
		  (LichessOAuth2Client onTokenFile: aFileReference / 'lichess-token')
		  apiClient: LichessAPIClient new
		  directory: aFileReference
]

{ #category : 'accessing' }
LichessGameImporter >> apiClient [

	^ apiClient
]

{ #category : 'oauth2' }
LichessGameImporter >> cancelLogin [

	oauthClient cancelAuthentication
]

{ #category : 'accessing' }
LichessGameImporter >> explorerClient [
	"An opening explorer client using my token, caching answers next to the games"

	^ LichessExplorerClient
		  accessToken: oauthClient accessToken
		  cacheDirectory: fileStore baseDirectory / 'explorer-cache'
]

{ #category : 'accessing' }
LichessGameImporter >> fileStore [

	^ fileStore
]

{ #category : 'accessing' }
LichessGameImporter >> games [
	"Answer the imported games' index entries, newest first"

	^ indexManager index entries asArray sort: [ :a :b |
		  a createdAt > b createdAt ]
]

{ #category : 'private' }
LichessGameImporter >> importGamesUntil: untilMillis since: sinceMillis [

	^ ((apiClient
		    fetchUserGames: self username
		    max: self pageSize
		    until: untilMillis
		    since: sinceMillis) reject: [ :gameData |
		   (indexManager index findById: (gameData at: 'id')) notNil ])
		  collect: [ :gameData | self saveGameFromData: gameData ]
]

{ #category : 'importing' }
LichessGameImporter >> importNewerGames [
	"Import every game created after the newest one we have, page by page from the newest down. Answer the new entries."

	| games since until entries page |
	games := self ownGames.
	games ifEmpty: [ ^ self importOlderGames ].
	since := games first createdAt + 1.
	entries := OrderedCollection new.
	[
		page := apiClient
			        fetchUserGames: self username
			        max: self pageSize
			        until: until
			        since: since.
		entries addAll: (page
				 reject: [ :gameData |
					 (indexManager index findById: (gameData at: 'id')) notNil ]
				 thenCollect: [ :gameData | self saveGameFromData: gameData ]).
		page size < self pageSize ] whileFalse: [
			until := (page detectMin: [ :gameData | gameData at: 'createdAt' ])
				         at: 'createdAt'.
			until := until - 1 ].
	^ entries asArray
]

{ #category : 'importing' }
LichessGameImporter >> importOlderGames [
	"Import the page of games created before the oldest one we have. Answer the new entries."

	| games |
	games := self ownGames.
	^ self
		  importGamesUntil:
		  (games ifEmpty: [ nil ] ifNotEmpty: [ games last createdAt - 1 ])
		  since: nil
]

{ #category : 'accessing' }
LichessGameImporter >> indexManager [

	^ indexManager
]

{ #category : 'initialization' }
LichessGameImporter >> initializeWithOAuthClient: anOAuthClient apiClient: anAPIClient fileStore: aFileStore indexManager: anIndexManager [

	oauthClient := anOAuthClient.
	apiClient := anAPIClient.
	apiClient accessToken: oauthClient accessToken.
	fileStore := aFileStore.
	indexManager := anIndexManager
]

{ #category : 'oauth2' }
LichessGameImporter >> isLoggedIn [

	^ oauthClient hasValidToken
]

{ #category : 'oauth2' }
LichessGameImporter >> login [
	"Run the browser login and record whose account it is (also as my username).
	Answer whether it succeeded; false means cancelled or timed out."

	| token name |
	token := oauthClient authenticate.
	apiClient accessToken: token.
	token ifNil: [ ^ false ].
	name := apiClient fetchMe at: 'username'.
	oauthClient username: name.
	self username: name.
	^ true
]

{ #category : 'oauth2' }
LichessGameImporter >> logout [
	"Forget the token; imported games stay on disk"

	oauthClient logout.
	apiClient accessToken: nil
]

{ #category : 'accessing' }
LichessGameImporter >> oauthClient [

	^ oauthClient
]

{ #category : 'accessing' }
LichessGameImporter >> ownGames [
	"My Lichess games' index entries, newest first (the index may also hold games from other sites)"

	^ self games select: [ :each | each source = 'lichess' ]
]

{ #category : 'accessing' }
LichessGameImporter >> pageSize [
	"Games per request (Load more)"

	^ pageSize ifNil: [ 20 ]
]

{ #category : 'accessing' }
LichessGameImporter >> pageSize: anInteger [

	pageSize := anInteger
]

{ #category : 'private' }
LichessGameImporter >> playerNameIn: playerData [

	playerData at: 'user' ifPresent: [ :user | ^ user at: 'name' ].
	playerData
		at: 'aiLevel'
		ifPresent: [ :level | ^ 'Stockfish level ' , level printString ].
	^ 'Anonymous'
]

{ #category : 'private' }
LichessGameImporter >> resultIn: gameData [

	(gameData at: 'status') = 'started' ifTrue: [ ^ '*' ].
	^ gameData
		  at: 'winner'
		  ifPresent: [ :winner |
				  winner = 'white'
					  ifTrue: [ '1-0' ]
					  ifFalse: [ '0-1' ] ]
		  ifAbsent: [ '1/2-1/2' ]
]

{ #category : 'private' }
LichessGameImporter >> saveGameFromData: gameData [
	"Save one game from a Lichess API response as PGN and index it. Answer its index entry."

	| gameId createdAt |
	gameId := gameData at: 'id'.
	createdAt := gameData at: 'createdAt'.
	fileStore savePGN: (gameData at: 'pgn') withId: gameId.
	^ indexManager addGameEntry: (Dictionary new
			   at: 'gameId' put: gameId;
			   at: 'filepath' put: (fileStore relativePathOf: gameId);
			   at: 'dateImported' put: DateAndTime now asString;
			   at: 'source' put: 'lichess';
			   at: 'players' put: (#( 'white' 'black' ) collect: [ :color |
						    self playerNameIn: ((gameData at: 'players') at: color) ]);
			   at: 'result' put: (self resultIn: gameData);
			   at: 'date'
			   put:
				   (DateAndTime fromUnixTime: createdAt // 1000) asDate yyyymmdd;
			   at: 'createdAt' put: createdAt;
			   at: 'speed' put: (gameData at: 'speed' ifAbsent: [ nil ]);
			   yourself)
]

{ #category : 'accessing' }
LichessGameImporter >> username [
	"My Lichess username: the one I set (games are public, no login needed), else the logged-in account's, else nil"

	self usernameFile exists ifTrue: [
		self usernameFile contents trimBoth ifNotEmpty: [ :name | ^ name ] ].
	^ oauthClient username
]

{ #category : 'accessing' }
LichessGameImporter >> username: aStringOrNil [
	"Remember my Lichess username; nil or empty forgets it (imported games stay)"

	self usernameFile ensureDelete.
	aStringOrNil isEmptyOrNil ifTrue: [ ^ self ].
	self usernameFile parent ensureCreateDirectory.
	self usernameFile writeStreamDo: [ :stream |
		stream nextPutAll: aStringOrNil trimBoth ]
]

{ #category : 'accessing' }
LichessGameImporter >> usernameFile [

	^ fileStore baseDirectory / 'lichess-username'
]
