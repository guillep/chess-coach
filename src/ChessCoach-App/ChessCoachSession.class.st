"
I hold the chess-coach app state: the Lichess login and the imported games, kept under one directory (~/.chess-coach by default). I announce ChessCoachSessionChanged when the login or the game list changes. Lichess errors (LichessError) are signalled to the caller.
"
Class {
	#name : 'ChessCoachSession',
	#superclass : 'Object',
	#instVars : [
		'importer',
		'announcer',
		'analyser',
		'explorer'
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

{ #category : 'moments' }
ChessCoachSession >> analyser [
	"Analyses games with Stockfish unless another analyser was set"

	^ analyser ifNil: [
		  analyser := GameAnalyser engine: StockfishEngine default ]
]

{ #category : 'moments' }
ChessCoachSession >> analyser: aGameAnalyser [

	analyser := aGameAnalyser
]

{ #category : 'moments' }
ChessCoachSession >> analysisFor: aGameIndexEntry [
	"The engine analysis of the game, computed once per depth and kept next to its PGN"

	| file analysis |
	file := importer fileStore
		        file: 'analysis.json'
		        of: aGameIndexEntry gameId.
	file exists ifTrue: [
			analysis := GameAnalysis fromJSON: file contents.
			analysis depth = self analyser depth ifTrue: [ ^ analysis ] ].
	analysis := self analyser analyse: (self gameFor: aGameIndexEntry).
	file
		ensureDelete;
		writeStreamDo: [ :stream | stream nextPutAll: analysis asJSON ].
	^ analysis
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

{ #category : 'moments' }
ChessCoachSession >> explorer [
	"The Lichess opening explorer, with my token, unless another one was set"

	^ explorer ifNil: [ importer explorerClient ]
]

{ #category : 'moments' }
ChessCoachSession >> explorer: aLichessExplorerClient [

	explorer := aLichessExplorerClient
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

{ #category : 'marks' }
ChessCoachSession >> mark: aGameIndexEntry ply: aPly note: aString [
	"Mark the ply-th half-move as important, replacing any earlier mark on it"

	self
		saveMarks: ((self marksFor: aGameIndexEntry) reject: [ :each |
				 (each at: 'ply') = aPly ]) , { (Dictionary new
				 at: 'ply' put: aPly;
				 at: 'note' put: aString;
				 yourself) }
		for: aGameIndexEntry
]

{ #category : 'marks' }
ChessCoachSession >> marksFor: aGameIndexEntry [
	"My marks on the game: dictionaries with 'ply' and 'note', sorted by ply"

	| file |
	file := importer fileStore
		        file: 'marks.json'
		        of: aGameIndexEntry gameId.
	file exists ifFalse: [ ^ #(  ) ].
	^ STONJSON fromString: file contents
]

{ #category : 'moments' }
ChessCoachSession >> momentsFor: aGameIndexEntry [
	"The game's interesting moments, sorted by ply. Slow the first time (engine analysis): call it off the UI thread."

	| game analysis colors |
	game := self gameFor: aGameIndexEntry.
	analysis := self analysisFor: aGameIndexEntry.
	colors := self myColorsIn: game.
	^ (MomentDetector
		   finders: {
				   (EvaluationJumpFinder on: analysis).
				   (OnlyMoveFinder on: analysis).
				   (OpeningWinRateFinder
					    game: game
					    explorer: self explorer
					    colors: colors) }
		   marksFinder: (MarkedMomentsFinder
				    game: game
				    marks: (self marksFor: aGameIndexEntry))
		   colors: colors) moments
]

{ #category : 'moments' }
ChessCoachSession >> myColorsIn: aGame [
	"The colors I played, by my Lichess username; both when I'm not a player of aGame"

	| colors |
	colors := #( #white #black ) select: [ :color |
			          (aGame metadata
				           at: color asString capitalized
				           ifAbsent: [ nil ])
				          ifNil: [ false ]
				          ifNotNil: [ :name |
				          name sameAs: (self username ifNil: [ '' ]) ] ].
	^ colors ifEmpty: [ #( #white #black ) ]
]

{ #category : 'games' }
ChessCoachSession >> refresh [
	"Download games newer than the newest stored one"

	importer importNewerGames.
	self announceChanged
]

{ #category : 'private' }
ChessCoachSession >> saveMarks: aCollection for: aGameIndexEntry [

	(importer fileStore file: 'marks.json' of: aGameIndexEntry gameId)
		ensureDelete;
		writeStreamDo: [ :stream |
				stream nextPutAll: (STONJSON toString:
								 (aCollection asArray sort: [ :a :b |
										  (a at: 'ply') < (b at: 'ply') ])) ].
	self announceChanged
]

{ #category : 'marks' }
ChessCoachSession >> unmark: aGameIndexEntry ply: aPly [

	self
		saveMarks: ((self marksFor: aGameIndexEntry) reject: [ :each |
				 (each at: 'ply') = aPly ])
		for: aGameIndexEntry
]

{ #category : 'accessing' }
ChessCoachSession >> username [

	^ importer username
]
