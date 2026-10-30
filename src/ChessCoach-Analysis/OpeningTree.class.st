"
I am a saved opening tree: my filters and the positions of the games that match them, by position key (FEN without the move counters). A position reached by a single game is dropped, so a branch ends with the move leaving the other games.
"
Class {
	#name : 'OpeningTree',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'color',
		'speed',
		'fromDate',
		'toDate',
		'databaseSource',
		'databaseSpeed',
		'ratings',
		'builtOn',
		'gameCount',
		'nodes',
		'period'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'constants' }
OpeningTree class >> formatVersion [
	"The version of the opening tree file format"

	^ 1
]

{ #category : 'instance creation' }
OpeningTree class >> fromJSON: aString [

	^ self new setFromDictionary: (STONJSON fromString: aString)
]

{ #category : 'positions' }
OpeningTree class >> keyOf: aChessPosition [
	"The position's FEN without the move counters, so transpositions share a key"

	^ ' ' join: (aChessPosition fen substrings first: 4)
]

{ #category : 'instance creation' }
OpeningTree class >> named: aName color: aColor speed: aSpeedOrNil from: aFromDateOrNil to: aToDateOrNil databaseSource: aSource databaseSpeed: aDatabaseSpeed ratings: someRatings [
	"Dates are 'yyyy-mm-dd' strings; aSource is 'lichess' or 'masters'"

	^ self new
		  setName: aName
		  color: aColor
		  speed: aSpeedOrNil
		  from: aFromDateOrNil
		  to: aToDateOrNil
		  databaseSource: aSource
		  databaseSpeed: aDatabaseSpeed
		  ratings: someRatings
]

{ #category : 'building' }
OpeningTree >> addGame: aGame points: aNumber [
	"Count a game in which I scored aNumber (1, 0.5 or 0)"

	| seconds position |
	seconds := (LongThinkFinder on: aGame) secondsPerPly.
	position := aGame initialPosition.
	gameCount := gameCount + 1.
	aGame moves withIndexDo: [ :move :ply |
			| node next |
			node := nodes
				        at: (self class keyOf: position)
				        ifAbsentPut: [
				        OpeningNode
					        key: (self class keyOf: position)
					        fen: position fen ].
			node addPoints: aNumber.
			next := position move: move san.
			(node moveFor: next lastMoveUCI san: move san)
				addPoints: aNumber
				seconds:
				(position turn = color ifTrue: [
					 seconds at: ply ifAbsent: [ nil ] ])
				nextKey: (self class keyOf: next).
			position := next ]
]

{ #category : 'converting' }
OpeningTree >> asJSON [

	^ STONJSON toString: (Dictionary new
			   at: 'formatVersion' put: self class formatVersion;
			   at: 'id' put: id;
			   at: 'name' put: name;
			   at: 'color' put: color asString;
			   at: 'speed' put: speed;
			   at: 'fromDate' put: fromDate;
			   at: 'toDate' put: toDate;
			   at: 'period' put: period;
			   at: 'databaseSource' put: databaseSource;
			   at: 'databaseSpeed' put: databaseSpeed;
			   at: 'ratings' put: ratings asArray;
			   at: 'builtOn' put: builtOn;
			   at: 'gameCount' put: gameCount;
			   at: 'nodes'
			   put:
				   (nodes values asArray collect: [ :each | each asDictionary ]);
			   yourself)
]

{ #category : 'accessing' }
OpeningTree >> builtOn [

	^ builtOn
]

{ #category : 'accessing' }
OpeningTree >> color [

	^ color
]

{ #category : 'accessing' }
OpeningTree >> databaseSource [

	^ databaseSource
]

{ #category : 'accessing' }
OpeningTree >> databaseSpeed [

	^ databaseSpeed
]

{ #category : 'building' }
OpeningTree >> databases [
	"The explorer answers fetched so far, by position key"

	| databases |
	databases := Dictionary new.
	nodes do: [ :each |
			each database ifNotNil: [ :database |
				databases at: each key put: database ] ].
	^ databases
]

{ #category : 'printing' }
OpeningTree >> filtersDescription [
	"My game filters in words, for when no game matches them"

	^ 'you playing {1}, {2}, {3}' format: {
			  color asString.
			  (speed ifNil: [ 'all time controls' ]).
			  (period ifNil: [ 'any date' ] ifNotNil: [
					   period = 0
						   ifTrue: [ 'today' ]
						   ifFalse: [ 'last ' , period printString , ' days' ] ]) }
]

{ #category : 'building' }
OpeningTree >> finishBuildingOn: aDateString [
	"Drop the positions of a single game, except the root"

	| root |
	root := self class keyOf: ChessPosition initial.
	nodes := nodes select: [ :each |
		         each games > 1 or: [ each key = root ] ].
	builtOn := aDateString
]

{ #category : 'accessing' }
OpeningTree >> gameCount [

	^ gameCount
]

{ #category : 'accessing' }
OpeningTree >> id [

	^ id
]

{ #category : 'weak spots' }
OpeningTree >> lowScoreSpots [
	"My moves with at least 5 games and a score below 40%, worst first"

	^ (self
		   spotsWhere: [ :node :move |
			   node turn = color and: [
				   move games >= 5 and: [ move score < 0.4 ] ] ]
		   kind: #lowScore) asArray sort: [ :a :b | a score < b score ]
]

{ #category : 'matching' }
OpeningTree >> matchesDate: aDateString [
	"Whether a 'yyyy-mm-dd' date is in my range"

	fromDate ifNotNil: [ aDateString < fromDate ifTrue: [ ^ false ] ].
	toDate ifNotNil: [ aDateString > toDate ifTrue: [ ^ false ] ].
	period ifNotNil: [
			aDateString < (Date today subtractDays: period) yyyymmdd ifTrue: [
				^ false ] ].
	^ true
]

{ #category : 'accessing' }
OpeningTree >> name [

	^ name
]

{ #category : 'accessing' }
OpeningTree >> name: aString [

	name := aString
]

{ #category : 'accessing' }
OpeningTree >> nodeAt: aKey [
	"The position, or nil when a branch ended before it"

	^ nodes at: aKey ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OpeningTree >> period: aNumberOfDaysOrNil [
	"Keep only the games of the last days, counted from each build; nil keeps them all"

	period := aNumberOfDaysOrNil
]

{ #category : 'weak spots' }
OpeningTree >> prepGapSpots [
	"Opponent replies faced at least 3 times where I score below 40%, worst first"

	^ (self
		   spotsWhere: [ :node :move |
			   node turn ~= color and: [
				   move games >= 3 and: [ move score < 0.4 ] ] ]
		   kind: #prepGap) asArray sort: [ :a :b | a score < b score ]
]

{ #category : 'accessing' }
OpeningTree >> ratings [

	^ ratings
]

{ #category : 'building' }
OpeningTree >> reset [
	"Forget the games, keeping the filters"

	gameCount := 0.
	nodes := Dictionary new
]

{ #category : 'building' }
OpeningTree >> restoreDatabases: aDictionary [
	"Put back the explorer answers fetched before a rebuild, by position key"

	aDictionary keysAndValuesDo: [ :key :database |
		(self nodeAt: key) ifNotNil: [ :node | node database: database ] ]
]

{ #category : 'accessing' }
OpeningTree >> root [
	"The initial position, or nil without games"

	^ nodes
		  at: (self class keyOf: ChessPosition initial)
		  ifAbsent: [ nil ]
]

{ #category : 'weak spots' }
OpeningTree >> scoreGapSpots [
	"My moves with at least 5 games scoring at least 10 points below the database, among the positions with fetched data, most points lost first"

	^ (self
		   spotsWhere: [ :node :move |
				   (node turn = color and: [ move games >= 5 ])
					   ifFalse: [ false ]
					   ifTrue: [
							   (node databaseScoreOf: move uci for: color)
								   ifNil: [ false ]
								   ifNotNil: [ :database |
										   database - move score >= 0.1
											   ifTrue: [ database - move score ]
											   ifFalse: [ false ] ] ] ]
		   kind: #scoreGap) asArray sort: [ :a :b |
		  a pointsLost > b pointsLost ]
]

{ #category : 'initialization' }
OpeningTree >> setFromDictionary: aDictionary [

	id := aDictionary at: 'id'.
	name := aDictionary at: 'name'.
	color := (aDictionary at: 'color') asSymbol.
	speed := aDictionary at: 'speed'.
	fromDate := aDictionary at: 'fromDate'.
	toDate := aDictionary at: 'toDate'.
	period := aDictionary at: 'period' ifAbsent: [ nil ].
	databaseSource := aDictionary at: 'databaseSource'.
	databaseSpeed := aDictionary at: 'databaseSpeed'.
	ratings := aDictionary at: 'ratings'.
	builtOn := aDictionary at: 'builtOn'.
	gameCount := aDictionary at: 'gameCount'.
	nodes := Dictionary new.
	(aDictionary at: 'nodes') do: [ :each |
			| node |
			node := OpeningNode fromDictionary: each.
			nodes at: node key put: node ]
]

{ #category : 'initialization' }
OpeningTree >> setName: aName color: aColor speed: aSpeedOrNil from: aFromDateOrNil to: aToDateOrNil databaseSource: aSource databaseSpeed: aDatabaseSpeed ratings: someRatings [

	id := UUID new asString.
	name := aName.
	color := aColor.
	speed := aSpeedOrNil.
	fromDate := aFromDateOrNil.
	toDate := aToDateOrNil.
	databaseSource := aSource.
	databaseSpeed := aDatabaseSpeed.
	ratings := someRatings.
	self reset
]

{ #category : 'accessing' }
OpeningTree >> speed [

	^ speed
]

{ #category : 'weak spots' }
OpeningTree >> spotsWhere: aBlock kind: aKind [
	"aBlock receives a node and a move and answers the gap, or false to skip it"

	| spots |
	spots := OrderedCollection new.
	nodes do: [ :node |
			node moves do: [ :move |
					(aBlock value: node value: move) ifNotNil: [ :gap |
							gap == false ifFalse: [
									spots add: (OpeningWeakSpot
											 kind: aKind
											 node: node
											 move: move
											 gap: (gap == true
													  ifTrue: [ nil ]
													  ifFalse: [ gap ])) ] ] ] ].
	^ spots
]
