"
Manages file I/O for chess games. Stores individual game files as JSON (PGN + metadata) in ~/Documents/chess-coach/games/ and provides load/save operations.
"
Class {
	#name : 'GameFileStore',
	#superclass : 'Object',
	#instVars : [
		'baseDirectory'
	],
	#category : 'ChessCoach-FileStorage',
	#package : 'ChessCoach-FileStorage'
}

{ #category : 'querying' }
GameFileStore >> allGameIds [
	"Scan games directory for all game files"

	| gamesDir |
	gamesDir := baseDirectory / 'games'.
	gamesDir exists ifFalse: [ ^ #(  ) ].
	^ (gamesDir allFiles select: [ :file | file extension = 'json' ])
		  collect: [ :file | file basenameWithoutExtension ]
]

{ #category : 'accessing' }
GameFileStore >> baseDirectory [

	^ baseDirectory
]

{ #category : 'private' }
GameFileStore >> gameFilePath: gameId [

	^ baseDirectory / 'games' / (gameId , '.json')
]

{ #category : 'initialization' }
GameFileStore >> initializeWithBaseDirectory: aPath [

	baseDirectory := aPath asFileReference.
	"Ensure directory structure exists"
	(baseDirectory / 'games') ensureCreateDirectory
]

{ #category : 'loading' }
GameFileStore >> loadGame: gameId [
	"Load game using STON deserialization"

	| file jsonContent |
	file := self gameFilePath: gameId.
	file exists ifFalse: [ ^ nil ].
	jsonContent := file readString.
	^ STON fromString: jsonContent
]

{ #category : 'saving' }
GameFileStore >> saveGame: aGameDict withId: gameId [
	"Save game using STON serialization"

	| file |
	file := self gameFilePath: gameId.
	file writeString: (STON toString: aGameDict).
	^ file path
]
