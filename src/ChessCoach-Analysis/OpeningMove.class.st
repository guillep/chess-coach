"
I am a move played from a position of an opening tree: how often, my score after it and, for my own moves, the thinking time.
"
Class {
	#name : 'OpeningMove',
	#superclass : 'Object',
	#instVars : [
		'uci',
		'san',
		'games',
		'points',
		'seconds',
		'timedGames',
		'nextKey'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
OpeningMove class >> fromDictionary: aDictionary [

	^ self new setFromDictionary: aDictionary
]

{ #category : 'instance creation' }
OpeningMove class >> uci: aUCI san: aSAN [

	^ self new setUCI: aUCI san: aSAN
]

{ #category : 'adding' }
OpeningMove >> addPoints: aNumber seconds: aNumberOrNil nextKey: aKey [

	games := games + 1.
	points := points + aNumber.
	nextKey := aKey.
	aNumberOrNil ifNil: [ ^ self ].
	seconds := seconds + aNumberOrNil.
	timedGames := timedGames + 1
]

{ #category : 'converting' }
OpeningMove >> asDictionary [

	^ Dictionary new
		  at: 'uci' put: uci;
		  at: 'san' put: san;
		  at: 'games' put: games;
		  at: 'points' put: points asFloat;
		  at: 'seconds' put: seconds asFloat;
		  at: 'timedGames' put: timedGames;
		  at: 'nextKey' put: nextKey;
		  yourself
]

{ #category : 'accessing' }
OpeningMove >> averageSeconds [
	"My average thinking time, or nil without clock data"

	timedGames = 0 ifTrue: [ ^ nil ].
	^ seconds / timedGames
]

{ #category : 'accessing' }
OpeningMove >> games [

	^ games
]

{ #category : 'accessing' }
OpeningMove >> nextKey [

	^ nextKey
]

{ #category : 'accessing' }
OpeningMove >> san [

	^ san
]

{ #category : 'accessing' }
OpeningMove >> score [
	"My score after this move, from 0 to 1"

	^ points / games
]

{ #category : 'initialization' }
OpeningMove >> setFromDictionary: aDictionary [

	self setUCI: (aDictionary at: 'uci') san: (aDictionary at: 'san').
	games := aDictionary at: 'games'.
	points := aDictionary at: 'points'.
	seconds := aDictionary at: 'seconds'.
	timedGames := aDictionary at: 'timedGames'.
	nextKey := aDictionary at: 'nextKey'
]

{ #category : 'initialization' }
OpeningMove >> setUCI: aUCI san: aSAN [

	uci := aUCI.
	san := aSAN.
	games := 0.
	points := 0.
	seconds := 0.
	timedGames := 0
]

{ #category : 'accessing' }
OpeningMove >> uci [

	^ uci
]
