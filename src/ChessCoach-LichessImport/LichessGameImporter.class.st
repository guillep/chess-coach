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

{ #category : 'accessing' }
LichessGameImporter >> apiClient [

	^ apiClient
]

{ #category : 'private' }
LichessGameImporter >> filterNewGames: games [
	"Return only games not already in index"

	| currentIds |
	currentIds := indexManager index gameIds asSet.
	^ games select: [ :gameData |
		  (currentIds includes: (gameData at: 'id')) not ]
]

{ #category : 'importing' }
LichessGameImporter >> importNewGames [
	"Main import workflow: ensure token, fetch, save, index"

	| games newGames username userInfo token |
	oauthClient hasValidToken ifFalse: [
			token := oauthClient authenticate.
			token ifNil: [ ^ #(  ) ] ].
	apiClient := LichessAPIClient new initializeWithToken:
		             oauthClient accessToken.
	userInfo := apiClient fetchMe.
	username := userInfo at: 'username'.
	games := apiClient fetchUserGames: username max: 50.
	newGames := self filterNewGames: games.
	newGames do: [ :gameData | self saveGameFromData: gameData ].
	^ newGames
]

{ #category : 'initialization' }
LichessGameImporter >> initializeWithOAuthClient: anOAuthClient apiClient: anAPIClient fileStore: aFileStore indexManager: anIndexManager [

	oauthClient := anOAuthClient.
	apiClient := anAPIClient ifNotNil: [ anAPIClient ] ifNil: [
			             anOAuthClient accessToken ifNotNil: [
				             LichessAPIClient new initializeWithToken:
					             anOAuthClient accessToken ] ].
	fileStore := aFileStore.
	indexManager := anIndexManager
]

{ #category : 'accessing' }
LichessGameImporter >> oauthClient [

	^ oauthClient
]

{ #category : 'oauth2' }
LichessGameImporter >> requestOAuthToken [
	"OAuth handled by LichessOAuth2Client. Returns current token or nil."

	^ oauthClient ifNotNil: [ oauthClient accessToken ] ifNil: [ nil ]
]

{ #category : 'oauth2' }
LichessGameImporter >> requestOAuthTokenAsync [
	"Run the OAuth flow in background so the UI is not blocked."

	[ self requestOAuthToken ] forkAt: Processor userBackgroundPriority.
	^ self
]

{ #category : 'private' }
LichessGameImporter >> saveGameFromData: gameData [
	"Save a single game from Lichess API response to disk and index"

	| gameId pgn metadata entryDict |
	gameId := gameData at: 'id'.
	pgn := gameData at: 'pgn'.
	"Extract metadata from game data"
	metadata := Dictionary new.
	metadata at: 'source' put: 'lichess'.
	metadata at: 'sourceId' put: gameId.
	metadata
		at: 'players'
		put: #( #( gameData at: 'players' ifAbsent: #'[' #(  ) #']' ) ).
	metadata at: 'result' put: (gameData at: 'status' ifAbsent: [ '' ]).
	metadata
		at: 'date'
		put:
		(gameData at: 'createdAt' ifAbsent: [ DateAndTime now asString ]).
	metadata
		at: 'timeControl'
		put: (gameData at: 'speed' ifAbsent: [ '' ]).
	metadata at: 'dateImported' put: DateAndTime now asString.
	"Save game file"
	fileStore
		saveGame: (Dictionary new
				 at: 'pgn' put: pgn;
				 at: 'metadata' put: metadata;
				 yourself)
		withId: gameId.
	"Add to index"
	entryDict := Dictionary new.
	entryDict at: 'gameId' put: gameId.
	entryDict at: 'filepath' put: 'games/' , gameId , '.json'.
	entryDict at: 'dateImported' put: DateAndTime now asString.
	entryDict at: 'source' put: 'lichess'.
	entryDict at: 'players' put: (metadata at: 'players').
	entryDict at: 'result' put: (metadata at: 'result').
	entryDict at: 'date' put: (metadata at: 'date').
	indexManager addGameEntry: entryDict
]

{ #category : 'private' }
LichessGameImporter >> startOAuthCallbackServer [
	"Start a simple HTTP server to capture the OAuth callback on localhost:8888"

	| server authCode sem |
	authCode := nil.
	sem := Semaphore new.
	server := ZnServer on: 8888.
	server onRequestRespond: [ :request |
			| code response |
			code := [ request uri queryAt: #code ]
				        on: Error
				        do: [ nil ].
			code
				ifNotNil: [
						authCode := code.
						[
							(Delay forMilliseconds: 100) wait.
							oauthClient exchangeCodeForToken: authCode.
							sem signal ] fork.
						response := ZnResponse ok: (ZnEntity html:
								             '<html><body><h1>Authentication successful!</h1><p>You can close this window.</p></body></html>') ]
				ifNil: [
						response := ZnResponse badRequest: (ZnEntity html:
								             '<html><body><h1>Error</h1><p>No authorization code received.</p></body></html>') ].
			response ].
	server start.
	sem waitTimeoutSeconds: 300.
	server stop.
	^ oauthClient accessToken
]
