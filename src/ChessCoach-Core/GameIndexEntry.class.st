"
Represents a single entry in the game index. Tracks metadata about a stored game file for quick lookup and listing.
"
Class {
	#name : 'GameIndexEntry',
	#superclass : 'Object',
	#instVars : [
		'gameId',
		'filepath',
		'dateImported',
		'source',
		'players',
		'result',
		'date'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'accessing' }
GameIndexEntry >> date [

	^ date
]

{ #category : 'accessing' }
GameIndexEntry >> dateImported [

	^ dateImported
]

{ #category : 'accessing' }
GameIndexEntry >> filepath [

	^ filepath
]

{ #category : 'accessing' }
GameIndexEntry >> gameId [

	^ gameId
]

{ #category : 'initialization' }
GameIndexEntry >> gameId: aString filepath: aPath dateImported: aTimestamp source: aSource players: aPlayersList result: aResult date: aDate [

	gameId := aString.
	filepath := aPath.
	dateImported := aTimestamp.
	source := aSource.
	players := aPlayersList.
	result := aResult.
	date := aDate.
	^ self
]

{ #category : 'accessing' }
GameIndexEntry >> players [

	^ players
]

{ #category : 'accessing' }
GameIndexEntry >> result [

	^ result
]

{ #category : 'accessing' }
GameIndexEntry >> source [

	^ source
]
