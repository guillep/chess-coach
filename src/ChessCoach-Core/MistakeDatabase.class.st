"
All my MistakeRecords (the mistakes.json index, rebuilt from the reviews) and the queries over them: most frequent tags, tags by phase, tags over time, records with a tag.
"
Class {
	#name : 'MistakeDatabase',
	#superclass : 'Object',
	#instVars : [
		'records'
	],
	#category : 'ChessCoach-Core-Mistakes',
	#package : 'ChessCoach-Core',
	#tag : 'Mistakes'
}

{ #category : 'constants' }
MistakeDatabase class >> formatVersion [
	"The version of the mistakes file format. Version 0 was a bare list of records."

	^ 1
]

{ #category : 'instance creation' }
MistakeDatabase class >> fromJSON: aString [
	"Version 0 of the file is a bare list of records"

	| contents records |
	contents := STONJSON fromString: aString.
	records := contents isDictionary
		           ifTrue: [ contents at: 'records' ]
		           ifFalse: [ contents ].
	^ self withRecords:
		  (records collect: [ :each | MistakeRecord fromDictionary: each ])
]

{ #category : 'instance creation' }
MistakeDatabase class >> withRecords: someMistakeRecords [

	^ self new setRecords: someMistakeRecords
]

{ #category : 'converting' }
MistakeDatabase >> asJSON [

	^ STONJSON toString: (Dictionary new
			   at: 'formatVersion' put: self class formatVersion;
			   at: 'records'
			   put: (records collect: [ :each | each asDictionary ]);
			   yourself)
]

{ #category : 'accessing' }
MistakeDatabase >> records [
	"Oldest first"

	^ records
]

{ #category : 'queries' }
MistakeDatabase >> recordsWithTag: aTagId [

	^ records select: [ :each | each hasTag: aTagId ]
]

{ #category : 'initialization' }
MistakeDatabase >> setRecords: someMistakeRecords [

	records := someMistakeRecords asArray sort: [ :a :b |
		           a date < b date or: [
			           a date = b date and: [ a ply <= b ply ] ] ]
]

{ #category : 'queries' }
MistakeDatabase >> tagFrequencies [
	"Tag id -> number of mistakes with it, most frequent first"

	^ self tagFrequenciesIn: records
]

{ #category : 'queries' }
MistakeDatabase >> tagFrequenciesByGames: aGameCount [
	"Tag frequencies per block of aGameCount consecutive games, oldest block first"

	| gameIds |
	gameIds := (records collect: [ :each | each gameId ])
		           asOrderedCollection removeDuplicates.
	^ ((1 to: gameIds size by: aGameCount) collect: [ :start |
			   | block |
			   block := (gameIds
				             copyFrom: start
				             to: (start + aGameCount - 1 min: gameIds size)) asSet.
			   self tagFrequenciesIn:
				   (records select: [ :each | block includes: each gameId ]) ])
		  asArray
]

{ #category : 'queries' }
MistakeDatabase >> tagFrequenciesByMonth [
	"'yyyy-mm' -> tag frequencies that month, to see the trend"

	^ self tagFrequenciesGroupedBy: [ :each |
		  each date yyyymmdd first: 7 ]
]

{ #category : 'queries' }
MistakeDatabase >> tagFrequenciesByPhase [
	"Phase -> tag frequencies in that phase"

	^ self tagFrequenciesGroupedBy: [ :each | each phase ]
]

{ #category : 'private' }
MistakeDatabase >> tagFrequenciesGroupedBy: aBlock [

	| groups |
	groups := OrderedDictionary new.
	records do: [ :each |
			(groups
				 at: (aBlock value: each)
				 ifAbsentPut: [ OrderedCollection new ]) add: each ].
	^ groups collect: [ :each | self tagFrequenciesIn: each ]
]

{ #category : 'private' }
MistakeDatabase >> tagFrequenciesIn: someRecords [
	"Ordered tag id -> count, most frequent first"

	| counts |
	counts := Bag new.
	someRecords do: [ :each | counts addAll: each tagIds ].
	^ counts sortedCounts
		  inject: OrderedDictionary new
		  into: [ :result :each |
				  result
					  at: each value put: each key;
					  yourself ]
]
