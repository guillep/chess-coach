"
In-memory index of all imported games. Provides lookup and management of GameIndexEntry objects.
"
Class {
	#name : 'GameIndex',
	#superclass : 'Object',
	#instVars : [
		'entries'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'adding' }
GameIndex >> addEntry: aGameIndexEntry [

	entries add: aGameIndexEntry
]

{ #category : 'accessing' }
GameIndex >> entries [

	^ entries
]

{ #category : 'querying' }
GameIndex >> findById: gameId [

	^ entries detect: [ :entry | entry gameId = gameId ] ifNone: [ nil ]
]

{ #category : 'accessing' }
GameIndex >> gameIds [

	^ entries collect: [ :entry | entry gameId ]
]

{ #category : 'initialization' }
GameIndex >> initialize [

	entries := OrderedCollection new
]
