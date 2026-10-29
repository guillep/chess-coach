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
	"Public resources work without a token: it is only sent when logged in"

	| client |
	client := ZnClient new.
	client url: aZnUrl.
	client accept: aMimeTypeString.
	accessToken ifNotNil: [
		client headerAt: 'Authorization' put: 'Bearer ' , accessToken ].
	client get.
	client isSuccess ifFalse: [
		^ LichessError signalForResponse: client response ].
	^ client contents
]

{ #category : 'private' }
LichessAPIClient >> getJSONLines: aZnUrl [
	"GET an NDJSON resource and answer one dictionary per line. Zinc doesn't know application/x-ndjson is text and answers bytes, so they are decoded as UTF-8 here."

	^ ((self textFrom: (self get: aZnUrl accept: 'application/x-ndjson'))
		   lines reject: [ :line | line trimBoth isEmpty ]) collect: [ :line |
		  STONJSON fromString: line ]
]

{ #category : 'initialization' }
LichessAPIClient >> initialize [

	baseUrl := 'https://lichess.org/api'
]

{ #category : 'fetching' }
LichessAPIClient >> playerExists: aUsername [
	"Lichess answers 404 for unknown players; other failures are errors"

	| client |
	client := ZnClient new.
	client url: baseUrl asZnUrl / 'user' / aUsername.
	client accept: 'application/json'.
	client get.
	client response code = 404 ifTrue: [ ^ false ].
	client isSuccess ifFalse: [
		^ LichessError signalForResponse: client response ].
	^ true
]

{ #category : 'private' }
LichessAPIClient >> textFrom: aStringOrByteArray [

	^ aStringOrByteArray isString
		  ifTrue: [ aStringOrByteArray ]
		  ifFalse: [ aStringOrByteArray utf8Decoded ]
]

{ #category : 'private' }
LichessAPIClient >> userGamesUrl: username max: maxGames until: untilMillis since: sinceMillis [
	"PGNs include [%clk] comments so the coach knows the time left on each move"

	| url |
	url := baseUrl asZnUrl / 'games' / 'user' / username.
	url
		queryAt: 'max' put: maxGames printString;
		queryAt: 'pgnInJson' put: 'true';
		queryAt: 'clocks' put: 'true'.
	untilMillis ifNotNil: [
		url queryAt: 'until' put: untilMillis printString ].
	sinceMillis ifNotNil: [
		url queryAt: 'since' put: sinceMillis printString ].
	^ url
]
