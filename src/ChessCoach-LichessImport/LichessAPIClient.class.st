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
LichessAPIClient >> baseUrl [

	^ baseUrl
]

{ #category : 'fetching' }
LichessAPIClient >> fetchMe [
	"Fetch current user profile info"

	| client response |
	client := ZnClient new.
	client url: baseUrl , '/account'.
	client headerAt: 'Authorization' put: 'Bearer ' , accessToken.
	response := client get.
	^ STONJSON fromString: response
]

{ #category : 'fetching' }
LichessAPIClient >> fetchUserGames: username max: maxGames [
	"Fetch games for a user from Lichess API"

	| client url response games |
	client := ZnClient new.
	url := baseUrl , '/games/user/' , username , '?max='
	       , maxGames asString , '&pgnInJson=true'.
	client url: url.
	client headerAt: 'Authorization' put: 'Bearer ' , accessToken.
	response := client get.
	games := OrderedCollection new.
	response asString linesDo: [ :line |
			| trimmed |
			trimmed := line trim.
			trimmed isEmpty ifFalse: [
				games add: (STONJSON fromString: trimmed) ] ].
	^ games
]

{ #category : 'initialization' }
LichessAPIClient >> initialize [

	baseUrl := 'https://lichess.org/api'.
	^ self
]

{ #category : 'initialization' }
LichessAPIClient >> initializeWithToken: aToken [

	accessToken := aToken.
	baseUrl := 'https://lichess.org/api'
]
