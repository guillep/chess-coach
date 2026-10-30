"
I query the Lichess opening explorer (lichess games database). Answers are JSON dictionaries with 'white', 'draws', 'black' and 'moves' (each with 'san', 'uci', 'white', 'draws', 'black').
When given a cache directory I keep every answer there and never ask twice.
"
Class {
	#name : 'LichessExplorerClient',
	#superclass : 'Object',
	#instVars : [
		'accessToken',
		'cacheDirectory'
	],
	#category : 'ChessCoach-LichessImport',
	#package : 'ChessCoach-LichessImport'
}

{ #category : 'instance creation' }
LichessExplorerClient class >> accessToken: aToken cacheDirectory: aFileReference [

	^ self new
		  setAccessToken: aToken cacheDirectory: aFileReference;
		  yourself
]

{ #category : 'parameters' }
LichessExplorerClient class >> ratingBucketsAround: aRating [
	"The explorer's rating groups that overlap aRating ± 200"

	| buckets |
	buckets := #( 0 1000 1200 1400 1600 1800 2000 2200 2500 ).
	^ (1 to: buckets size)
		  select: [ :index |
				  | low high |
				  low := buckets at: index.
				  high := index = buckets size
					          ifTrue: [ SmallInteger maxVal ]
					          ifFalse: [ (buckets at: index + 1) - 1 ].
				  low <= (aRating + 200) and: [ high >= (aRating - 200) ] ]
		  thenCollect: [ :index | buckets at: index ]
]

{ #category : 'parameters' }
LichessExplorerClient class >> speedForTimeControl: aString [
	"Lichess's speed for a PGN TimeControl like '180+2'"

	^ Game speedForTimeControl: aString
]

{ #category : 'private' }
LichessExplorerClient >> cachedAt: aKey ifAbsent: aBlock [

	| file contents |
	cacheDirectory ifNil: [ ^ aBlock value ].
	file := cacheDirectory
	        / ((SHA256 new hashMessage: aKey utf8Encoded) hex , '.json').
	file exists ifTrue: [ ^ file contents ].
	contents := aBlock value.
	cacheDirectory ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream nextPutAll: contents ].
	^ contents
]

{ #category : 'private' }
LichessExplorerClient >> get: aZnUrl [

	| client |
	client := ZnClient new.
	client url: aZnUrl.
	client accept: 'application/json'.
	accessToken ifNotNil: [
		client headerAt: 'Authorization' put: 'Bearer ' , accessToken ].
	client get.
	client isSuccess ifFalse: [
		^ LichessError signalForResponse: client response ].
	^ client contents
]

{ #category : 'querying' }
LichessExplorerClient >> lichessMovesFor: aFEN speed: aSpeed ratings: someRatings [
	"The Lichess database's moves from aFEN for games at aSpeed between players in the given rating groups (all ratings when empty)"

	| url key |
	url := 'https://explorer.lichess.ovh/lichess' asZnUrl.
	url
		queryAt: 'variant' put: 'standard';
		queryAt: 'fen' put: aFEN;
		queryAt: 'speeds' put: aSpeed;
		queryAt: 'moves' put: '12'.
	someRatings ifNotEmpty: [
			url
				queryAt: 'ratings'
				put:
				(',' join: (someRatings collect: [ :each | each printString ])) ].
	key := url printString.
	^ STONJSON fromString:
		  (self cachedAt: key ifAbsent: [ self get: url ])
]

{ #category : 'querying' }
LichessExplorerClient >> mastersMovesFor: aFEN [
	"The masters database's moves from aFEN"

	| url |
	url := 'https://explorer.lichess.ovh/masters' asZnUrl.
	url
		queryAt: 'fen' put: aFEN;
		queryAt: 'moves' put: '12'.
	^ STONJSON fromString:
		  (self cachedAt: url printString ifAbsent: [ self get: url ])
]

{ #category : 'initialization' }
LichessExplorerClient >> setAccessToken: aToken cacheDirectory: aFileReference [

	accessToken := aToken.
	cacheDirectory := aFileReference
]
