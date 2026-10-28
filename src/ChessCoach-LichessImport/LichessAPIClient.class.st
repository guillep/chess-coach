"
HTTP client for the Lichess API. Fetches user games, game details, and other Lichess data using the authenticated access token.
"
Class {
	#name : 'LichessAPIClient',
	#superclass : 'Object',
	#instVars : [
		'accessToken',
		'baseUrl'
	],
	#category : 'ChessCoach-LichessImport',
	#package : 'ChessCoach-LichessImport'
}

{ #category : 'accessing' }
LichessAPIClient >> accessToken [

	^ accessToken
]

{ #category : 'accessing' }
LichessAPIClient >> accessToken: aString [

	accessToken := aString
]

{ #category : 'accessing' }
LichessAPIClient >> baseUrl [

	^ baseUrl
]

{ #category : 'fetching' }
LichessAPIClient >> fetchMe [
	"Fetch current user profile info"

	^ STONJSON fromString:
		  (self get: baseUrl asZnUrl / 'account' accept: 'application/json')
]

{ #category : 'fetching' }
LichessAPIClient >> fetchUserGames: username max: maxGames until: untilMillis since: sinceMillis [
	"Answer up to maxGames game dictionaries, newest first, each with its PGN under 'pgn'.
	untilMillis and sinceMillis bound the creation time and may be nil."

	^ self getJSONLines: (self
			   userGamesUrl: username
			   max: maxGames
			   until: untilMillis
			   since: sinceMillis)
]

{ #category : 'private' }
LichessAPIClient >> get: aZnUrl accept: aMimeTypeString [

	| client |
	client := ZnClient new.
	client url: aZnUrl.
	client accept: aMimeTypeString.
	client headerAt: 'Authorization' put: 'Bearer ' , accessToken.
	client get.
	client isSuccess ifFalse: [
		^ LichessError signalForResponse: client response ].
	^ client contents
]

{ #category : 'private' }
LichessAPIClient >> getJSONLines: aZnUrl [
	"GET an NDJSON resource and answer one dictionary per line"

	^ ((self get: aZnUrl accept: 'application/x-ndjson') lines reject: [
		   :line | line trimBoth isEmpty ]) collect: [ :line |
		  STONJSON fromString: line ]
]

{ #category : 'initialization' }
LichessAPIClient >> initialize [

	baseUrl := 'https://lichess.org/api'
]

{ #category : 'private' }
LichessAPIClient >> userGamesUrl: username max: maxGames until: untilMillis since: sinceMillis [

	| url |
	url := baseUrl asZnUrl / 'games' / 'user' / username.
	url
		queryAt: 'max' put: maxGames printString;
		queryAt: 'pgnInJson' put: 'true'.
	untilMillis ifNotNil: [
		url queryAt: 'until' put: untilMillis printString ].
	sinceMillis ifNotNil: [
		url queryAt: 'since' put: sinceMillis printString ].
	^ url
]
