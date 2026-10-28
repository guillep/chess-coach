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
	^ (gamesDir files select: [ :file | file extension = 'pgn' ])
		  collect: [ :file | file basenameWithoutExtension ]
]

{ #category : 'accessing' }
GameFileStore >> baseDirectory [

	^ baseDirectory
]

{ #category : 'accessing' }
GameFileStore >> file: aSuffix of: gameId [
	"A companion file of the game, such as games/<id>.analysis.json"

	^ baseDirectory / 'games' / (gameId , '.' , aSuffix)
]

{ #category : 'private' }
GameFileStore >> gameFilePath: gameId [

	^ baseDirectory / (self relativePathOf: gameId)
]

{ #category : 'initialization' }
GameFileStore >> initializeWithBaseDirectory: aPath [

	baseDirectory := aPath asFileReference.
	"Ensure directory structure exists"
	(baseDirectory / 'games') ensureCreateDirectory
]

{ #category : 'loading' }
GameFileStore >> loadPGN: gameId [

	^ (self gameFilePath: gameId) contents
]

{ #category : 'accessing' }
GameFileStore >> relativePathOf: gameId [
	"Path of the game's PGN file, relative to the base directory"

	^ 'games/' , gameId , '.pgn'
]

{ #category : 'saving' }
GameFileStore >> savePGN: aString withId: gameId [

	(self gameFilePath: gameId)
		ensureDelete;
		writeStreamDo: [ :stream | stream nextPutAll: aString ]
]
