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
		'indexManager'
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
	"Import games created after the newest one we have (at most one page). Answer the new entries."

	| games |
	games := self games.
	games ifEmpty: [ ^ self importOlderGames ].
	^ self importGamesUntil: nil since: games first createdAt + 1
]

{ #category : 'importing' }
LichessGameImporter >> importOlderGames [
	"Import the page of games created before the oldest one we have. Answer the new entries."

	| games |
	games := self games.
	^ self
		  importGamesUntil:
		  (games ifEmpty: [ nil ] ifNotEmpty: [ games last createdAt - 1 ])
		  since: nil
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
	"Run the browser login and record whose account it is.
	Answer whether it succeeded; false means cancelled or timed out."

	| token |
	token := oauthClient authenticate.
	apiClient accessToken: token.
	token ifNil: [ ^ false ].
	oauthClient username: (apiClient fetchMe at: 'username').
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
LichessGameImporter >> pageSize [

	^ 20
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
			   yourself)
]

{ #category : 'accessing' }
LichessGameImporter >> username [
	"The logged-in Lichess user's name, recorded at login; nil when logged out"

	^ oauthClient username
]
