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
		'selectedIndex',
		'coachTab',
		'playThroughTab',
		'playThrough',
		'bell',
		'bellBadge',
		'notificationsWindow',
		'reviewedIds',
		'notReviewedButton',
		'gameTable',
		'shownGameId',
		'openings',
		'openingTreeTab'
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
	aChessCoachSession startScheduledChecks.
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
	"Toplo's light or dark theme for the whole window, with a matching page background.
	The theme goes on the space: under an element's local theme, Toplo installs no skin on a list's scrollbar (logged as an upstream candidate)."

	| dark |
	dark := session settings appTheme = 'Dark'.
	self isAttachedToSceneGraph ifTrue: [
			self space toTheme: (dark
					 ifTrue: [ ToRawDarkTheme new ]
					 ifFalse: [ ToRawTheme new ]) ].
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
	settingsElement backgroundRunner: aBlock.
	openings backgroundRunner: aBlock
]

{ #category : 'accessing' }
ChessCoachAppElement >> bell [

	^ bell
]

{ #category : 'accessing' }
ChessCoachAppElement >> bellBadge [

	^ bellBadge
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

{ #category : 'initialization' }
ChessCoachAppElement >> gameColumn: aTitle width: aNumber value: aBlock [
	"A column showing aBlock's text for each game, sorted by that text"

	^ ToTableColumn new
		  key: aTitle;
		  title: aTitle;
		  width: aNumber;
		  dataIndex: aBlock;
		  sorterBlock: aBlock;
		  yourself
]

{ #category : 'accessing' }
ChessCoachAppElement >> gameList [

	^ gameList
]

{ #category : 'accessing' }
ChessCoachAppElement >> gameRows [
	"The rows the list currently shows"

	| rows |
	rows := OrderedCollection new.
	gameList allChildrenBreadthFirstDo: [ :each |
		(each isKindOf: ToNodeContainer) ifTrue: [ rows add: each ] ].
	^ rows asArray
]

{ #category : 'accessing' }
ChessCoachAppElement >> gameTable [

	^ gameTable
]

{ #category : 'accessing' }
ChessCoachAppElement >> gameView [
	"The view of the selected game, or nil before one is selected"

	^ gameView
]

{ #category : 'private' }
ChessCoachAppElement >> games [
	"The listed games, in table order (the table sorts them in place)"

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
	"A top bar with the notification bell on the right, the pages in a tab pane with the tabs in a left column, and a status line below"

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
		addChild: (ToElement new
				 id: #topBar;
				 layout:
					 (BlLinearLayout horizontal alignCenterRight cellSpacing: 8);
				 hMatchParent;
				 vFitContent;
				 padding: (BlInsets
						  top: 8
						  left: 16
						  bottom: 0
						  right: 16);
				 addChild: self newBell;
				 yourself);
		addChild: navigation;
		addChild: self newStatusLine
]

{ #category : 'private' }
ChessCoachAppElement >> isReviewed: aGameIndexEntry [

	^ (reviewedIds ifNil: [ #(  ) ]) includes: aGameIndexEntry gameId
]

{ #category : 'updating' }
ChessCoachAppElement >> listSelectionChanged [
	"The table selected another game, by a click or the arrow keys. Sorting moves the shown game: only its index changes then"

	| index |
	index := gameList selectionModel firstIndex.
	(index isNil or: [ index = 0 or: [ index = selectedIndex ] ])
		ifTrue: [ ^ self ].
	selectedIndex := index.
	self selectedEntry gameId = shownGameId ifTrue: [ ^ self ].
	self selectedGameChanged
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
ChessCoachAppElement >> newBell [
	"The notification bell, with a red dot while there are unread notifications. Clicking it pops up the notifications below it, to its left (they would leave the window otherwise), and marks them read.
	The popup stays open on mouse up (a menu would close), so its buttons get their clicks"

	bellBadge := BlElement new
		             geometry: BlCircleGeometry new;
		             extent: 10 @ 10;
		             background: (Color fromHexString: '#dc2626');
		             visibility: BlVisibility hidden;
		             constraintsDo: [ :c |
				             c frame horizontal alignRight.
				             c frame vertical alignTop ];
		             yourself.
	bell := ToButton new
		        id: #notifications;
		        icon:
			        ((ToMaterialDesignIconProvider iconNamed:
					          'outlined_notifications')
				         extent: 24 @ 24;
				         yourself);
		        tooltipText: 'Notifications';
		        yourself.
	notificationsWindow := ToPopupWindowManager new.
	notificationsWindow placement: ToAnchoredBottomLeftPlacement new.
	notificationsWindow closeOnReleased: false.
	notificationsWindow windowBuilder: [ :window :element |
			window root addChild: self newNotificationsPanel.
			session notifications markAllRead ].
	bell addEventHandler: notificationsWindow.
	^ ToElement new
		  layout: BlFrameLayout new;
		  fitContent;
		  addChild: bell;
		  addChild: bellBadge;
		  yourself
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
ChessCoachAppElement >> newGameTable [
	"A Toplo table of the games: one column per field, sorted by clicking the arrow in its header, and a coach icon on reviewed games.
	After each header layout, column widths lost while the page was hidden are restored, in a task so the layout isn't changed while it runs (see restoreGameColumnWidths)"

	gameTable := ToTableElement new
		             useScrollbar: true;
		             width: 680;
		             vMatchParent;
		             margin: (BlInsets right: 12);
		             yourself.
	gameTable columns: {
			(self
				 gameColumn: 'White'
				 width: 150
				 value: [ :entry | entry players first ]).
			(self
				 gameColumn: 'Black'
				 width: 150
				 value: [ :entry | entry players second ]).
			(self
				 gameColumn: 'Result'
				 width: 80
				 value: [ :entry | entry result ]).
			(self gameColumn: 'Date' width: 100 value: [ :entry | entry date ]).
			((self
				  gameColumn: 'Time control'
				  width: 125
				  value: [ :entry | self speedNameOf: entry ])
				 sorterBlock: [ :entry | self speedRankOf: entry ];
				 yourself).
			(ToTableColumn new
				 key: 'reviewed';
				 title: '';
				 width: 40;
				 dataIndex: [ :entry | entry ];
				 sorterBlock: [ :entry |
						 (self isReviewed: entry)
							 ifTrue: [ 1 ]
							 ifFalse: [ 0 ] ];
				 cellBuilder: [ :cell :entry :holder |
						 (self isReviewed: entry) ifTrue: [
									 cell addChild:
											 ((ToMaterialDesignIconProvider iconNamed:
													   'outlined_school')
												  extent: 16 @ 16;
												  tooltipText: 'Reviewed with the coach';
												  yourself) ] ];
				 yourself) }.
	gameTable header
		addEventHandlerOn: BlElementLayoutComputedEvent
		do: [ :event |
				gameTable enqueueTask:
					(BlTaskAction new action: [ self restoreGameColumnWidths ]) ].
	gameList := gameTable list.
	gameList
		addEventHandlerOn: ToListPrimarySelectionChangedEvent
		do: [ :event | self listSelectionChanged ].
	gameTable selecter beSingleSelection.
	^ gameTable
]

{ #category : 'initialization' }
ChessCoachAppElement >> newGamesPage [
	"A bar with the speed filters, the Not reviewed filter, Refresh and Load more; below it the game table and the selected game"

	| bar body |
	notReviewedButton := ToToggleButton new
		                     labelText: 'Not reviewed';
		                     tooltipString:
			                     'Only the games you have not reviewed with the coach yet';
		                     yourself.
	notReviewedButton newCheckAction: [
		session ifNotNil: [ self updateFromSession ] ].
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
		       addChild: notReviewedButton;
		       addChild: refreshButton;
		       addChild: loadMoreButton;
		       yourself.
	analysisPane := ToElement new
		                layout: BlFrameLayout new;
		                matchParent;
		                yourself.
	body := ToElement new
		        layout: BlLinearLayout horizontal;
		        matchParent;
		        addChild: self newGameTable;
		        addChild: analysisPane;
		        yourself.
	self showDefaultPane.
	^ ChessCoachWidgets
		  page: 'Games'
		  subtitle:
		  'Your downloaded games. Pick one to see it, or start a new analysis with the coach.'
		  body: (ToElement new
				   layout: BlLinearLayout vertical;
				   matchParent;
				   addChild: bar;
				   addChild: body;
				   yourself)
]

{ #category : 'initialization' }
ChessCoachAppElement >> newNavigation [
	"Stats, Games, Openings and Settings as pages of a Toplo tab pane, tabs in a column on the left. Pages are built once and kept. The coach, a played-through game and an opening tree open as closable pages after them."

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
	openings := OpeningsElement new.
	openings whenOpenDo: [ :tree | self openOpeningTree: tree ].
	pane addItem: (self
			 newPageButton: 'Openings'
			 icon: 'outlined_accounttree'
			 page: openings).
	pane addItem: (self
			 newPageButton: 'Settings'
			 icon: 'outlined_settings'
			 page: settingsElement).
	pane
		addEventHandlerOn: ToItemRemovedFromListEvent
		do: [ :event |
		self tabClosed: event item wasSelected: event wasSelected ].
	^ pane
]

{ #category : 'notifications' }
ChessCoachAppElement >> newNotificationRow: aNotification in: aPanel [
	"Title, time and text, the notification's action (Show for new games) and a dismiss button that removes the row"

	| row header |
	row := ToElement new
		       layout: (BlLinearLayout vertical cellSpacing: 4);
		       hMatchParent;
		       vFitContent;
		       yourself.
	header := ToElement new
		          layout: (BlLinearLayout horizontal cellSpacing: 8);
		          hMatchParent;
		          vFitContent;
		          addChild: (ToLabel new
				           text: aNotification title asRopedText bold;
				           hMatchParent;
				           yourself);
		          addChild:
		          (ToLabel text: (self timeTextFor: aNotification time));
		          addChild: (ToButton new
				           icon:
					           ((ToMaterialDesignIconProvider iconNamed:
							             'outlined_close')
						            extent: 16 @ 16;
						            yourself);
				           tooltipText: 'Dismiss';
				           clickAction: [
						           session notifications dismiss: aNotification.
						           aPanel removeChild: row ];
				           yourself);
		          yourself.
	row addChild: header.
	aNotification text ifNotEmpty: [ :text |
		row addChild: (ChessCoachWidgets paragraph: text) ].
	aNotification kind = #newGames ifTrue: [
			row addChild: (ToButton new
					 labelText: 'Show';
					 clickAction: [
							 notificationsWindow currentWindow ifNotNil: [ :window |
									 window close ].
							 self showPage: #Games ];
					 yourself) ].
	^ row
]

{ #category : 'notifications' }
ChessCoachAppElement >> newNotificationsPanel [
	"The notifications, newest first, each with its action and a dismiss button"

	| panel visible |
	panel := ToElement new
		         layout: (BlLinearLayout vertical cellSpacing: 8);
		         width: 360;
		         vFitContent;
		         padding: (BlInsets all: 12);
		         yourself.
	visible := session notifications visible.
	visible ifEmpty: [
			^ panel
				  addChild: (ToLabel text: 'No notifications');
				  yourself ].
	visible
		do: [ :each |
		panel addChild: (self newNotificationRow: each in: panel) ]
		separatedBy: [ panel addChild: ChessCoachWidgets separator ].
	^ panel
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

{ #category : 'accessing' }
ChessCoachAppElement >> notReviewedButton [

	^ notReviewedButton
]

{ #category : 'accessing' }
ChessCoachAppElement >> notificationsWindow [

	^ notificationsWindow
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

{ #category : 'actions' }
ChessCoachAppElement >> openOpeningTree: anOpeningTree [
	"Explore a tree in its own closable page named after it, replacing an open one. A new tree is built there."

	| element |
	self closeTab: openingTreeTab.
	element := OpeningTreeElement
		           session: session
		           tree: anOpeningTree
		           runner: backgroundRunner.
	element board
		pieceSet: (ChessPieceSet named: session settings pieceSet);
		theme: session settings boardTheme.
	element whenGameChosenDo: [ :entry | self playThrough: entry ].
	element whenBuiltDo: [ openings updateTrees ].
	openingTreeTab := self
		                  openTab: anOpeningTree name
		                  icon: 'outlined_accounttree'
		                  page: (ChessCoachWidgets
				                   page: anOpeningTree name
				                   subtitle:
				                   'Your games compared with the database.'
				                   body: element).
	element start.
	^ element
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
	coachTab := self
		            openTab: 'Coach'
		            icon: 'outlined_school'
		            page: (ChessCoachWidgets
				             page:
				             aGameIndexEntry players first , ' – '
				             , aGameIndexEntry players second
				             subtitle: 'Review with the coach'
				             body: coach).
	^ coach
]

{ #category : 'navigation' }
ChessCoachAppElement >> openTab: aString icon: anIconName page: anElement [
	"Add a closable page after the fixed ones and show it, with the margins every page has"

	| button |
	button := (self
		           newPageButton: aString
		           icon: anIconName
		           page: (ToElement new
				            layout: BlFrameLayout new;
				            matchParent;
				            padding: (BlInsets all: 16);
				            addChild: anElement;
				            yourself))
		          removable: true;
		          yourself.
	navigation addItem: button.
	self showTab: button.
	^ button
]

{ #category : 'accessing' }
ChessCoachAppElement >> openings [

	^ openings
]

{ #category : 'navigation' }
ChessCoachAppElement >> pageButton: aPageId [

	^ navigation items asArray detect: [ :each | each id = aPageId ]
]

{ #category : 'actions' }
ChessCoachAppElement >> playThrough: aGameIndexEntry [
	"Look at the game move by move in its own closable page named after its players, replacing an open one"

	| game colors title |
	self closeTab: playThroughTab.
	game := session gameFor: aGameIndexEntry.
	colors := session myColorsIn: game.
	playThrough := GameAnalysisElement new.
	self applyPieceSet.
	playThrough boardElement orientation: (colors size = 1
			 ifTrue: [ colors first ]
			 ifFalse: [ #white ]).
	playThrough game: game.
	title := aGameIndexEntry players first , ' – '
	         , aGameIndexEntry players second.
	playThroughTab := self
		                  openTab: 'Game'
		                  icon: 'outlined_slideshow'
		                  page: (ChessCoachWidgets
				                   page: title
				                   subtitle: aGameIndexEntry date
				                   body: playThrough).
	^ playThrough
]

{ #category : 'accessing' }
ChessCoachAppElement >> playThroughTab [

	^ playThroughTab
]

{ #category : 'accessing' }
ChessCoachAppElement >> refreshButton [

	^ refreshButton
]

{ #category : 'private' }
ChessCoachAppElement >> restoreGameColumnWidths [
	"Workaround: a Toplo table laid out in a hidden tab records 0 as its column widths (upstream/toplo-table-in-hidden-tab-repro.st). Once the table is shown, give each header cell its column's width again and let the rows follow"

	| containers |
	gameTable width > 0 ifFalse: [ ^ self ].
	containers := gameTable header cellContainers.
	(containers anySatisfy: [ :each | each width = 0 ]) ifFalse: [
		^ self ].
	containers
		with: gameTable columns
		do: [ :container :column | container updateWidthWith: column width ].
	gameTable list recordCellsWidth
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
	"Select the listed game at anIndex (ignored outside the list), keep it in view and show it"

	(anIndex between: 1 and: self games size) ifFalse: [ ^ self ].
	selectedIndex := anIndex.
	gameList selecter selectOnlyIndex: anIndex.
	gameList scrollToDataSourcePosition: anIndex.
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
	shownGameId := entry gameId.
	gameView := GameReviewsElement new.
	gameView session: session entry: entry.
	gameView whenOpenDo: [ :review | self openReview: review of: entry ].
	gameView whenPlayThroughDo: [ self playThrough: entry ].
	self showInPane: gameView
]

{ #category : 'accessing' }
ChessCoachAppElement >> session: aChessCoachSession [
	"Connect to the session. The first time, run the setup wizard; otherwise open on Stats when there are reviewed mistakes, on Games otherwise.
	The app theme is applied again when I am added to a space."

	session := aChessCoachSession.
	(self childWithId: #topBar) addChildFirst:
		(ChessCoachWidgets help: 'Chess Coach ' , session appVersion).
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
		when: ChessCoachNotificationsChanged
		do: [ :announcement |
			self enqueueTask: (BlTaskAction new action: [ self updateBell ]) ]
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
	self
		addEventHandlerOn: BlElementAddedToSceneGraphEvent
		do: [ :event | self applyAppTheme ].
	self applyAppTheme.
	settingsElement backgroundRunner: backgroundRunner.
	settingsElement session: session.
	settingsElement whenSetupRequestedDo: [ self showWizard ].
	openings session: session.
	self updateFromSession.
	self updateBell.
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
	"The first-run setup replaces the pages until it is finished, below the top bar"

	| wizard |
	wizard := SetupWizardElement new.
	wizard backgroundRunner: backgroundRunner.
	wizard session: session.
	wizard whenFinishedDo: [
			wizard removeFromParent.
			self addChild: navigation at: 2.
			self updateFromSession.
			self showPage: #Games ].
	navigation removeFromParent.
	self addChild: wizard at: 2.
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
ChessCoachAppElement >> speedNameOf: aGameIndexEntry [

	^ (self speeds
		   detect: [ :each | each value = aGameIndexEntry speed ]
		   ifNone: [ nil ])
		  ifNil: [ aGameIndexEntry speed ifNil: [ '' ] ]
		  ifNotNil: [ :each | each key ]
]

{ #category : 'private' }
ChessCoachAppElement >> speedRankOf: aGameIndexEntry [
	"Faster speeds first, as the speed filters are"

	^ #( 'ultraBullet' 'bullet' 'blitz' 'rapid' 'classical' 'correspondence' )
		  indexOf: aGameIndexEntry speed
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
ChessCoachAppElement >> tabClosed: aTabButton wasSelected: aBoolean [
	"A closable page was closed, from its tab or from its own close button. If it was showing, go back to the page it came from rather than to the neighbouring tab, unless a new page of the same kind replaced it. Toplo checks the neighbour in a postponed action queued after this event, so the page is shown one postponed action later."

	aTabButton == coachTab ifTrue: [
			coach review leaveMoment.
			coach := nil.
			coachTab := nil.
			gameView ifNotNil: [ gameView updateReviews ].
			aBoolean ifTrue: [
					navigation itemList postponeAction: [
							navigation itemList postponeAction: [
								coachTab ifNil: [ self showPage: #Games ] ] ] ] ].
	aTabButton == playThroughTab ifTrue: [
			playThrough := nil.
			playThroughTab := nil.
			aBoolean ifTrue: [
					navigation itemList postponeAction: [
							navigation itemList postponeAction: [
								playThroughTab ifNil: [ self showPage: #Games ] ] ] ] ].
	aTabButton == openingTreeTab ifTrue: [
			openingTreeTab := nil.
			aBoolean ifTrue: [
					navigation itemList postponeAction: [
							navigation itemList postponeAction: [
								openingTreeTab ifNil: [ self showPage: #Openings ] ] ] ] ]
]

{ #category : 'notifications' }
ChessCoachAppElement >> timeTextFor: aDateAndTime [
	"Today's notifications show their time, older ones their date"

	^ aDateAndTime asDate = Date today
		  ifTrue: [ aDateAndTime asTime print24 first: 5 ]
		  ifFalse: [ aDateAndTime asDate yyyymmdd ]
]

{ #category : 'analysis queue' }
ChessCoachAppElement >> updateAnalysisStatus [

	| left |
	left := session analysisQueue pendingGameIds size.
	analysisLabel text: (left = 0
			 ifTrue: [ '' ]
			 ifFalse: [
					 'Stockfish is analysing: ' , left printString , ' game'
					 , (left = 1
							  ifTrue: [ '' ]
							  ifFalse: [ 's' ]) , ' left. You can keep working.' ])
]

{ #category : 'notifications' }
ChessCoachAppElement >> updateBell [
	"Show the red dot while there are unread notifications"

	bellBadge visibility: (session notifications unreadCount > 0
			 ifTrue: [ BlVisibility visible ]
			 ifFalse: [ BlVisibility hidden ])
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
	"Reload the table, keeping the selected game selected when it is still listed. With Not reviewed checked, reviewed games are left out"

	| selectedId listed index |
	refreshButton enabled: session canImport.
	loadMoreButton enabled: session canImport.
	self updateDashboard.
	selectedId := self selectedEntry ifNotNil: [ :entry | entry gameId ].
	reviewedIds := session reviewedGameIds.
	listed := (session gamesWithSpeed: speedFilter) asArray.
	notReviewedButton isChecked ifTrue: [
		listed := listed reject: [ :each | self isReviewed: each ] ].
	index := listed findFirst: [ :each | each gameId = selectedId ].
	selectedIndex := index = 0
		                 ifTrue: [ nil ]
		                 ifFalse: [ index ].
	gameList dataAccessor removeAll.
	gameList dataAccessor addAll: listed.
	selectedIndex ifNotNil: [
		gameList selecter selectOnlyIndex: selectedIndex ].
	self updateAnalysisStatus
]
