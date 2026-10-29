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
		'analysisQueue',
		'chessComImporter',
		'settings'
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
	"Analyses games with Stockfish as the settings say, unless another analyser was set"

	^ analyser ifNil: [
			  analyser := self configure:
				              (GameAnalyser engine: StockfishEngine default) ]
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
				                   (self configure:
					                    (GameAnalyser engine: StockfishEngine default)) ]
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

{ #category : 'games' }
ChessCoachSession >> canImport [
	"Whether some site is set up to download games from"

	^ self isLoggedIn or: [ self chessComUsername notNil ]
]

{ #category : 'coach' }
ChessCoachSession >> canTimeBox [
	"Time-boxed analyses need my times on at least 10 reviewed moments"

	^ self reviewTimes reviewedMomentCount >= 10
]

{ #category : 'login' }
ChessCoachSession >> cancelLogin [

	importer cancelLogin
]

{ #category : 'chess.com' }
ChessCoachSession >> chessComAPIClient: aChessComAPIClient [
	"Use another Chess.com client (tests use a stub)"

	chessComImporter := ChessComGameImporter
		                    apiClient: aChessComAPIClient
		                    fileStore: importer fileStore
		                    indexManager: importer indexManager
]

{ #category : 'chess.com' }
ChessCoachSession >> chessComImporter [
	"Imports my Chess.com games into the same files and index as the Lichess games"

	^ chessComImporter ifNil: [
			  chessComImporter := ChessComGameImporter
				                      apiClient: ChessComAPIClient new
				                      fileStore: importer fileStore
				                      indexManager: importer indexManager ]
]

{ #category : 'chess.com' }
ChessCoachSession >> chessComUsername [
	"My Chess.com username, or nil when I haven't set one"

	^ self chessComImporter username
]

{ #category : 'chess.com' }
ChessCoachSession >> chessComUsername: aStringOrNil [
	"Chess.com's game data is public, so a username is all it takes; nil forgets it"

	self chessComImporter username: aStringOrNil.
	self announceChanged
]

{ #category : 'coach' }
ChessCoachSession >> classifier [
	"Classifies my answers with the Ollama model of the settings, unless another classifier was set"

	^ classifier ifNil: [
			  classifier := AnswerClassifier
				                client: (OllamaClient new
						                 baseUrl: self settings ollamaUrl;
						                 model: self settings ollamaModel;
						                 yourself)
				                taxonomy: MistakeTaxonomy default ]
]

{ #category : 'coach' }
ChessCoachSession >> classifier: anAnswerClassifier [

	classifier := anAnswerClassifier
]

{ #category : 'settings' }
ChessCoachSession >> configure: aGameAnalyser [
	"Give aGameAnalyser the depth, MultiPV and Stockfish path of the settings"

	aGameAnalyser
		depth: self settings depth;
		multiPV: self settings multiPV.
	aGameAnalyser engine path: self settings stockfishPath.
	^ aGameAnalyser
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

{ #category : 'coach' }
ChessCoachSession >> finishMarking: aCoachReview of: aGameIndexEntry [
	"End the marking pass: merge my marks with the heuristic moments, and plan the moments that fit the time box if there is one. Slow when the game is not analysed yet: call it off the UI thread."

	aCoachReview
		finishMarkingWith: (self analysisFor: aGameIndexEntry)
		moments:
		(self momentsFor: aGameIndexEntry marks: aCoachReview marks).
	aCoachReview planWith: self reviewTimes
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

{ #category : 'games' }
ChessCoachSession >> gamesWithSpeed: aSpeedOrNil [
	"Stored games of one speed (bullet, blitz, …), newest first; all of them when nil.
	Entries indexed before speeds were recorded get theirs from the PGN once, and the index is saved."

	| games backfilled |
	aSpeedOrNil ifNil: [ ^ self games ].
	games := self games.
	backfilled := false.
	games do: [ :entry |
			entry speed ifNil: [
					entry speed: (self gameFor: entry) speed.
					backfilled := true ] ].
	backfilled ifTrue: [ importer indexManager saveIndexToDisk ].
	^ games select: [ :entry | entry speed = aSpeedOrNil ]
]

{ #category : 'initialization' }
ChessCoachSession >> initializeWithImporter: aLichessGameImporter [

	importer := aLichessGameImporter.
	announcer := Announcer new
]

{ #category : 'moments' }
ChessCoachSession >> isAnalysed: aGameIndexEntry [
	"Whether the game has its Stockfish analysis. It is kept even when the analysis settings change."

	^ (self analysisFileFor: aGameIndexEntry) exists
]

{ #category : 'testing' }
ChessCoachSession >> isLoggedIn [

	^ importer isLoggedIn
]

{ #category : 'games' }
ChessCoachSession >> loadMoreGames [
	"Download older games, as many per site as the settings say: from Lichess when logged in, from Chess.com when its username is set"

	self isLoggedIn ifTrue: [
			importer
				pageSize: self settings gamesPerLoad;
				importOlderGames ].
	self chessComUsername ifNotNil: [
		self chessComImporter importOlderGames: self settings gamesPerLoad ].
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
ChessCoachSession >> marksFor: aGameIndexEntry [
	"My marks on the game: dictionaries with 'ply' and 'note', sorted by ply"

	| file |
	file := importer fileStore
		        file: 'marks.json'
		        of: aGameIndexEntry gameId.
	file exists ifFalse: [ ^ #(  ) ].
	^ STONJSON fromString: file contents
]

{ #category : 'private' }
ChessCoachSession >> migrateOldReviewOf: aGameIndexEntry [
	"A review.json and marks.json saved before reviews had numbers become review-1.json, with every detected moment"

	| old marks review |
	old := importer fileStore
		       file: 'review.json'
		       of: aGameIndexEntry gameId.
	marks := importer fileStore
		         file: 'marks.json'
		         of: aGameIndexEntry gameId.
	(old exists or: [ marks exists ]) ifFalse: [ ^ self ].
	review := self newCoachReviewFor: aGameIndexEntry.
	old exists ifTrue: [
			review
				restoreFromJSON: old contents
				analysis: [ self analysisFor: aGameIndexEntry ] ].
	marks exists ifTrue: [
			(STONJSON fromString: marks contents) do: [ :each |
				review mark: (each at: 'ply') note: (each at: 'note') ] ].
	old exists ifTrue: [ self finishMarking: review of: aGameIndexEntry ].
	self saveReviewFile: review.
	old ensureDelete.
	marks ensureDelete
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
ChessCoachSession >> momentsFor: aGameIndexEntry marks: someMarks [
	"The game's interesting moments, merged with someMarks (dictionaries with 'ply' and 'note'), sorted by ply. Slow the first time (engine analysis): call it off the UI thread."

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
					    colors: colors).
				   (LongThinkFinder on: game) }
		   marksFinder: (MarkedMomentsFinder game: game marks: someMarks)
		   colors: colors) moments
]

{ #category : 'moments' }
ChessCoachSession >> myColorsIn: aGame [
	"The colors I played, by my Lichess or Chess.com username; both when I'm not a player of aGame"

	| names colors |
	names := {
		         self username.
		         self chessComUsername } reject: [ :each | each isNil ].
	colors := #( #white #black ) select: [ :color |
			          (aGame metadata
				           at: color asString capitalized
				           ifAbsent: [ nil ])
				          ifNil: [ false ]
				          ifNotNil: [ :name |
				          names anySatisfy: [ :each | name sameAs: each ] ] ].
	^ colors ifEmpty: [ #( #white #black ) ]
]

{ #category : 'private' }
ChessCoachSession >> newCoachReviewFor: aGameIndexEntry [
	"A review that saves itself after every change and rebuilds the mistake database when a moment is left"

	| review |
	review := CoachReview
		          gameId: aGameIndexEntry gameId
		          game: (self gameFor: aGameIndexEntry)
		          engine: self analyser engine
		          classifier: self classifier.
	review depth: self settings depth.
	review whenChangedDo: [ self saveReviewFile: review ].
	review whenMomentClosedDo: [ self saveReview: review ].
	^ review
]

{ #category : 'coach' }
ChessCoachSession >> newReviewFor: aGameIndexEntry [
	"Start the next review of the game, in its manual marking pass"

	^ self newReviewFor: aGameIndexEntry timeBox: nil
]

{ #category : 'coach' }
ChessCoachSession >> newReviewFor: aGameIndexEntry timeBox: minutesOrNil [
	"Start the next review of the game, in its manual marking pass, optionally limited to minutesOrNil"

	| review |
	review := self newCoachReviewFor: aGameIndexEntry.
	review number: ((self reviewsFor: aGameIndexEntry)
			 inject: 0
			 into: [ :max :each | max max: each number ]) + 1.
	review timeBox: minutesOrNil.
	self saveReviewFile: review.
	self announceChanged.
	^ review
]

{ #category : 'private' }
ChessCoachSession >> rebuiltMistakeDatabase [
	"The reviews are the source of truth: collect the mistakes saved in every games/<id>.review-<n>.json. A moment reviewed in several reviews of a game counts once, from the most recent one."

	| latest |
	latest := Dictionary new.
	((importer fileStore baseDirectory / 'games' filesMatching:
			  '*.review-*.json') collect: [ :file |
			 STONJSON fromString: file contents ]) asArray
		sort: [ :a :b | (a at: 'number') < (b at: 'number') ];
		do: [ :review |
				(review at: 'mistakes') do: [ :each |
							| record |
							record := MistakeRecord fromDictionary: each.
							latest at: record gameId -> record ply put: record ] ].
	^ MistakeDatabase withRecords: latest values
]

{ #category : 'games' }
ChessCoachSession >> refresh [
	"Download games newer than the newest stored one, from every site set up"

	self isLoggedIn ifTrue: [ importer importNewerGames ].
	self chessComUsername ifNotNil: [
		self chessComImporter importNewerGames ].
	self announceChanged
]

{ #category : 'private' }
ChessCoachSession >> review: aGameIndexEntry from: aJSONString [

	^ (self newCoachReviewFor: aGameIndexEntry)
		  restoreFromJSON: aJSONString
		  analysis: [ self analysisFor: aGameIndexEntry ];
		  yourself
]

{ #category : 'private' }
ChessCoachSession >> reviewFilesOf: aGameId [

	^ importer fileStore baseDirectory / 'games' filesMatching:
		  aGameId , '.review-*.json'
]

{ #category : 'coach' }
ChessCoachSession >> reviewTimes [
	"How long my reviews take, from every saved review"

	^ ReviewTimes fromReviewDictionaries:
		  ((importer fileStore baseDirectory / 'games' filesMatching:
			    '*.review-*.json') collect: [ :file |
			   STONJSON fromString: file contents ])
]

{ #category : 'coach' }
ChessCoachSession >> reviewsFor: aGameIndexEntry [
	"The game's coach reviews (games/<id>.review-<n>.json), oldest first. A review.json and marks.json from before reviews had numbers become review 1."

	self migrateOldReviewOf: aGameIndexEntry.
	^ ((self reviewFilesOf: aGameIndexEntry gameId) collect: [ :file |
		   self review: aGameIndexEntry from: file contents ]) asArray
		  sort: [ :a :b | a number < b number ]
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

	(importer fileStore
		 file: 'review-' , aCoachReview number printString , '.json'
		 of: aCoachReview gameId)
		ensureDelete;
		writeStreamDo: [ :stream | stream nextPutAll: aCoachReview asJSON ]
]

{ #category : 'settings' }
ChessCoachSession >> settingChanged: aKey [
	"Apply a changed setting to the engines and the classifier already created, then announce it. Stored analyses are kept."

	(#( 'depth' 'multiPV' 'stockfishPath' ) includes: aKey) ifTrue: [
			{
				self analyser.
				self analysisQueue analyser } do: [ :each | self configure: each ] ].
	(#( 'ollamaUrl' 'ollamaModel' ) includes: aKey) ifTrue: [
			self classifier client
				baseUrl: self settings ollamaUrl;
				model: self settings ollamaModel ].
	announcer announce: (ChessCoachSettingsChanged new
			 key: aKey;
			 yourself)
]

{ #category : 'settings' }
ChessCoachSession >> settings [
	"My preferences, in settings.json next to the games"

	^ settings ifNil: [
			  settings := ChessCoachSettings onFile:
				              importer fileStore baseDirectory / 'settings.json'.
			  settings whenChangedDo: [ :key | self settingChanged: key ].
			  settings ]
]

{ #category : 'accessing' }
ChessCoachSession >> username [

	^ importer username
]

{ #category : 'chess.com' }
ChessCoachSession >> validateChessComUsername: aString [
	"Remember aString as my Chess.com username if Chess.com knows it; answer whether it does"

	(self chessComImporter apiClient playerExists: aString trimBoth)
		ifFalse: [ ^ false ].
	self chessComUsername: aString trimBoth.
	^ true
]
