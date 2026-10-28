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
		'date',
		'createdAt',
		'speed'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'accessing' }
GameIndexEntry >> createdAt [
	"Creation time on the source site, in milliseconds since the Unix epoch."

	^ createdAt
]

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
GameIndexEntry >> gameId: aString filepath: aPath dateImported: aTimestamp source: aSource players: aPlayersList result: aResult date: aDate createdAt: aMillisecondCount [

	gameId := aString.
	filepath := aPath.
	dateImported := aTimestamp.
	source := aSource.
	players := aPlayersList.
	result := aResult.
	date := aDate.
	createdAt := aMillisecondCount.
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

{ #category : 'accessing' }
GameIndexEntry >> speed [
	"ultraBullet, bullet, blitz, rapid, classical or correspondence; nil for entries indexed before speeds were recorded"

	^ speed
]

{ #category : 'accessing' }
GameIndexEntry >> speed: aString [

	speed := aString
]
