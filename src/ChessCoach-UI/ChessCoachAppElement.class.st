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
		'backgroundRunner',
		'coachButton',
		'coach',
		'waitingEntry',
		'waitingLabel',
		'dashboard'
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
	"Redraw the row of the game whose analysis state changed (every row when nil); start the coach when the game it waits for is ready"

	| queue |
	gameList dataAccessor withIndexDo: [ :entry :index |
			(aGameIdOrNil isNil or: [ entry gameId = aGameIdOrNil ]) ifTrue: [
				gameList dataAccessor at: index put: entry ] ].
	waitingEntry ifNil: [ ^ self ].
	queue := session analysisQueue.
	(queue stateOf: waitingEntry) = #ready ifTrue: [
		^ self startCoachOn: waitingEntry ].
	((queue stateOf: waitingEntry) = #analysing and: [
		 queue progress notNil ]) ifTrue: [
			waitingLabel text:
				('Analysing the game… move {1} of {2}' format: {
						 queue progress key.
						 queue progress value }) ]
]

{ #category : 'accessing' }
ChessCoachAppElement >> backgroundRunner: aBlock [
	"aBlock receives the work block to run; tests pass [ :work | work value ]"

	backgroundRunner := aBlock
]

{ #category : 'accessing' }
ChessCoachAppElement >> coach [
	"The coach element while a review is open, or nil"

	^ coach
]

{ #category : 'accessing' }
ChessCoachAppElement >> coachButton [

	^ coachButton
]

{ #category : 'accessing' }
ChessCoachAppElement >> dashboard [

	^ dashboard
]

{ #category : 'coach' }
ChessCoachAppElement >> exitCoach [
	"Back to the analysis of the selected game (or the dashboard); the background analysis resumes"

	waitingEntry := nil.
	coach := nil.
	session analysisQueue resume.
	self showInPane: (analysis ifNil: [ dashboard ])
]

{ #category : 'accessing' }
ChessCoachAppElement >> gameList [

	^ gameList
]

{ #category : 'private' }
ChessCoachAppElement >> games [

	^ gameList dataAccessor asArray
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
	"The right pane starts on the mistakes dashboard (the landing)"

	dashboard := MistakesDashboardElement new.
	dashboard whenRecordSelectedDo: [ :record |
		self openCoachOnGameId: record gameId ].
	dashboard whenStartRequestedDo: [
			self games ifNotEmpty: [ :entries |
				self openCoachOnGameId: entries first gameId ] ].
	^ ToElement new
		  layout: BlFrameLayout new;
		  matchParent;
		  addChild: dashboard;
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
	coachButton := ToButton new
		               labelText: 'Review with coach';
		               clickAction: [ self openCoach ];
		               yourself.
	userLabel := ToLabel text: ''.
	statusLabel := ToLabel text: ''.
	bar
		addChild: loginButton;
		addChild: cancelButton;
		addChild: refreshButton;
		addChild: coachButton;
		addChild: userLabel;
		addChild: statusLabel.
	^ bar
]

{ #category : 'coach' }
ChessCoachAppElement >> openCoach [
	"Review the selected game with the coach, once its analysis is ready"

	| entry queue |
	entry := self selectedEntry ifNil: [ ^ self ].
	(session isAnalysed: entry) ifTrue: [ ^ self startCoachOn: entry ].
	queue := session analysisQueue.
	(queue stateOf: entry) = #unknown ifTrue: [ queue enqueueUnanalysed ].
	queue prioritise: entry.
	queue resume.
	waitingEntry := entry.
	waitingLabel := ToLabel text: 'Analysing the game…'.
	self showInPane: (ToElement new
			 layout: (BlLinearLayout vertical cellSpacing: 8);
			 padding: (BlInsets all: 16);
			 matchParent;
			 addChild: waitingLabel;
			 addChild: (ToButton new
					  labelText: 'Cancel';
					  clickAction: [ self exitCoach ];
					  yourself);
			 yourself)
]

{ #category : 'coach' }
ChessCoachAppElement >> openCoachOnGameId: aGameId [
	"Select the game in the list and review it with the coach"

	| index |
	index := self games findFirst: [ :each | each gameId = aGameId ].
	index = 0 ifTrue: [ ^ self ].
	gameList selecter selectIndex: index.
	self selectedGameChanged.
	self openCoach
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

	coach := nil.
	waitingEntry := nil.
	analysis ifNil: [ analysis := GameAnalysisElement new ].
	self showInPane: analysis.
	analysis game: aGame
]

{ #category : 'private' }
ChessCoachAppElement >> showInPane: anElement [

	analysisPane removeChildren.
	anElement removeFromParent.
	analysisPane addChild: anElement
]

{ #category : 'analysis queue' }
ChessCoachAppElement >> startBackgroundAnalysis [
	"Queue every unanalysed game and analyse them in the background; rows show their state"

	session analysisQueue
		enqueueUnanalysed;
		start
]

{ #category : 'coach' }
ChessCoachAppElement >> startCoachOn: aGameIndexEntry [
	"Pause the background analysis and open the review (moments and explorer data are fetched off the UI thread)"

	| review |
	waitingEntry := nil.
	session analysisQueue pause.
	self showInPane: (ToLabel text: 'Preparing the review…').
	backgroundRunner value: [
			review := session reviewFor: aGameIndexEntry.
			self inUIDo: [
					coach := CoachElement new.
					coach backgroundRunner: backgroundRunner.
					coach review: review.
					coach whenExitDo: [ self exitCoach ].
					self showInPane: coach ] ]
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
	dashboard database: session mistakeDatabase.
	gameList dataAccessor removeAll.
	gameList dataAccessor addAll: session games
]

{ #category : 'accessing' }
ChessCoachAppElement >> userLabel [

	^ userLabel
]
