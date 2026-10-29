"
I am the chess-coach main window: a top bar (login/logout, refresh, user, status), the list of stored games with ""Load more"" on the left, and the analysis of the selected game on the right.
Network work runs through my backgroundRunner (a forked process by default); I update myself when my ChessCoachSession announces a change.
"
Class {
	#name : 'ChessCoachAppElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'refreshButton',
		'loadMoreButton',
		'statusLabel',
		'analysisLabel',
		'gameList',
		'analysisPane',
		'gameView',
		'backgroundRunner',
		'coach',
		'dashboard',
		'speedFilter',
		'speedButtons',
		'navigation',
		'gamesPage',
		'settingsElement',
		'dependencyLabel'
	],
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'opening' }
ChessCoachAppElement class >> open [
	"Open on the games stored in ~/.chess-coach"

	^ self openOn: ChessCoachSession default
]

{ #category : 'opening' }
ChessCoachAppElement class >> openOn: aChessCoachSession [

	| app space |
	app := self session: aChessCoachSession.
	space := BlSpace new.
	space title: 'Chess Coach'.
	space extent: 1200 @ 760.
	space root addChild: app.
	space
		addEventHandlerOn: BlSpaceClosedEvent
		do: [ :event | aChessCoachSession analysisQueue stop ].
	space show.
	app startBackgroundAnalysis.
	^ app
]

{ #category : 'instance creation' }
ChessCoachAppElement class >> session: aChessCoachSession [

	^ self new
		  session: aChessCoachSession;
		  yourself
]

{ #category : 'private' }
ChessCoachAppElement >> analysisIconNameFor: aGameIndexEntry [
	"The Material Design icon showing the background analysis state of the game, or nil"

	| state |
	state := session analysisQueue stateOf: aGameIndexEntry.
	state = #ready ifTrue: [ ^ 'outlined_checkcircle' ].
	state = #queued ifTrue: [ ^ 'outlined_hourglassempty' ].
	state = #analysing ifTrue: [ ^ 'outlined_sync' ].
	^ nil
]

{ #category : 'accessing' }
ChessCoachAppElement >> analysisLabel [

	^ analysisLabel
]

{ #category : 'analysis queue' }
ChessCoachAppElement >> analysisStateChangedOf: aGameIdOrNil [
	"The background analysis is shown in the status line only: rebuilding list rows on every change left stale selection skins (invisible text)"

	self updateAnalysisStatus
]

{ #category : 'settings' }
ChessCoachAppElement >> applyPieceSet [
	"Every open board uses the piece set and the colour theme of the settings"

	| pieceSet theme |
	pieceSet := ChessPieceSet named: session settings pieceSet.
	theme := session settings boardTheme.
	gameView ifNotNil: [
			gameView board
				pieceSet: pieceSet;
				theme: theme ].
	coach ifNotNil: [
			coach board
				pieceSet: pieceSet;
				theme: theme ]
]

{ #category : 'accessing' }
ChessCoachAppElement >> backgroundRunner: aBlock [
	"aBlock receives the work block to run; tests pass [ :work | work value ]"

	backgroundRunner := aBlock.
	settingsElement backgroundRunner: aBlock
]

{ #category : 'accessing' }
ChessCoachAppElement >> coach [
	"The open coach review, or nil"

	^ coach
]

{ #category : 'accessing' }
ChessCoachAppElement >> dashboard [

	^ dashboard
]

{ #category : 'accessing' }
ChessCoachAppElement >> dependencyLabel [

	^ dependencyLabel
]

{ #category : 'coach' }
ChessCoachAppElement >> exitCoach [
	"Back to the view of the selected game"

	coach := nil.
	gameView ifNotNil: [ gameView updateReviews ].
	self showDefaultPane
]

{ #category : 'actions' }
ChessCoachAppElement >> filterBySpeed: aSpeedOrNil [
	"Show only the games of one time control (all when nil), as checking its button does"

	(speedButtons at: aSpeedOrNil) check
]

{ #category : 'accessing' }
ChessCoachAppElement >> gameList [

	^ gameList
]

{ #category : 'accessing' }
ChessCoachAppElement >> gameView [
	"The view of the selected game, or nil before one is selected"

	^ gameView
]

{ #category : 'private' }
ChessCoachAppElement >> games [

	^ gameList dataAccessor asArray
]

{ #category : 'accessing' }
ChessCoachAppElement >> gamesPage [

	^ gamesPage
]

{ #category : 'private' }
ChessCoachAppElement >> inUIDo: aBlock [

	self enqueueTask: (BlTaskAction new action: aBlock)
]

{ #category : 'initialization' }
ChessCoachAppElement >> initialize [
	"Pages in a tab pane with the tabs in a left column, and a status line below"

	super initialize.
	backgroundRunner := [ :aBlock |
	                    aBlock forkAt: Processor userBackgroundPriority ].
	self layout: BlLinearLayout vertical.
	self matchParent.
	dashboard := self newDashboard.
	gamesPage := self newGamesPage.
	settingsElement := SettingsElement new.
	navigation := self newNavigation.
	self
		addChild: navigation;
		addChild: self newStatusLine
]

{ #category : 'accessing' }
ChessCoachAppElement >> loadMoreButton [

	^ loadMoreButton
]

{ #category : 'accessing' }
ChessCoachAppElement >> loginButton [
	"Login/Logout lives in the settings page"

	^ settingsElement loginButton
]

{ #category : 'accessing' }
ChessCoachAppElement >> navigation [

	^ navigation
]

{ #category : 'initialization' }
ChessCoachAppElement >> newDashboard [

	| board |
	board := MistakesDashboardElement new.
	board whenRecordSelectedDo: [ :record | self openMistake: record ].
	board whenStartRequestedDo: [
			self showPage: #Games.
			self games ifNotEmpty: [ :entries |
				self selectGameId: entries first gameId ] ].
	^ board
]

{ #category : 'initialization' }
ChessCoachAppElement >> newGamesPage [
	"A title, a bar with the speed filters, Refresh and Load more; below it the game list and the selected game or the coach"

	| title bar body |
	title := ChessCoachWidgets
		         pageTitle: 'Games'
		         subtitle:
		         'Your downloaded games. Pick one to see it, or start a new analysis with the coach.'.
	title padding: (BlInsets
			 top: 8
			 left: 8
			 bottom: 0
			 right: 8).
	refreshButton := ToButton new
		                 labelText: 'Refresh';
		                 tooltipString:
			                 'Download the games played since your newest one';
		                 clickAction: [
			                 self runInBackground: [ session refresh ] ];
		                 yourself.
	loadMoreButton := ToButton new
		                  labelText: 'Load more';
		                  tooltipString:
			                  'Download older games (see Settings → Games per Load more)';
		                  clickAction: [
			                  self runInBackground: [ session loadMoreGames ] ];
		                  yourself.
	bar := ToElement new
		       layout: (BlLinearLayout horizontal cellSpacing: 8);
		       hMatchParent;
		       vFitContent;
		       padding: (BlInsets all: 8);
		       addChild: self newSpeedBar;
		       addChild: refreshButton;
		       addChild: loadMoreButton;
		       yourself.
	gameList := ToListElement new
		            useScrollbar: true;
		            vMatchParent;
		            width: 280;
		            nodeBuilder: [ :node :entry :holder |
			            node addChild: (self rowElementFor: entry) ];
		            addEventHandlerOn: ToListPrimarySelectionChangedEvent
		            do: [ :event | self selectedGameChanged ];
		            yourself.
	analysisPane := ToElement new
		                layout: BlFrameLayout new;
		                matchParent;
		                yourself.
	body := ToElement new
		        layout: BlLinearLayout horizontal;
		        matchParent;
		        addChild: gameList;
		        addChild: analysisPane;
		        yourself.
	self showDefaultPane.
	^ ToElement new
		  layout: BlLinearLayout vertical;
		  matchParent;
		  addChild: title;
		  addChild: bar;
		  addChild: body;
		  yourself
]

{ #category : 'initialization' }
ChessCoachAppElement >> newGamesPane [

	| pane |
	pane := ToElement new
		        layout: BlLinearLayout vertical;
		        vMatchParent;
		        width: 280;
		        yourself.
	gameList := ToListElement new
		            useScrollbar: true;
		            matchParent;
		            nodeBuilder: [ :node :entry :holder |
				            node addChild: (ToLabel new
							             text: (self rowTextFor: entry);
							             hMatchParent;
							             yourself) ];
		            addEventHandlerOn: ToListPrimarySelectionChangedEvent
		            do: [ :event | self selectedGameChanged ];
		            yourself.
	loadMoreButton := ToButton new
		                  labelText: 'Load more';
		                  clickAction: [
			                  self runInBackground: [ session loadMoreGames ] ];
		                  yourself.
	pane
		addChild: self newSpeedBar;
		addChild: gameList;
		addChild: loadMoreButton.
	^ pane
]

{ #category : 'initialization' }
ChessCoachAppElement >> newNavigation [
	"Stats, Games and Settings as pages of a Toplo tab pane, tabs in a column on the left. Pages are built once and kept."

	| pane |
	pane := ToTabPaneElement new.
	pane horizontal: true.
	pane matchParent.
	pane showAddTabItemButton: false.
	pane addItem:
		(self
			 newPageButton: 'Stats'
			 icon: 'outlined_insights'
			 page: dashboard).
	pane addItem: (self
			 newPageButton: 'Games'
			 icon: 'outlined_managesearch'
			 page: gamesPage).
	pane addItem: (self
			 newPageButton: 'Settings'
			 icon: 'outlined_settings'
			 page: settingsElement).
	^ pane
]

{ #category : 'initialization' }
ChessCoachAppElement >> newPageButton: aString icon: anIconName page: anElement [
	"A square tab: a large Material Design icon above a small label"

	^ ToTabButton new
		  id: aString asSymbol;
		  labelText: aString;
		  icon: ((ToMaterialDesignIconProvider iconNamed: anIconName)
				   extent: 32 @ 32;
				   yourself);
		  beVertical;
		  removable: false;
		  paneBuilder: [ :pane :button :holder | pane addChild: anElement ];
		  yourself
]

{ #category : 'initialization' }
ChessCoachAppElement >> newSpeedBar [
	"Toggle buttons that filter the game list by time control, in one row. A Toplo checkable group keeps exactly one checked; checking one filters the list."

	| bar group |
	bar := ToElement new
		       layout: BlLinearLayout horizontal;
		       hFitContent;
		       vFitContent;
		       yourself.
	group := ToCheckableGroup new.
	speedButtons := Dictionary new.
	self speeds do: [ :each |
			| button |
			button := ToToggleButton new
				          labelText: each key;
				          yourself.
			group register: button.
			button newCheckAction: [
				button isChecked ifTrue: [ self speedFilterChecked: each value ] ].
			speedButtons at: each value put: button.
			bar addChild: button ].
	(speedButtons at: nil) check.
	^ bar
]

{ #category : 'initialization' }
ChessCoachAppElement >> newStatusLine [
	"Background work, errors, the analysis queue and missing dependencies, shared by every page"

	statusLabel := ToLabel text: ''.
	analysisLabel := ToLabel text: ''.
	dependencyLabel := ToLabel text: ''.
	^ ToElement new
		  layout: (BlLinearLayout horizontal cellSpacing: 16);
		  hMatchParent;
		  vFitContent;
		  padding: (BlInsets
				   top: 2
				   left: 8
				   bottom: 2
				   right: 8);
		  addChild: statusLabel;
		  addChild: analysisLabel;
		  addChild: dependencyLabel;
		  yourself
]

{ #category : 'coach' }
ChessCoachAppElement >> openMistake: aMistakeRecord [
	"Go to Games, select the game of a mistake and show its moment in the most recent review that has it"

	| entry review |
	self showPage: #Games.
	(self selectGameId: aMistakeRecord gameId) ifFalse: [ ^ self ].
	entry := self selectedEntry.
	review := (session reviewsFor: entry) reversed
		          detect: [ :each |
				          each reviewedMoments anySatisfy: [ :moment |
					          moment ply = aMistakeRecord ply ] ]
		          ifNone: [ ^ self ].
	(self openReview: review of: entry) showMomentAtPly:
		aMistakeRecord ply
]

{ #category : 'coach' }
ChessCoachAppElement >> openReview: aCoachReview of: aGameIndexEntry [
	"Show a coach review. Its game goes to the front of the background analysis, which the end of the marking pass needs."

	(session isAnalysed: aGameIndexEntry) ifFalse: [
			| queue |
			queue := session analysisQueue.
			(queue stateOf: aGameIndexEntry) = #unknown ifTrue: [
				queue enqueueUnanalysed ].
			queue prioritise: aGameIndexEntry ].
	coach := CoachElement new.
	coach backgroundRunner: backgroundRunner.
	self applyPieceSet.
	coach session: session entry: aGameIndexEntry review: aCoachReview.
	coach whenExitDo: [ self exitCoach ].
	self showInPane: coach.
	^ coach
]

{ #category : 'navigation' }
ChessCoachAppElement >> pageButton: aPageId [

	^ navigation items asArray detect: [ :each | each id = aPageId ]
]

{ #category : 'accessing' }
ChessCoachAppElement >> refreshButton [

	^ refreshButton
]

{ #category : 'private' }
ChessCoachAppElement >> rowElementFor: aGameIndexEntry [
	"Players, result and date. A plain Bloc text: a Toplo label inside a list node kept the selected text colour after deselection, which made rows unreadable."

	^ BlTextElement new
		  text: (self rowTextFor: aGameIndexEntry) asRopedText;
		  padding: (BlInsets top: 2 bottom: 2);
		  constraintsDo: [ :c |
				  c horizontal matchParent.
				  c vertical fitContent ];
		  yourself
]

{ #category : 'private' }
ChessCoachAppElement >> rowTextFor: aGameIndexEntry [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (' – ' join: aGameIndexEntry players);
				  nextPutAll: ', ';
				  nextPutAll: aGameIndexEntry result;
				  nextPutAll: ', ';
				  nextPutAll: aGameIndexEntry date ]
]

{ #category : 'private' }
ChessCoachAppElement >> runInBackground: aBlock [
	"Run network work off the UI thread and show its progress. Lichess and network errors are shown in the status line; any other error is shown too and appended to errors.log, instead of opening a debugger."

	statusLabel text: 'Working…'.
	backgroundRunner value: [
			[
				aBlock value.
				self inUIDo: [ statusLabel text: '' ] ]
				on: Error
				do: [ :error |
						((error isKindOf: LichessError) or: [
							 error isKindOf: NetworkError ]) ifFalse: [
							session logError: error ].
						self inUIDo: [
								statusLabel text: ((error isKindOf: LichessError)
										 ifTrue: [ error messageText ]
										 ifFalse: [
												 'Something went wrong: ' , error class name , ': '
												 , (error messageText ifNil: [ '' ]) asString
												 , ' (details in errors.log)' ]) ] ] ]
]

{ #category : 'actions' }
ChessCoachAppElement >> selectGameId: aGameId [
	"Select the game in the list; answer whether it is listed"

	| index |
	index := self games findFirst: [ :each | each gameId = aGameId ].
	index = 0 ifTrue: [ ^ false ].
	gameList selecter selectIndex: index.
	self selectedGameChanged.
	^ true
]

{ #category : 'private' }
ChessCoachAppElement >> selectedEntry [
	"The index entry of the selected game, or nil"

	| index |
	index := gameList selectionModel firstIndex.
	(index isNil or: [ index = 0 ]) ifTrue: [ ^ nil ].
	^ gameList dataAccessor at: index
]

{ #category : 'updating' }
ChessCoachAppElement >> selectedGameChanged [

	| entry |
	entry := self selectedEntry ifNil: [ ^ self ].
	coach := nil.
	gameView := GameReviewsElement new.
	self applyPieceSet.
	gameView session: session entry: entry.
	gameView whenOpenDo: [ :review | self openReview: review of: entry ].
	self showInPane: gameView
]

{ #category : 'accessing' }
ChessCoachAppElement >> session: aChessCoachSession [
	"Connect to the session. The first time, run the setup wizard; otherwise open on Stats when there are reviewed mistakes, on Games otherwise."

	session := aChessCoachSession.
	session announcer
		when: ChessCoachSessionChanged
		do: [ :announcement |
				self enqueueTask:
					(BlTaskAction new action: [ self updateFromSession ]) ]
		for: self.
	session announcer
		when: AnalysisQueueChanged
		do: [ :announcement |
				self enqueueTask: (BlTaskAction new action: [
						 self analysisStateChangedOf: announcement gameId ]) ]
		for: self.
	session announcer
		when: ChessCoachSettingsChanged
		do: [ :announcement |
				(#( 'pieceSet' 'boardTheme' ) includes: announcement key) ifTrue: [
					self enqueueTask:
						(BlTaskAction new action: [ self applyPieceSet ]) ] ]
		for: self.
	settingsElement backgroundRunner: backgroundRunner.
	settingsElement session: session.
	settingsElement whenSetupRequestedDo: [ self showWizard ].
	self updateFromSession.
	self showPage: (session mistakeDatabase records
			 ifEmpty: [ #Games ]
			 ifNotEmpty: [ #Stats ]).
	session isFirstRun ifTrue: [ self showWizard ]
]

{ #category : 'accessing' }
ChessCoachAppElement >> settingsButton [
	"The Settings tab"

	^ self pageButton: #Settings
]

{ #category : 'accessing' }
ChessCoachAppElement >> settingsElement [

	^ settingsElement
]

{ #category : 'settings' }
ChessCoachAppElement >> showDefaultPane [
	"The view of the selected game, or a hint"

	self showInPane: (gameView ifNil: [
				 ToLabel new
					 text: 'Select a game';
					 padding: (BlInsets all: 16);
					 yourself ])
]

{ #category : 'analysis queue' }
ChessCoachAppElement >> showDegradedModeNotes [
	"Check Stockfish and Ollama off the UI thread and say what is off in the status line"

	backgroundRunner value: [
			| notes |
			notes := session degradedModeNotes.
			self inUIDo: [ dependencyLabel text: (' · ' join: notes) ] ]
]

{ #category : 'private' }
ChessCoachAppElement >> showInPane: anElement [

	analysisPane removeChildren.
	anElement removeFromParent.
	analysisPane addChild: anElement
]

{ #category : 'navigation' }
ChessCoachAppElement >> showPage: aPageId [
	"#Games, #Stats or #Settings"

	navigation selecter selectIndex:
		(navigation items asArray findFirst: [ :each | each id = aPageId ])
]

{ #category : 'navigation' }
ChessCoachAppElement >> showWizard [
	"The first-run setup replaces the pages until it is finished"

	| wizard |
	wizard := SetupWizardElement new.
	wizard backgroundRunner: backgroundRunner.
	wizard session: session.
	wizard whenFinishedDo: [
			wizard removeFromParent.
			self addChildFirst: navigation.
			self updateFromSession.
			self showPage: #Games ].
	navigation removeFromParent.
	self addChildFirst: wizard.
	^ wizard
]

{ #category : 'accessing' }
ChessCoachAppElement >> speedButtonFor: aSpeedOrNil [

	^ speedButtons at: aSpeedOrNil
]

{ #category : 'actions' }
ChessCoachAppElement >> speedFilterChecked: aSpeedOrNil [

	speedFilter := aSpeedOrNil.
	session ifNotNil: [ self updateFromSession ]
]

{ #category : 'private' }
ChessCoachAppElement >> speeds [
	"Label -> speed (nil for all games)"

	^ {
		  ('All' -> nil).
		  ('Bullet' -> 'bullet').
		  ('Blitz' -> 'blitz').
		  ('Rapid' -> 'rapid').
		  ('Classical' -> 'classical').
		  ('Daily' -> 'correspondence') }
]

{ #category : 'analysis queue' }
ChessCoachAppElement >> startBackgroundAnalysis [
	"Queue every unanalysed game and analyse them in the background when Stockfish is there; show what is degraded in the status line"

	session isEngineAvailable ifTrue: [
			session analysisQueue
				enqueueUnanalysed;
				start ].
	self showDegradedModeNotes
]

{ #category : 'accessing' }
ChessCoachAppElement >> statusLabel [

	^ statusLabel
]

{ #category : 'analysis queue' }
ChessCoachAppElement >> updateAnalysisStatus [

	| left |
	left := session analysisQueue pendingGameIds size.
	analysisLabel text: (left = 0
			 ifTrue: [ '' ]
			 ifFalse: [
					 'Analysing in the background: ' , left printString , ' game'
					 , (left = 1
							  ifTrue: [ '' ]
							  ifFalse: [ 's' ]) , ' left' ])
]

{ #category : 'updating' }
ChessCoachAppElement >> updateFromSession [

	refreshButton enabled: session canImport.
	loadMoreButton enabled: session canImport.
	session analysisQueue isRunning ifTrue: [
		session analysisQueue enqueueUnanalysed ].
	dashboard
		database: session mistakeDatabase
		times: session reviewTimes.
	gameList dataAccessor removeAll.
	gameList dataAccessor addAll: (session gamesWithSpeed: speedFilter).
	self updateAnalysisStatus
]
