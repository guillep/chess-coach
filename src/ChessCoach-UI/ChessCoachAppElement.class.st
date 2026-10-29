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
		'dependencyLabel',
		'listedGames',
		'selectedIndex',
		'rowsColumn',
		'coachTab',
		'playThroughTab',
		'playThrough'
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
		do: [ :event | aChessCoachSession shutDown ].
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
	"The background analysis is shown in the status line and in the open game's info, not in the list: rebuilding list rows on every change left stale selection skins (invisible text)"

	self updateAnalysisStatus.
	gameView ifNotNil: [ gameView updateInfo ]
]

{ #category : 'settings' }
ChessCoachAppElement >> applyAppTheme [
	"Toplo's light or dark theme for the whole app, with a matching page background"

	| dark |
	dark := session settings appTheme = 'Dark'.
	self localTheme: (dark
			 ifTrue: [ ToRawDarkTheme new ]
			 ifFalse: [ ToRawTheme new ]).
	self background: (Color fromHexString: (dark
				  ifTrue: [ '#1f2124' ]
				  ifFalse: [ '#ffffff' ]))
]

{ #category : 'settings' }
ChessCoachAppElement >> applyPieceSet [
	"Every open board uses the piece set and the colour theme of the settings"

	| pieceSet theme |
	pieceSet := ChessPieceSet named: session settings pieceSet.
	theme := session settings boardTheme.
	playThrough ifNotNil: [
			playThrough boardElement
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

{ #category : 'navigation' }
ChessCoachAppElement >> closeTab: aTabButton [

	aTabButton ifNil: [ ^ self ].
	navigation removeItem: aTabButton
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
	"Close the coach's page and go back to the game. Closing the shown tab makes Toplo check its neighbour in a postponed action, so Games is shown in a later postponed action."

	self closeTab: coachTab.
	navigation itemList postponeAction: [ self showPage: #Games ]
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
ChessCoachAppElement >> gameRows [
	"The rows without their separators"

	^ (1 to: rowsColumn childrenCount by: 2) collect: [ :index |
		  rowsColumn childAt: index ]
]

{ #category : 'accessing' }
ChessCoachAppElement >> gameView [
	"The view of the selected game, or nil before one is selected"

	^ gameView
]

{ #category : 'private' }
ChessCoachAppElement >> games [
	"The listed games, in list order"

	^ listedGames ifNil: [ #(  ) ]
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

{ #category : 'private' }
ChessCoachAppElement >> keepRowVisible: aRow [
	"Scroll the game list just enough to show aRow, as when moving with the arrow keys"

	| scrollable rowBounds |
	scrollable := rowsColumn parent.
	(scrollable isNil or: [ scrollable height isZero ]) ifTrue: [ ^ self ].
	rowBounds := (aRow bounds inParent: scrollable) asRectangle.
	rowBounds top < 0 ifTrue: [ ^ scrollable scrollBy: 0 @ rowBounds top ].
	rowBounds bottom > scrollable height ifTrue: [
		scrollable scrollBy: 0 @ (rowBounds bottom - scrollable height) ]
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
	board whenSpeedChosenDo: [ :speed | self updateDashboard ].
	^ board
]

{ #category : 'initialization' }
ChessCoachAppElement >> newGamesPage [
	"A title, a bar with the speed filters, Refresh and Load more; below it the game list and the selected game.
	The list is a plain scrollable column of rows. Workaround: Toplo's ToListElement recycles nodes during layout and skin installation, which left nodes without a space (logged as an upstream candidate). Up and down arrows move the selection; clicking the list gives it the keyboard focus."

	| title bar body |
	title := ChessCoachWidgets
		         pageTitle: 'Games'
		         subtitle:
		         'Your downloaded games. Pick one to see it, or start a new analysis with the coach.'.
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
		       padding: (BlInsets bottom: 8);
		       addChild: self newSpeedBar;
		       addChild: refreshButton;
		       addChild: loadMoreButton;
		       yourself.
	rowsColumn := ToElement new
		              layout: BlLinearLayout vertical;
		              hMatchParent;
		              vFitContent;
		              yourself.
	gameList := ToElement new
		            layout: BlFrameLayout new;
		            width: 300;
		            vMatchParent;
		            margin: (BlInsets right: 12);
		            border:
			            (BlBorder paint: (Color gray alpha: 0.4) width: 1);
		            addChild: (ChessCoachWidgets scrollable: rowsColumn);
		            yourself.
	gameList addShortcut: (BlShortcutWithAction new
			 combination: BlKeyCombination arrowDown;
			 action: [ self selectGameAt: (selectedIndex ifNil: [ 0 ]) + 1 ]).
	gameList addShortcut: (BlShortcutWithAction new
			 combination: BlKeyCombination arrowUp;
			 action: [ self selectGameAt: (selectedIndex ifNil: [ 2 ]) - 1 ]).
	gameList
		addEventHandlerOn: BlClickEvent
		do: [ :event | gameList requestFocus ].
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
	^ ChessCoachWidgets page: {
			  title.
			  bar.
			  body }
]

{ #category : 'initialization' }
ChessCoachAppElement >> newNavigation [
	"Stats, Games and Settings as pages of a Toplo tab pane, tabs in a column on the left. Pages are built once and kept. The coach and a played-through game open as closable pages after them."

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
	pane
		addEventHandlerOn: ToItemRemovedFromListEvent
		do: [ :event | self tabClosed: event item ].
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
	"Show a coach review in its own closable page, replacing an open one. Its game is queued for analysis (Stockfish analyses only the games you review), which the end of the marking pass needs."

	self closeTab: coachTab.
	(session isAnalysed: aGameIndexEntry) ifFalse: [
		session analysisQueue enqueue: aGameIndexEntry ].
	coach := CoachElement new.
	coach backgroundRunner: backgroundRunner.
	coach session: session entry: aGameIndexEntry review: aCoachReview.
	self applyPieceSet.
	coach whenExitDo: [ self exitCoach ].
	coachTab := self openTab: 'Coach' icon: 'outlined_school' page: coach.
	^ coach
]

{ #category : 'navigation' }
ChessCoachAppElement >> openTab: aString icon: anIconName page: anElement [
	"Add a closable page after the fixed ones and show it"

	| button |
	button := (self
		           newPageButton: aString
		           icon: anIconName
		           page: anElement)
		          removable: true;
		          yourself.
	navigation addItem: button.
	self showTab: button.
	^ button
]

{ #category : 'navigation' }
ChessCoachAppElement >> pageButton: aPageId [

	^ navigation items asArray detect: [ :each | each id = aPageId ]
]

{ #category : 'updating' }
ChessCoachAppElement >> paintRowAt: anIndex [

	self paintRowAt: anIndex hovered: false
]

{ #category : 'updating' }
ChessCoachAppElement >> paintRowAt: anIndex hovered: aBoolean [
	"Translucent backgrounds, so that they work on light and dark themes"

	| childIndex |
	childIndex := anIndex * 2 - 1.
	childIndex > rowsColumn childrenCount ifTrue: [ ^ self ].
	(rowsColumn childAt: childIndex) background:
		(anIndex = selectedIndex
			 ifTrue: [ Color blue alpha: 0.25 ]
			 ifFalse: [
					 aBoolean
						 ifTrue: [ Color gray alpha: 0.15 ]
						 ifFalse: [ Color transparent ] ])
]

{ #category : 'actions' }
ChessCoachAppElement >> playThrough: aGameIndexEntry [
	"Look at the game move by move in its own closable page, replacing an open one"

	| game colors |
	self closeTab: playThroughTab.
	game := session gameFor: aGameIndexEntry.
	colors := session myColorsIn: game.
	playThrough := GameAnalysisElement new.
	self applyPieceSet.
	playThrough boardElement orientation: (colors size = 1
			 ifTrue: [ colors first ]
			 ifFalse: [ #white ]).
	playThrough game: game.
	playThroughTab := self
		                  openTab: 'Game'
		                  icon: 'outlined_slideshow'
		                  page: playThrough.
	^ playThrough
]

{ #category : 'updating' }
ChessCoachAppElement >> rebuildRows [
	"Each row is followed by a 1 px translucent separator, which works on light and dark themes"

	rowsColumn removeChildren.
	listedGames doWithIndex: [ :entry :index |
			rowsColumn addChild: (self rowElementFor: entry at: index).
			rowsColumn addChild: (BlElement new
					 height: 1;
					 constraintsDo: [ :c | c horizontal matchParent ];
					 background: (Color gray alpha: 0.3);
					 yourself) ].
	self updateRowSelection
]

{ #category : 'accessing' }
ChessCoachAppElement >> refreshButton [

	^ refreshButton
]

{ #category : 'private' }
ChessCoachAppElement >> rowElementFor: aGameIndexEntry at: anIndex [
	"Players, result and date; a click selects the game. A label, so that its text follows the app theme."

	| row |
	row := ToLabel new
		       text: (self rowTextFor: aGameIndexEntry);
		       padding: (BlInsets
				        top: 8
				        left: 10
				        bottom: 8
				        right: 10);
		       hMatchParent;
		       yourself.
	row
		addEventHandlerOn: BlClickEvent
		do: [ :event | self selectGameAt: anIndex ].
	row
		addEventHandlerOn: BlMouseEnterEvent
		do: [ :event | self paintRowAt: anIndex hovered: true ].
	row
		addEventHandlerOn: BlMouseLeaveEvent
		do: [ :event | self paintRowAt: anIndex hovered: false ].
	^ row
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
ChessCoachAppElement >> selectGameAt: anIndex [
	"Select the listed game at anIndex (ignored outside the list), keep it in view and show it; only the previous and the new row are repainted"

	| previous |
	(anIndex between: 1 and: self games size) ifFalse: [ ^ self ].
	previous := selectedIndex.
	selectedIndex := anIndex.
	previous ifNotNil: [ self paintRowAt: previous ].
	self paintRowAt: anIndex.
	anIndex * 2 - 1 <= rowsColumn childrenCount ifTrue: [
		self keepRowVisible: (rowsColumn childAt: anIndex * 2 - 1) ].
	self selectedGameChanged
]

{ #category : 'actions' }
ChessCoachAppElement >> selectGameId: aGameId [
	"Select the game in the list; answer whether it is listed"

	| index |
	index := self games findFirst: [ :each | each gameId = aGameId ].
	index = 0 ifTrue: [ ^ false ].
	self selectGameAt: index.
	^ true
]

{ #category : 'private' }
ChessCoachAppElement >> selectedEntry [
	"The index entry of the selected game, or nil"

	(selectedIndex isNil or: [ selectedIndex > self games size ])
		ifTrue: [ ^ nil ].
	^ self games at: selectedIndex
]

{ #category : 'updating' }
ChessCoachAppElement >> selectedGameChanged [

	| entry |
	entry := self selectedEntry ifNil: [ ^ self ].
	gameView := GameReviewsElement new.
	gameView session: session entry: entry.
	gameView whenOpenDo: [ :review | self openReview: review of: entry ].
	gameView whenPlayThroughDo: [ self playThrough: entry ].
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
						(BlTaskAction new action: [ self applyPieceSet ]) ].
				announcement key = 'appTheme' ifTrue: [
					self enqueueTask:
						(BlTaskAction new action: [ self applyAppTheme ]) ] ]
		for: self.
	self applyAppTheme.
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
ChessCoachAppElement >> showTab: aTabButton [

	navigation selecter selectIndex:
		(navigation items asArray indexOf: aTabButton)
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

	^ ChessCoachWidgets speeds
]

{ #category : 'analysis queue' }
ChessCoachAppElement >> startBackgroundAnalysis [
	"Start the background analysis when Stockfish is there; it stays idle until a game is queued (when its marking pass starts). Show what is degraded in the status line."

	session isEngineAvailable ifTrue: [ session analysisQueue start ].
	self showDegradedModeNotes
]

{ #category : 'accessing' }
ChessCoachAppElement >> statusLabel [

	^ statusLabel
]

{ #category : 'navigation' }
ChessCoachAppElement >> tabClosed: aTabButton [
	"A closable page was closed, from its tab or from its own close button"

	aTabButton == coachTab ifTrue: [
			coach review leaveMoment.
			coach := nil.
			coachTab := nil.
			gameView ifNotNil: [ gameView updateReviews ] ].
	aTabButton == playThroughTab ifTrue: [
			playThrough := nil.
			playThroughTab := nil ]
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
ChessCoachAppElement >> updateDashboard [
	"The mistakes of the time control chosen on the Stats page"

	dashboard
		database: (session mistakeDatabaseWithSpeed: dashboard speed)
		times: session reviewTimes
]

{ #category : 'updating' }
ChessCoachAppElement >> updateFromSession [
	"Reload the list, keeping the selected game selected when it is still listed"

	| selectedId index |
	refreshButton enabled: session canImport.
	loadMoreButton enabled: session canImport.
	self updateDashboard.
	selectedId := self selectedEntry ifNotNil: [ :entry | entry gameId ].
	listedGames := (session gamesWithSpeed: speedFilter) asArray.
	index := listedGames findFirst: [ :each | each gameId = selectedId ].
	selectedIndex := index = 0
		                 ifTrue: [ nil ]
		                 ifFalse: [ index ].
	self rebuildRows.
	self updateAnalysisStatus
]

{ #category : 'updating' }
ChessCoachAppElement >> updateRowSelection [

	1 to: self games size do: [ :index | self paintRowAt: index ]
]
