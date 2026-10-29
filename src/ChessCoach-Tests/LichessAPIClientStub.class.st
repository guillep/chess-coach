"
I answer canned Lichess game dictionaries (newest first) instead of calling the network. Set an error to make fetching signal it.
"
Class {
	#name : 'LichessAPIClientStub',
	#superclass : 'LichessAPIClient',
	#instVars : [
		'games',
		'error'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'examples' }
LichessAPIClientStub class >> gameNumber: i [
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

{ #category : 'instance creation' }
LichessAPIClientStub class >> withGames: aNumber [
	"A stub whose account has aNumber games, numbered 1 (oldest) to aNumber"

	^ self new games:
		  ((aNumber to: 1 by: -1) collect: [ :i | self gameNumber: i ])
]

{ #category : 'accessing' }
LichessAPIClientStub >> addNewestGame: aDictionary [

	games := { aDictionary } , games
]

{ #category : 'accessing' }
LichessAPIClientStub >> error: anException [

	error := anException
]

{ #category : 'fetching' }
LichessAPIClientStub >> fetchMe [

	^ Dictionary new
		  at: 'username' put: 'tester';
		  yourself
]

{ #category : 'fetching' }
LichessAPIClientStub >> fetchUserGames: username max: maxGames until: untilMillis since: sinceMillis [

	| matching |
	error ifNotNil: [ error signal ].
	matching := games select: [ :game |
			            | createdAt |
			            createdAt := game at: 'createdAt'.
			            (untilMillis isNil or: [ createdAt <= untilMillis ])
				            and: [
				            sinceMillis isNil or: [ createdAt >= sinceMillis ] ] ].
	^ matching first: (maxGames min: matching size)
]

{ #category : 'accessing' }
LichessAPIClientStub >> games: aCollection [
	"Canned game dictionaries, newest first"

	games := aCollection
]

{ #category : 'accessing' }
LichessAPIClientStub >> newSessionOn: aFileReference [
	"A session that logs in with a stub OAuth client and fetches from me"

	^ ChessCoachSession importer: (LichessGameImporter
			   oauthClient:
			   (LichessOAuth2ClientStub onTokenFile:
				    aFileReference / 'lichess-token')
			   apiClient: self
			   directory: aFileReference)
]

{ #category : 'fetching' }
LichessAPIClientStub >> playerExists: aUsername [

	^ #( 'tester' 'alice' ) includes: aUsername asLowercase
]
