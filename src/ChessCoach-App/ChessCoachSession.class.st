"
I hold the chess-coach app state: the Lichess login and the imported games, kept under one directory (~/.chess-coach by default). I announce ChessCoachSessionChanged when the login or the game list changes. Lichess errors (LichessError) are signalled to the caller.
"
Class {
	#name : 'ChessCoachSession',
	#superclass : 'Object',
	#instVars : [
		'importer',
		'announcer'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'instance creation' }
ChessCoachSession class >> default [

	^ self onDirectory: FileLocator home / '.chess-coach'
]

{ #category : 'instance creation' }
ChessCoachSession class >> importer: aLichessGameImporter [

	^ self new
		  initializeWithImporter: aLichessGameImporter;
		  yourself
]

{ #category : 'instance creation' }
ChessCoachSession class >> onDirectory: aFileReference [

	^ self importer: (LichessGameImporter onDirectory: aFileReference)
]

{ #category : 'private' }
ChessCoachSession >> announceChanged [

	announcer announce: (ChessCoachSessionChanged new
			 session: self;
			 yourself)
]

{ #category : 'accessing' }
ChessCoachSession >> announcer [

	^ announcer
]

{ #category : 'login' }
ChessCoachSession >> cancelLogin [

	importer cancelLogin
]

{ #category : 'accessing' }
ChessCoachSession >> gameFor: aGameIndexEntry [

	^ PGNParser new parse:
		  (importer fileStore loadPGN: aGameIndexEntry gameId)
]

{ #category : 'accessing' }
ChessCoachSession >> games [
	"Index entries of the stored games, newest first"

	^ importer games
]

{ #category : 'initialization' }
ChessCoachSession >> initializeWithImporter: aLichessGameImporter [

	importer := aLichessGameImporter.
	announcer := Announcer new
]

{ #category : 'testing' }
ChessCoachSession >> isLoggedIn [

	^ importer isLoggedIn
]

{ #category : 'games' }
ChessCoachSession >> loadMoreGames [
	"Download the page of games older than the oldest stored one"

	importer importOlderGames.
	self announceChanged
]

{ #category : 'login' }
ChessCoachSession >> login [
	"Log in through the browser. Answer whether it succeeded."

	importer login ifFalse: [ ^ false ].
	self announceChanged.
	^ true
]

{ #category : 'login' }
ChessCoachSession >> logout [
	"Delete the token; stored games stay listed"

	importer logout.
	self announceChanged
]

{ #category : 'games' }
ChessCoachSession >> refresh [
	"Download games newer than the newest stored one"

	importer importNewerGames.
	self announceChanged
]

{ #category : 'accessing' }
ChessCoachSession >> username [

	^ importer username
]
