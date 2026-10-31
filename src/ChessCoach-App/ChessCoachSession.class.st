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
		'settings',
		'notifications',
		'scheduler',
		'updater',
		'availableUpdate'
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
	"The engine analysis of the game, computed once and kept next to its PGN"

	^ self analysisFor: aGameIndexEntry onProgress: [ :done :total |  ]
]

{ #category : 'moments' }
ChessCoachSession >> analysisFor: aGameIndexEntry onProgress: aBlock [
	"The engine analysis of the game, computed once and kept next to its PGN. aBlock receives (plies done, total) while it is computed. Without Stockfish, an analysis with no engine lines (not stored)."

	(self isAnalysed: aGameIndexEntry) ifTrue: [
			^ GameAnalysis fromJSON:
				  (self analysisFileFor: aGameIndexEntry) contents ].
	self isEngineAvailable ifFalse: [
		^ GameAnalysis withoutEngineFor: (self gameFor: aGameIndexEntry) ].
	^ self
		  analyse: aGameIndexEntry
		  with: self analyser
		  onProgress: aBlock
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

{ #category : 'accessing' }
ChessCoachSession >> appVersion [
	"The version of the chess-coach repository in the style of git describe: nearest tag, commits since it and the commit. Without a tag, only the commit."

	| repository head distance |
	repository := IceRepository registry
		              detect: [ :each | each name = 'chess-coach' ]
		              ifNone: [ ^ 'Repository version not found' ].
	head := repository head commit.
	distance := 0.
	head commitsDo: [ :commit |
			commit tags ifNotEmpty: [ :tags |
					^ '{1}-{2}-g{3}' format: {
							  tags first name.
							  distance.
							  head shortId } ].
			distance := distance + 1 ].
	^ head shortId
]

{ #category : 'updates' }
ChessCoachSession >> availableUpdate [
	"The release tag to update to, or nil"

	^ availableUpdate
]

{ #category : 'opening trees' }
ChessCoachSession >> buildOpeningTree: anOpeningTree [
	"Count the matching games and save the tree, keeping the database data already fetched. Slow: call it off the UI thread."

	| databases |
	databases := anOpeningTree databases.
	anOpeningTree reset.
	(self gamesMatching: anOpeningTree) do: [ :each |
			anOpeningTree
				addGame: each
				points: (self pointsIn: each as: anOpeningTree color) ].
	anOpeningTree finishBuildingOn: Date today yyyymmdd.
	anOpeningTree restoreDatabases: databases.
	self saveOpeningTree: anOpeningTree
]

{ #category : 'games' }
ChessCoachSession >> canImport [
	"Whether some site is set up to download games from: a Lichess or Chess.com username"

	^ self username notNil or: [ self chessComUsername notNil ]
]

{ #category : 'coach' }
ChessCoachSession >> canTimeBox [
	"Time-boxed analyses need my times on at least 10 reviewed moments"

	^ self reviewTimes reviewedMomentCount >= 10
]

{ #category : 'opening trees' }
ChessCoachSession >> canUseDatabase [
	"The explorer needs a Lichess login"

	^ explorer notNil or: [ self isLoggedIn ]
]

{ #category : 'login' }
ChessCoachSession >> cancelLogin [

	importer cancelLogin
]

{ #category : 'notifications' }
ChessCoachSession >> checkForNewGames [
	"Download new games from every site with a username, as Refresh does, and notify them in one notification, replaced by the next check. A site that fails gets one error notification, replaced while it keeps failing"

	| entries |
	entries := OrderedCollection new.
	self username ifNotNil: [
			entries addAll:
				(self importFrom: 'Lichess' doing: [ importer importNewerGames ]) ].
	self chessComUsername ifNotNil: [
			entries addAll: (self
					 importFrom: 'Chess.com'
					 doing: [ self chessComImporter importNewerGames ]) ].
	entries ifEmpty: [ ^ self ].
	self notifications post: (ChessCoachNotification
			 key: 'new-games'
			 kind: #newGames
			 title: (entries size = 1
					  ifTrue: [ '1 new game' ]
					  ifFalse: [ entries size printString , ' new games' ])
			 text: 'Downloaded from your accounts').
	self announceChanged
]

{ #category : 'updates' }
ChessCoachSession >> checkForUpdate [
	"Look for a newer release and notify it; the notification also tells the window to show its Update button"

	availableUpdate := self updater availableUpdate.
	availableUpdate ifNil: [ ^ self ].
	self notifications post: (ChessCoachNotification
			 key: 'update-' , availableUpdate
			 kind: #update
			 title: 'Update available'
			 text: availableUpdate , ' can be installed')
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

{ #category : 'opening trees' }
ChessCoachSession >> dateOf: aGame [
	"The game's date as 'yyyy-mm-dd'"

	^ (aGame metadata
		   at: 'UTCDate'
		   ifAbsent: [ aGame metadata at: 'Date' ifAbsent: [ '' ] ])
		  copyReplaceAll: '.'
		  with: '-'
]

{ #category : 'degraded mode' }
ChessCoachSession >> degradedModeNotes [
	"One sentence per missing dependency, saying what is off. Slow (checks Ollama): call it off the UI thread."

	| notes |
	notes := OrderedCollection new.
	self isEngineAvailable ifFalse: [
			notes add:
				'Stockfish not found: moments come only from your marks and long thinks.' ].
	self isClassifierAvailable ifFalse: [
			notes add:
				'Ollama or its model not available: choose the tags yourself.' ].
	^ notes
]

{ #category : 'opening trees' }
ChessCoachSession >> deleteOpeningTree: anOpeningTree [

	(self openingTreesDirectory / (anOpeningTree id , '.json'))
		ensureDelete
]

{ #category : 'coach' }
ChessCoachSession >> deleteReview: aCoachReview [
	"Delete the review's file and rebuild the mistake database without it"

	(importer fileStore
		 file: 'review-' , aCoachReview number printString , '.json'
		 of: aCoachReview gameId) ensureDelete.
	self mistakesFile
		ensureDelete;
		writeStreamDo: [ :stream |
			stream nextPutAll: self rebuiltMistakeDatabase asJSON ].
	self announceChanged
]

{ #category : 'opening trees' }
ChessCoachSession >> entriesMatching: anOpeningTree collect: aBlock [
	"aBlock receives the index entry and the parsed game of each game that passes the tree's filters. Games I didn't play are left out."

	| matching |
	matching := OrderedCollection new.
	(self gamesWithSpeed: anOpeningTree speed) do: [ :entry |
			| game |
			game := self gameFor: entry.
			((self myColorsIn: game) asArray = { anOpeningTree color } and: [
				 anOpeningTree matchesDate: (self dateOf: game) ]) ifTrue: [
				matching add: (aBlock value: entry value: game) ] ].
	^ matching
]

{ #category : 'opening trees' }
ChessCoachSession >> entriesOf: anOpeningTree at: aKey [
	"The index entries of the matching games that reach the position, found by replaying them"

	^ (self entriesMatching: anOpeningTree collect: [ :entry :game |
			   (self game: game reaches: aKey)
				   ifTrue: [ entry ]
				   ifFalse: [ nil ] ]) reject: [ :each | each isNil ]
]

{ #category : 'errors' }
ChessCoachSession >> errorLog [
	"Errors the app showed instead of opening a debugger, newest last"

	^ importer fileStore baseDirectory / 'errors.log'
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

{ #category : 'opening trees' }
ChessCoachSession >> fetchDatabaseOf: anOpeningNode in: anOpeningTree [
	"Ask the explorer about the position and keep the answer in the tree. Slow: call it off the UI thread."

	anOpeningNode database: (anOpeningTree databaseSource = 'masters'
			 ifTrue: [ self explorer mastersMovesFor: anOpeningNode fen ]
			 ifFalse: [
					 self explorer
						 lichessMovesFor: anOpeningNode fen
						 speed: anOpeningTree databaseSpeed
						 ratings: anOpeningTree ratings ]).
	self saveOpeningTree: anOpeningTree
]

{ #category : 'coach' }
ChessCoachSession >> finishMarking: aCoachReview of: aGameIndexEntry [

	^ self
		  finishMarking: aCoachReview
		  of: aGameIndexEntry
		  onProgress: [ :done :total |  ]
]

{ #category : 'coach' }
ChessCoachSession >> finishMarking: aCoachReview of: aGameIndexEntry onProgress: aBlock [
	"See finishMarking:of:onProgress:onStep:"

	^ self
		  finishMarking: aCoachReview
		  of: aGameIndexEntry
		  onProgress: aBlock
		  onStep: [ :description |  ]
]

{ #category : 'coach' }
ChessCoachSession >> finishMarking: aCoachReview of: aGameIndexEntry onProgress: aBlock onStep: aStepBlock [
	"End the marking pass: merge my marks with the heuristic moments, and plan the moments that fit the time box if there is one. aBlock receives (plies done, total) while the game is analysed; aStepBlock receives a description of each later step. Answer the sentences explaining heuristics that could not run. Slow when the game is not analysed yet: call it off the UI thread."

	| problems analysis moments |
	problems := OrderedCollection new.
	analysis := self analysisFor: aGameIndexEntry onProgress: aBlock.
	aStepBlock value: ((explorer notNil or: [ self isLoggedIn ])
			 ifTrue: [ 'Comparing your opening with the Lichess database…' ]
			 ifFalse: [ 'Finding the important moments…' ]).
	moments := self
		           momentsFor: aGameIndexEntry
		           marks: aCoachReview marks
		           problems: problems.
	aCoachReview finishMarkingWith: analysis moments: moments.
	aCoachReview planWith: self reviewTimes.
	^ problems
]

{ #category : 'opening trees' }
ChessCoachSession >> game: aGame reaches: aKey [

	| position |
	position := aGame initialPosition.
	(OpeningTree keyOf: position) = aKey ifTrue: [ ^ true ].
	aGame moves do: [ :move |
			position := position move: move san.
			(OpeningTree keyOf: position) = aKey ifTrue: [ ^ true ] ].
	^ false
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

{ #category : 'opening trees' }
ChessCoachSession >> gamesMatching: anOpeningTree [
	"The parsed games that pass the tree's filters"

	^ self
		  entriesMatching: anOpeningTree
		  collect: [ :entry :game | game ]
]

{ #category : 'games' }
ChessCoachSession >> gamesWithSpeed: aSpeedOrNil [
	"Stored games of one speed (bullet, blitz, …), newest first; all of them when nil.
	Entries indexed before speeds were recorded get theirs from the PGN once, and the index is saved."

	| games backfilled |
	games := self games.
	backfilled := false.
	games do: [ :entry |
			entry speed ifNil: [
					entry speed: (self gameFor: entry) speed.
					backfilled := true ] ].
	backfilled ifTrue: [ importer indexManager saveIndexToDisk ].
	aSpeedOrNil ifNil: [ ^ games ].
	^ games select: [ :entry | entry speed = aSpeedOrNil ]
]

{ #category : 'notifications' }
ChessCoachSession >> importFrom: siteName doing: aBlock [
	"Answer the entries aBlock imports. On an error, notify it under the site's key (unexpected errors also go to errors.log) and answer none"

	^ aBlock
		  on: Error
		  do: [ :error |
				  ((error isKindOf: LichessError) or: [
					   error isKindOf: NetworkError ]) ifFalse: [
					  self logError: error ].
				  self notifications post: (ChessCoachNotification
						   key: 'error-' , siteName
						   kind: #error
						   title: siteName , ' check failed'
						   text:
						   (error messageText ifNil: [ error class name ]) asString).
				  #(  ) ]
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

{ #category : 'degraded mode' }
ChessCoachSession >> isClassifierAvailable [
	"Whether Ollama answers and has the chosen model. Slow (network): call it off the UI thread."

	^ [
		  self classifier client installedModels includes:
			  self settings ollamaModel ]
		  on: NetworkError , ZnHttpUnsuccessful
		  do: [ :error | false ]
]

{ #category : 'degraded mode' }
ChessCoachSession >> isEngineAvailable [

	^ self analyser engine isAvailable
]

{ #category : 'settings' }
ChessCoachSession >> isFirstRun [
	"The setup wizard has never been finished and there are no games yet"

	^ (self settings at: 'setupDone') not and: [ self games isEmpty ]
]

{ #category : 'testing' }
ChessCoachSession >> isLoggedIn [

	^ importer isLoggedIn
]

{ #category : 'opening trees' }
ChessCoachSession >> lichessRatingAt: aSpeed [
	"My Lichess rating in my newest game of that speed, or nil without one"

	self username ifNil: [ ^ nil ].
	(self gamesWithSpeed: aSpeed) do: [ :entry |
			| metadata |
			metadata := (self gameFor: entry) metadata.
			#( 'White' 'Black' ) do: [ :color |
					((metadata at: color ifAbsent: [ '' ]) sameAs: self username)
						ifTrue: [
								(metadata at: color , 'Elo' ifAbsent: [ nil ]) ifNotNil: [
									:elo | elo isAllDigits ifTrue: [ ^ elo asInteger ] ] ] ] ].
	^ nil
]

{ #category : 'accessing' }
ChessCoachSession >> lichessUsername: aStringOrNil [
	"Lichess games are public, so a username is enough to download them; nil forgets it"

	importer username: aStringOrNil.
	self announceChanged
]

{ #category : 'games' }
ChessCoachSession >> loadMoreGames [
	"Download older games, as many per site as the settings say, from every site with a username"

	self username ifNotNil: [
			importer
				pageSize: self settings gamesPerLoad;
				importOlderGames ].
	self chessComUsername ifNotNil: [
		self chessComImporter importOlderGames: self settings gamesPerLoad ].
	self announceChanged
]

{ #category : 'errors' }
ChessCoachSession >> logError: anError [
	"Append anError with its stack to errors.log, for bug reports"

	| stack |
	stack := String streamContents: [ :stream |
			         anError signalerContext ifNotNil: [ :context |
					         context stack do: [ :each |
							         stream
								         print: each;
								         cr ] ] ].
	self errorLog parent ensureCreateDirectory.
	self errorLog writeStreamDo: [ :stream |
			stream
				setToEnd;
				nextPutAll: '--- ';
				nextPutAll: DateAndTime now printString;
				nextPutAll: ' ';
				nextPutAll: anError class name;
				nextPutAll: ': ';
				nextPutAll: (anError messageText ifNil: [ '' ]) asString;
				lf;
				nextPutAll: stack;
				lf ]
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

{ #category : 'mistakes' }
ChessCoachSession >> mistakeDatabaseWithSpeed: aSpeedOrNil [
	"The reviewed mistakes from games of one speed (bullet, blitz, …); all of them when nil"

	| gameIds |
	aSpeedOrNil ifNil: [ ^ self mistakeDatabase ].
	gameIds := ((self gamesWithSpeed: aSpeedOrNil) collect: [ :each |
		            each gameId ]) asSet.
	^ MistakeDatabase withRecords:
		  (self mistakeDatabase records select: [ :each |
			   gameIds includes: each gameId ])
]

{ #category : 'private' }
ChessCoachSession >> mistakesFile [

	^ importer fileStore baseDirectory / 'mistakes.json'
]

{ #category : 'moments' }
ChessCoachSession >> momentsFor: aGameIndexEntry marks: someMarks [
	"The game's interesting moments, merged with someMarks; heuristics that could not run are left out"

	^ self
		  momentsFor: aGameIndexEntry
		  marks: someMarks
		  problems: OrderedCollection new
]

{ #category : 'moments' }
ChessCoachSession >> momentsFor: aGameIndexEntry marks: someMarks problems: aCollection [
	"The game's interesting moments, merged with someMarks (dictionaries with 'ply' and 'note'), sorted by ply. Only the heuristics turned on in the settings run; those that could not run add a sentence to aCollection. Slow the first time (engine analysis): call it off the UI thread."

	| game analysis colors finders opening |
	game := self gameFor: aGameIndexEntry.
	analysis := self analysisFor: aGameIndexEntry.
	colors := self myColorsIn: game.
	finders := OrderedCollection new.
	analysis hasEngineLines
		ifTrue: [
				(self settings at: 'findEvaluationJumps') ifTrue: [
					finders add: (EvaluationJumpFinder on: analysis) ].
				(self settings at: 'findOnlyMoves') ifTrue: [
					finders add: (OnlyMoveFinder on: analysis) ] ]
		ifFalse: [
				aCollection add:
					'Stockfish not found: moments come only from your marks and long thinks.' ].
	(self settings at: 'findLongThinks') ifTrue: [
		finders add: (LongThinkFinder on: game) ].
	(self settings at: 'findOpeningChoices') ifTrue: [
			(explorer notNil or: [ self isLoggedIn ])
				ifTrue: [
						finders add: (opening := OpeningWinRateFinder
								            game: game
								            explorer: self explorer
								            colors: colors) ]
				ifFalse: [
						aCollection add:
							'Log in to Lichess to compare your opening moves with its database.' ] ].
	^ (MomentDetector
		   finders: finders
		   marksFinder: (MarkedMomentsFinder game: game marks: someMarks)
		   colors: colors) moments in: [ :moments |
			  opening ifNotNil: [
				  opening problem ifNotNil: [ :problem | aCollection add: problem ] ].
			  moments ]
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

{ #category : 'opening trees' }
ChessCoachSession >> newGameCountOf: anOpeningTree [
	"How many more games match than when the tree was built"

	^ anOpeningTree gameCount negated
	  + (self gamesMatching: anOpeningTree) size max: 0
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

{ #category : 'notifications' }
ChessCoachSession >> notifications [
	"The notification center, in notifications.json next to the games"

	^ notifications ifNil: [
			  notifications := ChessCoachNotifications onFile:
				                   importer fileStore baseDirectory
				                   / 'notifications.json'.
			  notifications whenChangedDo: [
					  announcer announce: (ChessCoachNotificationsChanged new
							   notifications: notifications;
							   yourself) ].
			  notifications ]
]

{ #category : 'opening trees' }
ChessCoachSession >> openingTrees [
	"The saved opening trees, by name"

	self openingTreesDirectory exists ifFalse: [ ^ #(  ) ].
	^ (self openingTreesDirectory files collect: [ :file |
		   OpeningTree fromJSON: file contents ]) asArray sort: [ :a :b |
		  a name < b name ]
]

{ #category : 'opening trees' }
ChessCoachSession >> openingTreesDirectory [

	^ importer fileStore baseDirectory / 'opening-trees'
]

{ #category : 'opening trees' }
ChessCoachSession >> pointsIn: aGame as: aColor [
	"What aColor scored: 1, 0.5 or 0. An unfinished game counts as a draw."

	| result |
	result := aGame metadata at: 'Result' ifAbsent: [ '*' ].
	result = '1-0' ifTrue: [
			^ aColor = #white
				  ifTrue: [ 1 ]
				  ifFalse: [ 0 ] ].
	result = '0-1' ifTrue: [
			^ aColor = #black
				  ifTrue: [ 1 ]
				  ifFalse: [ 0 ] ].
	^ 0.5
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
	"Download games newer than the newest stored one, from every site with a username"

	self username ifNotNil: [ importer importNewerGames ].
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
ChessCoachSession >> reviewedGameIds [
	"The ids of the games with at least one coach review, from one listing of the games directory"

	| directory |
	directory := importer fileStore baseDirectory / 'games'.
	directory exists ifFalse: [ ^ Set new ].
	^ (directory filesMatching: '*.review-*.json')
		  collect: [ :file | file basename copyUpToSubstring: '.review-' ]
		  as: Set
]

{ #category : 'coach' }
ChessCoachSession >> reviewsFor: aGameIndexEntry [
	"The game's coach reviews (games/<id>.review-<n>.json), oldest first. A review.json and marks.json from before reviews had numbers become review 1."

	self migrateOldReviewOf: aGameIndexEntry.
	^ ((self reviewFilesOf: aGameIndexEntry gameId) collect: [ :file |
		   self review: aGameIndexEntry from: file contents ]) asArray
		  sort: [ :a :b | a number < b number ]
]

{ #category : 'opening trees' }
ChessCoachSession >> saveOpeningTree: anOpeningTree [

	self openingTreesDirectory ensureCreateDirectory.
	(self openingTreesDirectory / (anOpeningTree id , '.json'))
		ensureDelete;
		writeStreamDo: [ :stream | stream nextPutAll: anOpeningTree asJSON ]
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

{ #category : 'running' }
ChessCoachSession >> scheduler [

	^ scheduler
]

{ #category : 'settings' }
ChessCoachSession >> settingChanged: aKey [
	"Apply a changed setting to the engines, the classifier and the scheduled checks already running, then announce it. Stored analyses are kept."

	(#( 'depth' 'multiPV' 'stockfishPath' ) includes: aKey) ifTrue: [
			{
				self analyser.
				self analysisQueue analyser } do: [ :each | self configure: each ] ].
	(#( 'ollamaUrl' 'ollamaModel' ) includes: aKey) ifTrue: [
			self classifier client
				baseUrl: self settings ollamaUrl;
				model: self settings ollamaModel ].
	(aKey = 'gamesCheckMinutes' and: [
		 scheduler notNil and: [ scheduler isRunning ] ]) ifTrue: [
		self startScheduledChecks ].
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

{ #category : 'running' }
ChessCoachSession >> shutDown [
	"Stop the scheduled checks, the background analysis and quit every Stockfish process this session started"

	scheduler ifNotNil: [ scheduler stop ].
	analysisQueue ifNotNil: [ analysisQueue stop ].
	analyser ifNotNil: [ analyser engine stop ]
]

{ #category : 'running' }
ChessCoachSession >> startScheduledChecks [
	"Check for new games now and every so many minutes (a setting), and for updates now and every 6 hours, until shutDown. Unexpected errors go to errors.log"

	scheduler ifNotNil: [ scheduler stop ].
	scheduler := ChessCoachScheduler new.
	scheduler onErrorDo: [ :error | self logError: error ].
	scheduler
		every: self settings gamesCheckMinutes minutes
		do: [ self checkForNewGames ].
	scheduler every: 6 hours do: [ self checkForUpdate ].
	scheduler start
]

{ #category : 'coach' }
ChessCoachSession >> suggestedGame [
	"The latest game I lost and haven't reviewed, among my recent games, or the latest unreviewed one, or nil"

	| reviewed pending |
	reviewed := self reviewedGameIds.
	pending := (self games first: (self games size min: 30)) reject: [
		           :each | reviewed includes: each gameId ].
	pending ifEmpty: [ ^ nil ].
	^ pending
		  detect: [ :entry |
				  | game colors |
				  game := self gameFor: entry.
				  colors := self myColorsIn: game.
				  colors size = 1 and: [
					  (self pointsIn: game as: colors first) = 0 ] ]
		  ifNone: [ pending first ]
]

{ #category : 'updates' }
ChessCoachSession >> updater [

	^ updater ifNil: [ updater := ChessCoachUpdater new ]
]

{ #category : 'updates' }
ChessCoachSession >> updater: aChessCoachUpdater [

	updater := aChessCoachUpdater
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

{ #category : 'accessing' }
ChessCoachSession >> validateLichessUsername: aString [
	"Remember aString as my Lichess username if Lichess knows it; answer whether it does"

	(importer apiClient playerExists: aString trimBoth) ifFalse: [
		^ false ].
	self lichessUsername: aString trimBoth.
	^ true
]

{ #category : 'errors' }
ChessCoachSession >> writeReportFor: aGameIndexEntry review: aCoachReview note: aString [
	"Copy what is needed to look into a problem to reports/<timestamp>/: my note, the game, its analysis, the review and errors.log. Answer the directory."

	| directory games |
	directory := importer fileStore baseDirectory / 'reports'
	             /
	             (DateAndTime now asString copyReplaceAll: ':' with: '-').
	directory ensureCreateDirectory.
	directory / 'note.txt' writeStreamDo: [ :stream |
		stream nextPutAll: aString ].
	games := importer fileStore baseDirectory / 'games'.
	(games filesMatching: aGameIndexEntry gameId , '.*') do: [ :file |
		file copyTo: directory / file basename ].
	directory
	/ ('current-review-' , aCoachReview number printString , '.json')
		writeStreamDo: [ :stream | stream nextPutAll: aCoachReview asJSON ].
	self errorLog exists ifTrue: [
		self errorLog copyTo: directory / 'errors.log' ].
	^ directory
]
