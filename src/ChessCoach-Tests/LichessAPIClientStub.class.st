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
