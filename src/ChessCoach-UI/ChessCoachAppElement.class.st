"
I am the Chessmate window, on the Mamotreto shell (MMWindow): Home, Stats, Games, Openings, Settings and Help in the rail; the coach, a played-through game and an opening tree open as closable pages. The Games page lists the stored games with filters, Refresh and Load more, and shows the selected one at the right. The status bar also shows the background analysis and missing dependencies.
"
Class {
	#name : 'ChessCoachAppElement',
	#superclass : 'MMWindow',
	#instVars : [
		'refreshButton',
		'loadMoreButton',
		'analysisLabel',
		'gameList',
		'analysisPane',
		'gameView',
		'coach',
		'dashboard',
		'gamesPage',
		'settingsElement',
		'dependencyLabel',
		'selectedIndex',
		'coachTab',
		'playThroughTab',
		'playThrough',
		'gameTable',
		'shownGameId',
		'openings',
		'openingTreeTab',
		'home',
		'speedSelect',
		'reviewSelect',
		'reviewStates',
		'helpElement'
	],
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'instance creation' }
ChessCoachAppElement class >> defaultApp [

	^ ChessmateApp new
]

{ #category : 'opening' }
ChessCoachAppElement class >> open [
	"Open on the games stored in ~/.chess-coach"

	^ ChessmateApp new open
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
	"The Chessmate light or dark Toplo theme, then the palette.
	The theme goes on the space: under an element's local theme, Toplo installs no skin on a list's scrollbar (logged as an upstream candidate)."

	self isAttachedToSceneGraph ifTrue: [
			self space toTheme: (session settings appTheme = 'Dark'
					 ifTrue: [ ChessmateDarkTheme new ]
					 ifFalse: [ ChessmateTheme new ]) ].
	super applyAppTheme
]

{ #category : 'settings' }
ChessCoachAppElement >> applyPieceSet [
	"Every open board uses the piece set and the colour theme of the settings: the game played through, the coach (and its marking replay) and the opening tree"

	| pieceSet theme |
	pieceSet := ChessPieceSet named: session settings pieceSet.
	theme := session settings boardTheme.
	playThrough ifNotNil: [
			playThrough boardElement
				pieceSet: pieceSet;
				theme: theme ].
	coach ifNotNil: [ coach pieceSet: pieceSet theme: theme ].
	openingTreeTab ifNotNil: [
			openingTreeTab userData at: #openingTree ifPresent: [ :tree |
					tree board
						pieceSet: pieceSet;
						theme: theme ] ]
]

{ #category : 'accessing' }
ChessCoachAppElement >> backgroundRunner: aBlock [
	"aBlock receives the work block to run; tests pass [ :work | work value ]"

	super backgroundRunner: aBlock.
	settingsElement backgroundRunner: aBlock.
	openings backgroundRunner: aBlock
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
ChessCoachAppElement >> filterByReview: aStateOrNil [
	"Show only the games in that review state (all when nil), as choosing it does"

	reviewSelect selecter selectIndex:
		(self reviewChoices findFirst: [ :each | each value = aStateOrNil ])
]

{ #category : 'actions' }
ChessCoachAppElement >> filterBySpeed: aSpeedOrNil [
	"Show only the games of one time control (all when nil), as choosing it does"

	speedSelect selecter selectIndex:
		(self speedChoices findFirst: [ :each | each value = aSpeedOrNil ])
]

{ #category : 'accessing' }
ChessCoachAppElement >> gameFilter [
	"What the two dropdowns chose"

	| filter |
	filter := GameFilter new.
	filter at: 'speed' put: speedSelect selectedDataItem value.
	filter at: 'review' put: reviewSelect selectedDataItem value.
	^ filter
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

{ #category : 'accessing' }
ChessCoachAppElement >> helpElement [

	^ helpElement
]

{ #category : 'accessing' }
ChessCoachAppElement >> home [

	^ home
]

{ #category : 'app' }
ChessCoachAppElement >> isExpectedError: anError [
	"Lichess errors say what went wrong themselves"

	^ (anError isKindOf: LichessError) or: [
		  super isExpectedError: anError ]
]

{ #category : 'accessing' }
ChessCoachAppElement >> isReviewed: aGameIndexEntry [
	"Whether it has a review, finished or not"

	^ (self reviewStateOf: aGameIndexEntry) ~= 'unreviewed'
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

{ #category : 'initialization' }
ChessCoachAppElement >> newDashboard [
	"The chosen time control is remembered for the next time"

	| board |
	board := MistakesDashboardElement new.
	board whenRecordSelectedDo: [ :record | self openMistake: record ].
	board whenStartRequestedDo: [
			self showPage: #Games.
			self games ifNotEmpty: [ :entries |
				self selectGameId: entries first gameId ] ].
	board whenSpeedChosenDo: [ :speed |
			session settings at: 'statsSpeed' put: speed.
			self updateDashboard ].
	^ board
]

{ #category : 'initialization' }
ChessCoachAppElement >> newFilterSelect: someAssociations [
	"A dropdown of label -> value, the first selected, that reloads the table"

	| select |
	select := (MMWidgets dropdown: someAssociations)
		          width: 190;
		          yourself.
	select
		addEventHandlerOn: ToSelectChangedEvent
		do: [ :event | session ifNotNil: [ self updateFromSession ] ].
	^ select
]

{ #category : 'initialization' }
ChessCoachAppElement >> newGameTable [
	"A table of the games: one column per field, sorted by clicking the arrow in its header, and a coach icon on reviewed games"

	gameTable := MMTableElement new
		             width: 630;
		             vMatchParent;
		             margin: (BlInsets right: 12);
		             yourself.
	gameTable columns: {
			(MMTableElement
				 column: 'White'
				 width: 135
				 value: [ :entry | entry players first ]).
			(MMTableElement
				 column: 'Black'
				 width: 135
				 value: [ :entry | entry players second ]).
			(MMTableElement
				 column: 'Result'
				 width: 80
				 value: [ :entry | entry result ]).
			(MMTableElement
				 column: 'Date'
				 width: 100
				 value: [ :entry | entry date ]).
			((MMTableElement
				  column: 'Time control'
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
						 #( 'unreviewed' 'inProgress' 'reviewed' ) indexOf:
								 (self reviewStateOf: entry) ];
				 cellBuilder: [ :cell :entry :holder |
						 (self isReviewed: entry) ifTrue: [
									 cell addChild: ((ChessCoachWidgets
												   icon: ((self reviewStateOf: entry) = 'reviewed'
														    ifTrue: [ 'outlined_school' ]
														    ifFalse: [ 'outlined_timelapse' ])
												   extent: 16 @ 16)
												  tooltipText: ((self reviewStateOf: entry) = 'reviewed'
														   ifTrue: [ 'Reviewed with the coach' ]
														   ifFalse: [ 'Review in progress' ]);
												  yourself) ] ];
				 yourself) }.
	gameList := gameTable list.
	gameList
		addEventHandlerOn: ToListPrimarySelectionChangedEvent
		do: [ :event | self listSelectionChanged ].
	gameTable selecter beSingleSelection.
	^ gameTable
]

{ #category : 'initialization' }
ChessCoachAppElement >> newGamesPage [
	"A bar with the time control and review filters, Refresh and Load more; below it the game table and the selected game"

	| bar body |
	speedSelect := self newFilterSelect: self speedChoices.
	reviewSelect := self newFilterSelect: self reviewChoices.
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
		       addChild: speedSelect;
		       addChild: reviewSelect;
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
	"Build the pages the app declares, wired to each other; the coach, a played-through game and an opening tree open as closable pages after them"

	dashboard := self newDashboard.
	gamesPage := self newGamesPage.
	settingsElement := SettingsElement new.
	home := HomeElement new.
	home whenShowGamesDo: [ self showPage: #Games ].
	home whenGameChosenDo: [ :entry |
			self showPage: #Games.
			self selectGameId: entry gameId ].
	openings := OpeningsElement new.
	openings whenOpenDo: [ :tree | self openOpeningTree: tree ].
	helpElement := HelpElement new.
	^ super newNavigation
]

{ #category : 'actions' }
ChessCoachAppElement >> openAnalysisBoardAt: aChessPosition [
	"Analyse a position on its own board, in a closable page that replaces an open one. The tab button is kept in my userData (no new slot while windows are open); closing the page lets the background analysis go on."

	| element tab |
	(self userData at: #analysisTab ifAbsent: [ nil ]) ifNotNil: [ :open |
		self closeTab: open ].
	element := AnalysisBoardElement
		           session: session
		           position: aChessPosition
		           runner: backgroundRunner.
	tab := self
		       openTab: 'Analysis'
		       icon: 'outlined_insights'
		       page: (ChessCoachWidgets
				        page: 'Analysis board'
				        subtitle:
				        'Move the pieces; Stockfish evaluates every position.'
				        actions: { (self closeButtonDo: [
						         self closeTab:
							         (self userData at: #analysisTab ifAbsent: [ nil ]) ]) }
				        body: element).
	tab userData at: #analysisBoard put: element.
	self userData at: #analysisTab put: tab.
	^ element
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
	"Explore a tree in its own closable page named after it, replacing an open one. A new tree is built there. The tab keeps the tree element, so that its board follows the settings."

	| element |
	self closeTab: openingTreeTab.
	element := OpeningTreeElement
		           session: session
		           tree: anOpeningTree
		           runner: backgroundRunner.
	element whenGameChosenDo: [ :entry | self playThrough: entry ].
	element whenBuiltDo: [ openings updateTrees ].
	openingTreeTab := self
		                  openTab: anOpeningTree name
		                  icon: 'outlined_accounttree'
		                  page: (ChessCoachWidgets
				                   page: anOpeningTree name
				                   subtitle:
				                   'Your games compared with the database.'
				                   actions:
				                   { (self closeButtonDo: [
					                    self closeTab: openingTreeTab ]) }
				                   body: element).
	openingTreeTab userData at: #openingTree put: element.
	self applyPieceSet.
	element start.
	^ element
]

{ #category : 'coach' }
ChessCoachAppElement >> openReview: aCoachReview of: aGameIndexEntry [
	"Show a coach review in its own closable page, replacing an open one. Its game is queued for analysis (Stockfish analyses only the games you review), which the end of the marking pass needs. A moment can be played on from on an analysis board."

	self closeTab: coachTab.
	(session isAnalysed: aGameIndexEntry) ifFalse: [
		session analysisQueue enqueue: aGameIndexEntry ].
	coach := CoachElement new.
	coach backgroundRunner: backgroundRunner.
	coach session: session entry: aGameIndexEntry review: aCoachReview.
	self applyPieceSet.
	coach whenExitDo: [ self exitCoach ].
	coach whenAnalyseDo: [ :position |
		self openAnalysisBoardAt: position ].
	coachTab := self
		            openTab: 'Coach'
		            icon: 'outlined_school'
		            page: (ChessCoachWidgets
				             page:
				             aGameIndexEntry players first , ' – '
				             , aGameIndexEntry players second
				             subtitle: 'Review with the coach'
				             actions: coach titleActions
				             body: coach).
	^ coach
]

{ #category : 'app' }
ChessCoachAppElement >> opened [

	self startBackgroundAnalysis
]

{ #category : 'accessing' }
ChessCoachAppElement >> openings [

	^ openings
]

{ #category : 'settings' }
ChessCoachAppElement >> pageRoots [
	"The pages that may be hidden when the theme changes"

	^ {
		  self.
		  dashboard.
		  gamesPage.
		  settingsElement.
		  openings }
]

{ #category : 'actions' }
ChessCoachAppElement >> playThrough: aGameIndexEntry [
	"Look at the game move by move in its own closable page named after its players, replacing an open one. Its tab shows my opponent. The title has buttons to analyse the shown position on its own board and to copy it (FEN) or the game (PGN)."

	| game colors title opponent |
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
	opponent := colors asArray = #( #white )
		            ifTrue: [ aGameIndexEntry players second ]
		            ifFalse: [ aGameIndexEntry players first ].
	playThroughTab := self
		                  openTab: (opponent truncateTo: 10)
		                  icon: 'outlined_slideshow'
		                  page: (ChessCoachWidgets
				                   page: title
				                   subtitle: aGameIndexEntry date
				                   actions: { (ToButton new
						                    labelText: 'Analyse';
						                    icon:
							                    ((ToMaterialDesignIconProvider iconNamed:
									                      'outlined_insights')
								                     extent: 16 @ 16;
								                     yourself);
						                    tooltipText:
						                    'Play on from the position on the board, with Stockfish';
						                    clickAction: [
						                    self openAnalysisBoardAt:
							                    playThrough boardElement chessPosition ];
						                    yourself) } , (ChessCoachWidgets
						                    exportButtonsForBoard:
						                    playThrough boardElement
						                    game: game)
					                   ,
					                   { (self closeButtonDo: [
						                    self closeTab: playThroughTab ]) }
				                   body: playThrough).
	^ playThrough
]

{ #category : 'accessing' }
ChessCoachAppElement >> playThroughTab [

	^ playThroughTab
]

{ #category : 'app' }
ChessCoachAppElement >> quietText [

	^ 'All quiet. Time for another mate.'
]

{ #category : 'accessing' }
ChessCoachAppElement >> refreshButton [

	^ refreshButton
]

{ #category : 'accessing' }
ChessCoachAppElement >> reviewChoices [

	^ {
		  ('All reviews' -> nil).
		  ('Not reviewed' -> 'unreviewed').
		  ('In progress' -> 'inProgress').
		  ('Reviewed' -> 'reviewed') }
]

{ #category : 'accessing' }
ChessCoachAppElement >> reviewSelect [

	^ reviewSelect
]

{ #category : 'accessing' }
ChessCoachAppElement >> reviewStateOf: aGameIndexEntry [

	^ (reviewStates ifNil: [ Dictionary new ])
		  at: aGameIndexEntry gameId
		  ifAbsent: [ 'unreviewed' ]
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
	"Connect to the session and open on Home. The first time, run the setup wizard."

	super session: aChessCoachSession.
	session announcer
		when: ChessCoachSessionChanged
		do: [ :announcement | self inUIDo: [ self updateFromSession ] ]
		for: self.
	session announcer
		when: AnalysisQueueChanged
		do: [ :announcement |
			self inUIDo: [ self analysisStateChangedOf: announcement gameId ] ]
		for: self.
	settingsElement backgroundRunner: backgroundRunner.
	settingsElement session: session.
	settingsElement whenSetupRequestedDo: [ self showWizard ].
	openings session: session.
	self updateFromSession.
	home session: session.
	helpElement session: session.
	self showPage: #Home.
	session isFirstRun ifTrue: [ self showWizard ]
]

{ #category : 'app' }
ChessCoachAppElement >> settingChanged: aKey [
	"The boards follow the piece set and colours"

	super settingChanged: aKey.
	(#( 'pieceSet' 'boardTheme' ) includes: aKey) ifTrue: [
		self applyPieceSet ]
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

{ #category : 'app' }
ChessCoachAppElement >> showActionFor: aNotification [
	"New games are shown on the Games page"

	^ aNotification kind = #newGames
		  ifTrue: [ [ self showPage: #Games ] ]
		  ifFalse: [ nil ]
]

{ #category : 'settings' }
ChessCoachAppElement >> showDefaultPane [
	"The view of the selected game, or a hint"

	self showInPane: (gameView ifNil: [
				 ToElement new
					 layout: (BlLinearLayout vertical alignCenter cellSpacing: 12);
					 matchParent;
					 addChild: (ChessCoachWidgets logo: 128);
					 addChild: (ToLabel text: 'Pick a game. The mate is ready.');
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
ChessCoachAppElement >> showWizard [
	"The first-run setup replaces the pages until it is finished, between the title bar and the status line"

	| wizard |
	wizard := SetupWizardElement new.
	wizard backgroundRunner: backgroundRunner.
	wizard session: session.
	wizard whenFinishedDo: [
			wizard removeFromParent.
			self addChild: navigation at: 3.
			self updateFromSession.
			self showPage: #Games ].
	navigation removeFromParent.
	self addChild: wizard at: 3.
	^ wizard
]

{ #category : 'accessing' }
ChessCoachAppElement >> speedChoices [
	"As the speeds, with an All that says what it is about"

	^ self speeds collect: [ :each |
			  (each value ifNil: [ 'All time controls' ] ifNotNil: [ each key ])
			  -> each value ]
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

{ #category : 'accessing' }
ChessCoachAppElement >> speedSelect [

	^ speedSelect
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

{ #category : 'app' }
ChessCoachAppElement >> statusLineExtras [
	"The background analysis and missing dependencies"

	analysisLabel := ToLabel text: ''.
	dependencyLabel := ToLabel text: ''.
	^ {
		  analysisLabel.
		  dependencyLabel }
]

{ #category : 'navigation' }
ChessCoachAppElement >> tabClosed: aTabButton wasSelected: aBoolean [
	"A closable page was closed, from its tab or from its own close button. If it was showing, go back to the page it came from rather than to the neighbouring tab, unless a new page of the same kind replaced it. Toplo checks the neighbour in a postponed action queued after this event, so the page is shown one postponed action later. A closed analysis board lets the background analysis go on."

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
								openingTreeTab ifNil: [ self showPage: #Openings ] ] ] ] ].
	aTabButton == (self userData at: #analysisTab ifAbsent: [ nil ])
		ifTrue: [
				(aTabButton userData at: #analysisBoard) close.
				self userData removeKey: #analysisTab ]
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

{ #category : 'updating' }
ChessCoachAppElement >> updateDashboard [
	"The mistakes of the time control chosen on the Stats page, remembered in the settings"

	dashboard speed: (session settings at: 'statsSpeed').
	dashboard
		database: (session mistakeDatabaseWithSpeed: dashboard speed)
		times: session reviewTimes
]

{ #category : 'updating' }
ChessCoachAppElement >> updateFromSession [
	"Reload the table, keeping the selected game selected when it is still listed. The dropdowns choose the games"

	| selectedId listed index |
	refreshButton enabled: session canImport.
	loadMoreButton enabled: session canImport.
	self updateDashboard.
	selectedId := self selectedEntry ifNotNil: [ :entry | entry gameId ].
	reviewStates := session reviewStates.
	listed := (session gamesPassing: self gameFilter) asArray.
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
