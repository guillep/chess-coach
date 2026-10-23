"
Manages the in-memory game index and coordinates with GameFileStore. Loads the index from disk on startup, scans for new games, and updates the index as games are imported.
"
Class {
	#name : 'GameIndexManager',
	#superclass : 'Object',
	#instVars : [
		'fileStore',
		'index'
	],
	#category : 'ChessCoach-FileStorage',
	#package : 'ChessCoach-FileStorage'
}

{ #category : 'adding' }
GameIndexManager >> addGameEntry: entryDict [
	"Add a new game entry to the index and save to disk"

	| entry |
	entry := GameIndexEntry new.
	entry
		gameId: (entryDict at: 'gameId')
		filepath: (entryDict at: 'filepath')
		dateImported: (entryDict at: 'dateImported')
		source: (entryDict at: 'source')
		players: (entryDict at: 'players' ifAbsent: [ #(  ) ])
		result: (entryDict at: 'result' ifAbsent: [ '' ])
		date: (entryDict at: 'date' ifAbsent: [ '' ]).
	index addEntry: entry.
	self saveIndexToDisk.
	^ entry
]

{ #category : 'accessing' }
GameIndexManager >> fileStore [

	^ fileStore
]

{ #category : 'accessing' }
GameIndexManager >> index [

	^ index
]

{ #category : 'initialization' }
GameIndexManager >> initializeWithFileStore: aGameFileStore [

	fileStore := aGameFileStore.
	index := GameIndex new.
	self loadIndexFromDisk
]

{ #category : 'loading' }
GameIndexManager >> loadIndexFromDisk [
	"Load index.json if it exists, otherwise create empty index"

	| indexFile indexData |
	indexFile := fileStore baseDirectory / 'index.json'.
	indexFile exists ifFalse: [ ^ self ].
	indexData := STON fromString: indexFile readString.
	(indexData at: 'games' ifAbsent: [ #(  ) ]) do: [ :entryDict |
			| entry |
			entry := GameIndexEntry new.
			entry
				gameId: (entryDict at: 'gameId')
				filepath: (entryDict at: 'filepath')
				dateImported: (entryDict at: 'dateImported')
				source: (entryDict at: 'source')
				players: (entryDict at: 'players' ifAbsent: [ #(  ) ])
				result: (entryDict at: 'result' ifAbsent: [ '' ])
				date: (entryDict at: 'date' ifAbsent: [ '' ]).
			index addEntry: entry ]
]

{ #category : 'saving' }
GameIndexManager >> saveIndexToDisk [
	"Write current index to index.json"

	| indexFile indexData |
	indexFile := fileStore baseDirectory / 'index.json'.
	indexData := Dictionary new.
	indexData at: 'games' put: (index entries collect: [ :entry |
				 Dictionary new
					 at: 'gameId' put: entry gameId;
					 at: 'filepath' put: entry filepath;
					 at: 'dateImported' put: entry dateImported;
					 at: 'source' put: entry source;
					 at: 'players' put: entry players;
					 at: 'result' put: entry result;
					 at: 'date' put: entry date;
					 yourself ]).
	indexFile writeString: (STON toString: indexData)
]
