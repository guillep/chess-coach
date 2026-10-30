"
I am a position of an opening tree, whatever move order reached it. database is the explorer's answer for me once it was fetched.
"
Class {
	#name : 'OpeningNode',
	#superclass : 'Object',
	#instVars : [
		'key',
		'fen',
		'games',
		'points',
		'moves',
		'database'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
OpeningNode class >> fromDictionary: aDictionary [

	^ self new setFromDictionary: aDictionary
]

{ #category : 'instance creation' }
OpeningNode class >> key: aKey fen: aFEN [

	^ self new setKey: aKey fen: aFEN
]

{ #category : 'adding' }
OpeningNode >> addPoints: aNumber [

	games := games + 1.
	points := points + aNumber
]

{ #category : 'converting' }
OpeningNode >> asDictionary [

	^ Dictionary new
		  at: 'key' put: key;
		  at: 'fen' put: fen;
		  at: 'games' put: games;
		  at: 'points' put: points asFloat;
		  at: 'moves'
		  put: (moves values asArray collect: [ :each | each asDictionary ]);
		  at: 'database' put: database;
		  yourself
]

{ #category : 'accessing' }
OpeningNode >> database [

	^ database
]

{ #category : 'accessing' }
OpeningNode >> database: aDictionary [

	database := aDictionary
]

{ #category : 'accessing' }
OpeningNode >> databaseScoreOf: aUCI for: aColor [
	"The explorer's score of the move for aColor, or nil when it isn't known"

	| move total |
	database ifNil: [ ^ nil ].
	move := (database at: 'moves')
		        detect: [ :each | (each at: 'uci') = aUCI ]
		        ifNone: [ ^ nil ].
	total := self gamesOfDatabaseMove: move.
	total = 0 ifTrue: [ ^ nil ].
	^ (move at: aColor asString) + ((move at: 'draws') / 2) / total
]

{ #category : 'accessing' }
OpeningNode >> fen [

	^ fen
]

{ #category : 'accessing' }
OpeningNode >> games [

	^ games
]

{ #category : 'accessing' }
OpeningNode >> gamesOfDatabaseMove: aDictionary [

	^ (aDictionary at: 'white') + (aDictionary at: 'draws')
	  + (aDictionary at: 'black')
]

{ #category : 'accessing' }
OpeningNode >> key [

	^ key
]

{ #category : 'adding' }
OpeningNode >> moveFor: aUCI san: aSAN [

	^ moves at: aUCI ifAbsentPut: [ OpeningMove uci: aUCI san: aSAN ]
]

{ #category : 'accessing' }
OpeningNode >> moves [
	"My moves, most played first"

	^ moves values sort: [ :a :b | a games > b games ]
]

{ #category : 'accessing' }
OpeningNode >> score [

	^ points / games
]

{ #category : 'initialization' }
OpeningNode >> setFromDictionary: aDictionary [

	self setKey: (aDictionary at: 'key') fen: (aDictionary at: 'fen').
	games := aDictionary at: 'games'.
	points := aDictionary at: 'points'.
	database := aDictionary at: 'database'.
	(aDictionary at: 'moves') do: [ :each |
			| move |
			move := OpeningMove fromDictionary: each.
			moves at: move uci put: move ]
]

{ #category : 'initialization' }
OpeningNode >> setKey: aKey fen: aFEN [

	key := aKey.
	fen := aFEN.
	games := 0.
	points := 0.
	moves := Dictionary new
]

{ #category : 'accessing' }
OpeningNode >> topDatabaseMoves [
	"The explorer's five most played moves"

	database ifNil: [ ^ #(  ) ].
	^ ((database at: 'moves') asArray sort: [ :a :b |
		   (self gamesOfDatabaseMove: a) > (self gamesOfDatabaseMove: b) ])
		  first: ((database at: 'moves') size min: 5)
]

{ #category : 'accessing' }
OpeningNode >> turn [
	"The side to move: #white or #black"

	^ fen substrings second = 'w'
		  ifTrue: [ #white ]
		  ifFalse: [ #black ]
]
