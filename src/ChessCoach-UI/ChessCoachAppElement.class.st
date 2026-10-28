"
I am the chess-coach main window: a top bar (login/logout, refresh, user, status), the list of stored games with ""Load more"" on the left, and the analysis of the selected game on the right.
Network work runs through my backgroundRunner (a forked process by default); I update myself when my ChessCoachSession announces a change.
"
Class {
	#name : 'ChessCoachAppElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'loginButton',
		'cancelButton',
		'refreshButton',
		'loadMoreButton',
		'userLabel',
		'statusLabel',
		'gameList',
		'analysisPane',
		'analysis',
		'backgroundRunner'
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

{ #category : 'accessing' }
ChessCoachAppElement >> analysis [
	"The analysis of the selected game, or nil before one is selected"

	^ analysis
]

{ #category : 'private' }
ChessCoachAppElement >> analysisMarkFor: aGameIndexEntry [
	"A prefix showing the background analysis state of the game"

	| queue state |
	queue := session analysisQueue.
	state := queue stateOf: aGameIndexEntry.
	state = #ready ifTrue: [ ^ '✓ ' ].
	state = #queued ifTrue: [ ^ '⏳ ' ].
	state = #analysing ifTrue: [
			^ queue progress ifNil: [ '⚙ ' ] ifNotNil: [ :progress |
					  '⚙ ' , progress key printString , '/'
					  , progress value printString , ' ' ] ].
	^ ''
]

{ #category : 'analysis queue' }
ChessCoachAppElement >> analysisStateChangedOf: aGameIdOrNil [
	"Redraw the row of the game whose analysis state changed (every row when nil)"

	gameList dataAccessor withIndexDo: [ :entry :index |
			(aGameIdOrNil isNil or: [ entry gameId = aGameIdOrNil ]) ifTrue: [
				gameList dataAccessor at: index put: entry ] ]
]

{ #category : 'accessing' }
ChessCoachAppElement >> backgroundRunner: aBlock [
	"aBlock receives the work block to run; tests pass [ :work | work value ]"

	backgroundRunner := aBlock
]

{ #category : 'accessing' }
ChessCoachAppElement >> gameList [

	^ gameList
]

{ #category : 'private' }
ChessCoachAppElement >> inUIDo: aBlock [

	self enqueueTask: (BlTaskAction new action: aBlock)
]

{ #category : 'initialization' }
ChessCoachAppElement >> initialize [

	| body |
	super initialize.
	backgroundRunner := [ :aBlock |
	                    aBlock forkAt: Processor userBackgroundPriority ].
	self layout: BlLinearLayout vertical.
	self matchParent.
	body := ToElement new
		        layout: BlLinearLayout horizontal;
		        matchParent;
		        yourself.
	body addChild: self newGamesPane.
	body addChild: (analysisPane := self newAnalysisPane).
	self addChild: self newTopBar.
	self addChild: body
]

{ #category : 'accessing' }
ChessCoachAppElement >> loadMoreButton [

	^ loadMoreButton
]

{ #category : 'accessing' }
ChessCoachAppElement >> loginButton [

	^ loginButton
]

{ #category : 'actions' }
ChessCoachAppElement >> loginOrLogout [

	session isLoggedIn ifTrue: [ ^ session logout ].
	cancelButton visibility: BlVisibility visible.
	self runInBackground: [
			session login.
			self inUIDo: [ cancelButton visibility: BlVisibility gone ] ]
]

{ #category : 'initialization' }
ChessCoachAppElement >> newAnalysisPane [

	^ ToElement new
		  layout: BlFrameLayout new;
		  matchParent;
		  addChild: (ToEmpty new
				   labelText: 'Select a game';
				   yourself);
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
		addChild: gameList;
		addChild: loadMoreButton.
	^ pane
]

{ #category : 'initialization' }
ChessCoachAppElement >> newTopBar [

	| bar |
	bar := ToElement new
		       layout: (BlLinearLayout horizontal cellSpacing: 8);
		       hMatchParent;
		       vFitContent;
		       padding: (BlInsets all: 8);
		       yourself.
	loginButton := ToButton new
		               labelText: 'Login';
		               clickAction: [ self loginOrLogout ];
		               yourself.
	cancelButton := ToButton new
		                labelText: 'Cancel';
		                clickAction: [ session cancelLogin ];
		                visibility: BlVisibility gone;
		                yourself.
	refreshButton := ToButton new
		                 labelText: 'Refresh';
		                 clickAction: [
			                 self runInBackground: [ session refresh ] ];
		                 yourself.
	userLabel := ToLabel text: ''.
	statusLabel := ToLabel text: ''.
	bar
		addChild: loginButton;
		addChild: cancelButton;
		addChild: refreshButton;
		addChild: userLabel;
		addChild: statusLabel.
	^ bar
]

{ #category : 'accessing' }
ChessCoachAppElement >> refreshButton [

	^ refreshButton
]

{ #category : 'private' }
ChessCoachAppElement >> rowTextFor: aGameIndexEntry [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (self analysisMarkFor: aGameIndexEntry);
				  nextPutAll: (' – ' join: aGameIndexEntry players);
				  nextPutAll: ', ';
				  nextPutAll: aGameIndexEntry result;
				  nextPutAll: ', ';
				  nextPutAll: aGameIndexEntry date ]
]

{ #category : 'private' }
ChessCoachAppElement >> runInBackground: aBlock [
	"Run network work off the UI thread; show progress and any Lichess or network error inline"

	statusLabel text: 'Working…'.
	backgroundRunner value: [
			[
				aBlock value.
				self inUIDo: [ statusLabel text: '' ] ]
				on: LichessError , NetworkError
				do: [ :error |
				self inUIDo: [ statusLabel text: error messageText ] ] ]
]

{ #category : 'updating' }
ChessCoachAppElement >> selectedGameChanged [

	| index |
	index := gameList selectionModel firstIndex.
	(index isNil or: [ index = 0 ]) ifTrue: [ ^ self ].
	self showGame: (session gameFor: (gameList dataAccessor at: index))
]

{ #category : 'accessing' }
ChessCoachAppElement >> session: aChessCoachSession [

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
	self updateFromSession
]

{ #category : 'updating' }
ChessCoachAppElement >> showGame: aGame [

	analysis ifNil: [
			analysis := GameAnalysisElement new.
			analysisPane removeChildren.
			analysisPane addChild: analysis ].
	analysis game: aGame
]

{ #category : 'analysis queue' }
ChessCoachAppElement >> startBackgroundAnalysis [
	"Queue every unanalysed game and analyse them in the background; rows show their state"

	session analysisQueue
		enqueueUnanalysed;
		start
]

{ #category : 'accessing' }
ChessCoachAppElement >> statusLabel [

	^ statusLabel
]

{ #category : 'updating' }
ChessCoachAppElement >> updateFromSession [

	| loggedIn |
	loggedIn := session isLoggedIn.
	loginButton labelText: (loggedIn
			 ifTrue: [ 'Logout' ]
			 ifFalse: [ 'Login' ]).
	refreshButton enabled: loggedIn.
	loadMoreButton enabled: loggedIn.
	userLabel text: (session username ifNil: [ '' ]).
	session analysisQueue isRunning ifTrue: [
		session analysisQueue enqueueUnanalysed ].
	gameList dataAccessor removeAll.
	gameList dataAccessor addAll: session games
]

{ #category : 'accessing' }
ChessCoachAppElement >> userLabel [

	^ userLabel
]
