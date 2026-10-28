"
Imports a Chess.com player's standard-chess games into the same game files and index as the Lichess importer, one monthly archive at a time, newest first. The username is kept in a file (chesscom-username) next to the games.
"
Class {
	#name : 'ChessComGameImporter',
	#superclass : 'Object',
	#instVars : [
		'apiClient',
		'usernameFile',
		'fileStore',
		'indexManager'
	],
	#category : 'ChessCoach-ChessComImport',
	#package : 'ChessCoach-ChessComImport'
}

{ #category : 'instance creation' }
ChessComGameImporter class >> apiClient: aChessComAPIClient fileStore: aGameFileStore indexManager: aGameIndexManager [

	^ self new
		  setAPIClient: aChessComAPIClient
		  fileStore: aGameFileStore
		  indexManager: aGameIndexManager
]

{ #category : 'private' }
ChessComGameImporter >> gameIdOf: gameData [
	"chesscom-<number> from the game URL, so ids never clash with Lichess ones"

	^ 'chesscom-' , ((gameData at: 'url') substrings: '/') last
]

{ #category : 'private' }
ChessComGameImporter >> importArchive: anArchiveUrl [
	"Import the standard-chess games of one archive that are not in the index yet"

	^ (apiClient gamesInArchive: anArchiveUrl)
		  select: [ :gameData |
				  (gameData at: 'rules' ifAbsent: [ 'chess' ]) = 'chess' and: [
					  (indexManager index findById: (self gameIdOf: gameData)) isNil ] ]
		  thenCollect: [ :gameData | self saveGameFromData: gameData ]
]

{ #category : 'importing' }
ChessComGameImporter >> importNewerGames [
	"Import the games of the current month I don't have yet. Answer the new entries."

	| archives |
	archives := apiClient archivesOf: self username.
	archives ifEmpty: [ ^ #(  ) ].
	^ self importArchive: archives first
]

{ #category : 'importing' }
ChessComGameImporter >> importOlderGames [
	"Import the newest monthly archive that still has games I don't have. Answer the new entries."

	(apiClient archivesOf: self username) do: [ :archive |
			| entries |
			entries := self importArchive: archive.
			entries ifNotEmpty: [ ^ entries ] ].
	^ #(  )
]

{ #category : 'accessing' }
ChessComGameImporter >> ownGames [
	"My Chess.com games' index entries, newest first"

	^ (indexManager index entries select: [ :each |
		   each source = 'chess.com' ]) asArray sort: [ :a :b |
		  a createdAt > b createdAt ]
]

{ #category : 'private' }
ChessComGameImporter >> resultIn: gameData [

	((gameData at: 'white') at: 'result') = 'win' ifTrue: [ ^ '1-0' ].
	((gameData at: 'black') at: 'result') = 'win' ifTrue: [ ^ '0-1' ].
	^ '1/2-1/2'
]

{ #category : 'private' }
ChessComGameImporter >> saveGameFromData: gameData [
	"Save one game from a Chess.com archive as PGN and index it. Answer its index entry."

	| gameId createdAt |
	gameId := self gameIdOf: gameData.
	createdAt := (gameData at: 'end_time') * 1000.
	fileStore savePGN: (gameData at: 'pgn') withId: gameId.
	^ indexManager addGameEntry: (Dictionary new
			   at: 'gameId' put: gameId;
			   at: 'filepath' put: (fileStore relativePathOf: gameId);
			   at: 'dateImported' put: DateAndTime now asString;
			   at: 'source' put: 'chess.com';
			   at: 'players' put: (#( 'white' 'black' ) collect: [ :color |
						    (gameData at: color) at: 'username' ]);
			   at: 'result' put: (self resultIn: gameData);
			   at: 'date'
			   put:
				   (DateAndTime fromUnixTime: createdAt // 1000) asDate yyyymmdd;
			   at: 'createdAt' put: createdAt;
			   at: 'speed' put: (Game speedForTimeControl:
						    (gameData at: 'time_control' ifAbsent: [ nil ]));
			   yourself)
]

{ #category : 'initialization' }
ChessComGameImporter >> setAPIClient: aChessComAPIClient fileStore: aGameFileStore indexManager: aGameIndexManager [

	apiClient := aChessComAPIClient.
	fileStore := aGameFileStore.
	indexManager := aGameIndexManager.
	usernameFile := aGameFileStore baseDirectory / 'chesscom-username'
]

{ #category : 'accessing' }
ChessComGameImporter >> username [
	"My Chess.com username, or nil when not set"

	usernameFile exists ifFalse: [ ^ nil ].
	^ usernameFile contents trimBoth ifEmpty: [ nil ]
]

{ #category : 'accessing' }
ChessComGameImporter >> username: aStringOrNil [
	"Remember my Chess.com username; nil or empty forgets it (imported games stay)"

	usernameFile ensureDelete.
	aStringOrNil isEmptyOrNil ifTrue: [ ^ self ].
	usernameFile parent ensureCreateDirectory.
	usernameFile writeStreamDo: [ :stream |
		stream nextPutAll: aStringOrNil trimBoth ]
]
