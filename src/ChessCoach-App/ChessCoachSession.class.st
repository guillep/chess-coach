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
		'explorer',
		'classifier',
		'analysisQueue'
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
ChessCoachSession >> analyse: aGameIndexEntry with: aGameAnalyser onProgress: aBlock [
	"Analyse the game with aGameAnalyser and store the result next to its PGN"

	| analysis |
	analysis := aGameAnalyser
		            analyse: (self gameFor: aGameIndexEntry)
		            onProgress: aBlock.
	(self analysisFileFor: aGameIndexEntry)
		ensureDelete;
		writeStreamDo: [ :stream | stream nextPutAll: analysis asJSON ].
	^ analysis
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

{ #category : 'private' }
ChessCoachSession >> analysisFileFor: aGameIndexEntry [

	^ importer fileStore file: 'analysis.json' of: aGameIndexEntry gameId
]

{ #category : 'moments' }
ChessCoachSession >> analysisFor: aGameIndexEntry [
	"The engine analysis of the game, computed once per depth and kept next to its PGN"

	(self isAnalysed: aGameIndexEntry) ifTrue: [
			^ GameAnalysis fromJSON:
				  (self analysisFileFor: aGameIndexEntry) contents ].
	^ self
		  analyse: aGameIndexEntry
		  with: self analyser
		  onProgress: [ :done :total |  ]
]

{ #category : 'moments' }
ChessCoachSession >> analysisQueue [
	"Background analysis with its own Stockfish, so the coach's engine stays free"

	^ analysisQueue ifNil: [
			  analysisQueue := AnalysisQueue
				                   session: self
				                   analyser:
					                   ((GameAnalyser engine: StockfishEngine default)
						                    depth: self analyser depth;
						                    yourself) ]
]

{ #category : 'moments' }
ChessCoachSession >> analysisQueue: anAnalysisQueue [

	analysisQueue := anAnalysisQueue
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

{ #category : 'coach' }
ChessCoachSession >> classifier [
	"Classifies my answers with the local Ollama model unless another classifier was set"

	^ classifier ifNil: [
			  classifier := AnswerClassifier
				                client: OllamaClient new
				                taxonomy: MistakeTaxonomy default ]
]

{ #category : 'coach' }
ChessCoachSession >> classifier: anAnswerClassifier [

	classifier := anAnswerClassifier
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

{ #category : 'moments' }
ChessCoachSession >> isAnalysed: aGameIndexEntry [
	"Whether a stored analysis exists at the analyser's depth"

	| file |
	file := self analysisFileFor: aGameIndexEntry.
	^ file exists and: [
		  (GameAnalysis fromJSON: file contents) depth = self analyser depth ]
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

{ #category : 'coach' }
ChessCoachSession >> mistakeDatabase [
	"My mistakes from all finished reviews"

	^ self mistakesFile exists
		  ifTrue: [ MistakeDatabase fromJSON: self mistakesFile contents ]
		  ifFalse: [ MistakeDatabase withRecords: #(  ) ]
]

{ #category : 'private' }
ChessCoachSession >> mistakesFile [

	^ importer fileStore baseDirectory / 'mistakes.json'
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

{ #category : 'private' }
ChessCoachSession >> rebuiltMistakeDatabase [
	"The reviews are the source of truth: collect the mistakes saved in every games/<id>.review.json"

	^ MistakeDatabase withRecords:
		  ((importer fileStore baseDirectory / 'games' filesMatching:
			    '*.review.json') flatCollect: [ :file |
				   ((STONJSON fromString: file contents) at: 'mistakes') collect: [
					   :each | MistakeRecord fromDictionary: each ] ])
]

{ #category : 'games' }
ChessCoachSession >> refresh [
	"Download games newer than the newest stored one"

	importer importNewerGames.
	self announceChanged
]

{ #category : 'coach' }
ChessCoachSession >> reviewFor: aGameIndexEntry [
	"The coach review of the game, continuing the saved one if any. It saves itself after every change and rebuilds the mistake database when a moment is closed. Slow the first time (engine analysis): call it off the UI thread."

	| review file |
	review := CoachReview
		          gameId: aGameIndexEntry gameId
		          game: (self gameFor: aGameIndexEntry)
		          analysis: (self analysisFor: aGameIndexEntry)
		          moments: (self momentsFor: aGameIndexEntry)
		          engine: self analyser engine
		          classifier: self classifier.
	file := importer fileStore
		        file: 'review.json'
		        of: aGameIndexEntry gameId.
	file exists
		ifTrue: [ review restoreFromJSON: file contents ]
		ifFalse: [ review reviewMore ].
	review whenChangedDo: [ self saveReviewFile: review ].
	review whenMomentClosedDo: [ self saveReview: review ].
	^ review
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

{ #category : 'coach' }
ChessCoachSession >> saveReview: aCoachReview [
	"Save the review next to its game and rebuild the mistake database from all reviews"

	self saveReviewFile: aCoachReview.
	self mistakesFile
		ensureDelete;
		writeStreamDo: [ :stream |
			stream nextPutAll: self rebuiltMistakeDatabase asJSON ].
	self announceChanged
]

{ #category : 'private' }
ChessCoachSession >> saveReviewFile: aCoachReview [

	(importer fileStore file: 'review.json' of: aCoachReview gameId)
		ensureDelete;
		writeStreamDo: [ :stream | stream nextPutAll: aCoachReview asJSON ]
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
