Class {
	#name : 'ChessCoachAppElementTest',
	#superclass : 'TestCase',
	#instVars : [
		'api',
		'session',
		'app',
		'scripter'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
ChessCoachAppElementTest >> click: anElement [
	"Show the page that holds anElement (Settings or Games) when it isn't shown, then click it"

	#( #Settings #Games ) do: [ :page |
			anElement isAttachedToSceneGraph ifFalse: [
					app showPage: page.
					scripter pulse ] ].
	scripter testClick onChildFromBlock: [ :root | anElement ].
	scripter syncContinue.
	scripter pulse
]

{ #category : 'helpers' }
ChessCoachAppElementTest >> isInATab: anElement [

	| each |
	each := anElement.
	[ each notNil ] whileTrue: [
			(each isKindOf: ToTabButton) ifTrue: [ ^ true ].
			each := each parent ].
	^ false
]

{ #category : 'helpers' }
ChessCoachAppElementTest >> newAppElement [

	^ ChessCoachAppElement new
		  backgroundRunner: [ :work | work value ];
		  session: session;
		  yourself
]

{ #category : 'helpers' }
ChessCoachAppElementTest >> scripterOn: anAppElement [

	| aScripter |
	aScripter := BlDevScripter new.
	aScripter element: anAppElement.
	aScripter space extent: 1200 @ 700.
	aScripter pulse.
	^ aScripter
]

{ #category : 'running' }
ChessCoachAppElementTest >> setUp [
	"Setup is marked done: the wizard has its own test. The tests start on Games, laid out."

	super setUp.
	api := LichessAPIClientStub withGames: 25.
	session := api newSessionOn: FileSystem memory root.
	session settings at: 'setupDone' put: true.
	app := self newAppElement.
	scripter := self scripterOn: app.
	app showPage: #Games.
	scripter pulse.
	scripter pulse
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testAppTheme [

	| settings |
	scripter space extent: 1200 @ 1200.
	app showPage: #Settings.
	scripter pulse.
	settings := app settingsElement.
	self deny: (app space root localTheme isKindOf: ToRawDarkTheme).
	self click: (settings buttonLabeled: 'Dark').
	scripter pulse.
	self assert: session settings appTheme equals: 'Dark'.
	self assert: (settings texts includes: '✓ Dark').
	self assert: (app space root localTheme isKindOf: ToRawDarkTheme).
	self click: (settings buttonLabeled: 'Light').
	scripter pulse.
	self assert: session settings appTheme equals: 'Light'.
	self deny: (app space root localTheme isKindOf: ToRawDarkTheme)
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testArrowKeysMoveTheGameSelection [

	self click: app loginButton.
	self click: app loadMoreButton.
	app selectGameAt: 1.
	scripter pulse.
	app gameList requestFocus.
	scripter keyClick: KeyboardKey down.
	scripter syncContinue.
	self assert: app selectedEntry equals: app games second.
	scripter keyClick: KeyboardKey up.
	scripter syncContinue.
	self assert: app selectedEntry equals: app games first
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testClosingTheShownGamePageGoesBackToGames [

	self click: app loginButton.
	self click: app loadMoreButton.
	app selectGameAt: 1.
	scripter pulse.
	app playThrough: app selectedEntry.
	scripter pulse.
	app closeTab: app playThroughTab.
	scripter pulse.
	self assert: app gameView isAttachedToSceneGraph
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testCoachAndPlayThroughOpenInClosableTabs [

	| coach coachTab |
	self click: app loginButton.
	self click: app loadMoreButton.
	app selectGameAt: 1.
	scripter pulse.
	app gameView newAnalysis.
	scripter pulse.
	coach := app coach.
	self assert: coach isAttachedToSceneGraph.
	self
		assert: (app navigation items asArray collect: [ :each | each id ])
		equals: #( #Home #Stats #Games #Openings #Settings #Coach ).
	coachTab := app navigation items asArray last.
	app showPage: #Stats.
	scripter pulse.
	self assert: (coach review instVarNamed: #pausedAt) notNil.
	app showTab: coachTab.
	scripter pulse.
	self assert: (coach review instVarNamed: #pausedAt) isNil.
	app playThrough: app selectedEntry.
	scripter pulse.
	self assert: app navigation items size equals: 7.
	app navigation removeItem: coachTab.
	scripter pulse.
	self assert: app coach isNil.
	self assert: app navigation items size equals: 6
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testEveryPageTitleIsAtTheSamePlace [
	"The page titles, not the tab labels with the same text"

	| places |
	places := #( #Stats #Games #Settings ) collect: [ :page |
			          | title |
			          app showPage: page.
			          scripter pulse.
			          scripter pulse.
			          app space root allChildrenBreadthFirstDo: [ :each |
					          ((each isKindOf: ToLabel) and: [
							           each text asString = page asString and: [
								           each isAttachedToSceneGraph and: [
									           (self isInATab: each) not ] ] ]) ifTrue: [
						          title := each ] ].
			          title bounds inSpace topLeft ].
	self assert: places asSet size = 1 description: places printString
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testGamesListedWhileOnStatsShowLater [
	"As at startup with reviews: the list is filled while the app is on Stats, then the Games page is opened"

	app showPage: #Stats.
	scripter pulse.
	self click: app loginButton.
	self click: app loadMoreButton.
	scripter pulse.
	app showPage: #Games.
	scripter pulse.
	app selectGameAt: 1.
	scripter pulse.
	self deny: scripter space hasLayoutError.
	self assert: app gameView isAttachedToSceneGraph
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testHelpIconOpensItsTooltipOnClick [

	| icon helpScripter |
	icon := ChessCoachWidgets help: 'Some help'.
	helpScripter := BlDevScripter new.
	helpScripter element: (ToElement new
			 fitContent;
			 padding: (BlInsets all: 30);
			 addChild: icon;
			 yourself).
	helpScripter pulse.
	helpScripter testClick onChildFromBlock: [ :root | icon ].
	helpScripter syncContinue.
	helpScripter pulse.
	self assert: icon currentTooltipWindow notNil.
	self assert: icon currentTooltipWindow isOpened
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testHomeIsThePageItOpensOn [

	| other |
	other := self newAppElement.
	self assert: other navigation items asArray first id equals: #Home.
	other home update.
	self assert: other home children notEmpty
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLichessErrorIsShownInline [

	self click: app loginButton.
	api error: (LichessError new messageText: 'rate limited').
	self click: app loadMoreButton.
	self assert: app statusLabel text asString equals: 'rate limited'
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLichessUsernameInSettings [

	| settings |
	app showPage: #Settings.
	scripter pulse.
	settings := app settingsElement.
	self deny: app loadMoreButton isEnabled.
	settings lichessField text: 'alice'.
	settings validateLichess.
	scripter pulse.
	self assert: session username equals: 'alice'.
	self deny: session isLoggedIn.
	self assert: (settings texts includes: 'OK: alice').
	self assert: app loadMoreButton isEnabled
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLoadMoreAddsRows [

	| texts |
	self click: app loginButton.
	self click: app loadMoreButton.
	self assert: app games size equals: 20.
	texts := OrderedCollection new.
	app gameTable allChildrenBreadthFirstDo: [ :each |
		(each isKindOf: ToLabel) ifTrue: [ texts add: each text asString ] ].
	self assert: (texts includesAll:
			 #( 'White' 'Black' 'Result' 'Date' 'Time control' 'alice' 'Stockfish level 3'
			    '1-0' '1970-01-01' ))
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLoadMoreButtonIsVisibleBelowTheList [

	| buttonBounds target |
	buttonBounds := app loadMoreButton bounds inSpace bounds.
	self assert: buttonBounds height > 0.
	self assert: buttonBounds bottom <= 700.
	self assert: app gameTable width equals: 630.
	target := app space root findMouseEventTargetAt: buttonBounds center.
	self assert: (target == app loadMoreButton or: [
			 target allParentsInclude: app loadMoreButton ])
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLoginShowsLogoutButton [

	self click: app loginButton.
	self assert: app loginButton labelText asString equals: 'Logout'.
	self assert: app loadMoreButton isEnabled
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLogoutKeepsGamesListed [

	self click: app loginButton.
	self click: app loadMoreButton.
	self click: app loginButton.
	self assert: app loginButton labelText asString equals: 'Login'.
	self assert: app games size equals: 20
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testNavigation [

	| games stats header |
	self
		assert: app gamesPage isAttachedToSceneGraph
		description: 'starts on Games without reviews'.
	self deny: app dashboard isAttachedToSceneGraph.
	header := app navigation header.
	self assert: header bounds inSpace left equals: 0.
	self
		assert: header height > header width
		description: 'tabs in a column on the left'.
	app showPage: #Stats.
	scripter pulse.
	self assert: app dashboard isAttachedToSceneGraph.
	self deny: app gamesPage isAttachedToSceneGraph.
	games := app gamesPage.
	app showPage: #Games.
	scripter pulse.
	self assert: app gamesPage == games description: 'pages are kept'.
	stats := app pageButton: #Stats.
	self assert: stats labelText asString equals: 'Stats'
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testNewAnalysisMarksThenReviewsAndIsListed [

	| engine queue coach review |
	self click: app loginButton.
	self click: app loadMoreButton.
	engine := StockfishEngineStub new.
	session analyser: (GameAnalyser engine: engine).
	session explorer: LichessExplorerClientStub new.
	session classifier: (AnswerClassifier
			 client: (OllamaClientStub new replyContent: '{"tags":[]}')
			 taxonomy: MistakeTaxonomy default).
	queue := AnalysisQueue
		         session: session
		         analyser: (GameAnalyser engine: engine).
	session analysisQueue: queue.
	app selectGameAt: 2.
	scripter pulse.
	app gameView newAnalysis.
	scripter pulse.
	coach := app coach.
	self assert: coach mode equals: #marking.
	self
		assert: queue pendingGameIds first
		equals: app games second gameId.
	coach showPly: 1.
	coach noteField text: 'felt wrong'.
	coach markShown.
	review := coach review.
	self assert: (review isMarked: 1).
	coach doneMarking.
	scripter pulse.
	self assert: coach mode equals: #moment.
	self assert: coach shownMoment ply equals: 1.
	self assert: coach shownMoment isMarked.
	coach stop.
	scripter pulse.
	self assert: coach mode equals: #list.
	app exitCoach.
	scripter pulse.
	self assert: app coach isNil.
	self assert: app gameView isAttachedToSceneGraph.
	self assert:
		(app gameView reviewsZone children first children first labelText
			 asString beginsWith: 'Analysis 1 · ').
	session deleteReview: review.
	app gameView updateReviews.
	self assert: (session reviewsFor: app selectedEntry) isEmpty.
	self
		assert: app gameView reviewsZone children first text asString
		equals: 'No analysis yet.'
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testOnlyReviewedGamesAreQueuedForAnalysis [

	| queue |
	self click: app loginButton.
	self click: app loadMoreButton.
	queue := AnalysisQueue
		         session: session
		         analyser: (GameAnalyser engine: StockfishEngineStub new).
	session analysisQueue: queue.
	app startBackgroundAnalysis.
	app updateFromSession.
	self assert: queue pendingGameIds isEmpty.
	app selectGameAt: 2.
	scripter pulse.
	app gameView newAnalysis.
	scripter pulse.
	self
		assert: queue pendingGameIds asArray
		equals: { app games second gameId }.
	queue stop
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testOpeningsBuildAnOpeningTree [

	| tree element |
	self click: app loginButton.
	self click: app loadMoreButton.
	session explorer: LichessExplorerClientStub new.
	app showPage: #Openings.
	scripter pulse.
	self assert: app openings isAttachedToSceneGraph.
	tree := app openings newTree.
	self assert: tree ratings equals: #(  ).
	element := app openOpeningTree: tree.
	scripter pulse.
	scripter pulse.
	self assert: element isAttachedToSceneGraph.
	self assert: element message equals: nil.
	self assert: tree builtOn notNil.
	self assert: session openingTrees size equals: 1
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testOpeningsDropdownListsItsOptions [

	| select |
	select := OpeningsElement new newSelect: {
			          ('One' -> 1).
			          ('Two' -> 2) }.
	scripter space root addChild: select popupListElement.
	scripter pulse.
	self assert: select popupListElement isAttachedToSceneGraph.
	self assert: select selectedDataItem value equals: 1
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testReviewedGamesHaveAnIconAndCanBeLeftOut [

	| games reviewedId |
	session login.
	session loadMoreGames.
	scripter pulse.
	games := app games.
	reviewedId := games first gameId.
	session saveReview: (session newReviewFor: games first).
	scripter pulse.
	self assert: (app isReviewed: games first).
	self deny: (app isReviewed: games second).
	self click: app notReviewedButton.
	self assert: app notReviewedButton isChecked.
	self assert: app games size equals: games size - 1.
	self deny:
		(app games anySatisfy: [ :each | each gameId = reviewedId ]).
	(Delay forMilliseconds: 600) wait.
	self click: app notReviewedButton.
	self
		deny: app notReviewedButton isChecked
		description: 'unchecked by the second click'.
	self assert: app games size equals: games size
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testRowsShowTheAnalysisState [

	| queue first |
	self click: app loginButton.
	self click: app loadMoreButton.
	queue := AnalysisQueue
		         session: session
		         analyser: (GameAnalyser engine: StockfishEngineStub new).
	session analysisQueue: queue.
	queue enqueueUnanalysed.
	scripter pulse.
	first := app games first.
	self
		assert: (app analysisIconNameFor: first)
		equals: 'outlined_hourglassempty'.
	self assert:
		(app analysisLabel text asString includesSubstring: '20 games left').
	queue runNext.
	scripter pulse.
	self
		assert: (app analysisIconNameFor: first)
		equals: 'outlined_checkcircle'.
	self assert:
		(app analysisLabel text asString includesSubstring: '19 games left')
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testSelectingARowOpensTheGameView [

	| info |
	self click: app loginButton.
	self click: app loadMoreButton.
	scripter pulse.
	self click: app gameRows first.
	self assert: app gameView isAttachedToSceneGraph.
	self assert: app selectedEntry == app games first.
	self
		assert: app gameView reviewsZone children first text asString
		equals: 'No analysis yet.'.
	info := app gameView infoLines.
	self assert: (info first beginsWith: 'White: ').
	self assert: (info second beginsWith: 'Black: ').
	self assert: info last equals: 'Stockfish: not analysed yet'
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testSettingsPage [

	| settings chessCom |
	chessCom := ChessComAPIClientStub new.
	chessCom
		at: 'https://api.chess.com/pub/player/bob'
		answer: (Dictionary new
				 at: 'username' put: 'bob';
				 yourself).
	session chessComAPIClient: chessCom.
	session analyser: (GameAnalyser engine: StockfishEngineStub new).
	session classifier: (AnswerClassifier
			 client: (OllamaClientStub new replyContent:
					  '{"tags":[{"tag":"missed-opponent-threat","confidence":0.9}]}')
			 taxonomy: MistakeTaxonomy default).
	"The whole page fits without scrolling"
	scripter space extent: 1200 @ 1800.
	app showPage: #Settings.
	scripter pulse.
	settings := app settingsElement.
	self assert: settings isAttachedToSceneGraph.
	self assert: (settings texts includes: 'Depth: 18').
	self click: (settings buttonLabeled: '+').
	self assert: session settings gamesPerLoad equals: 30.
	self assert: (settings texts includes: 'Games per Load more: 30').
	self click: (settings buttonLabeled: 'Livius').
	self assert: session settings pieceSet equals: 'Livius'.
	self assert:
		(settings previewBoard pieceSet isKindOf: LiviusPieceSet).
	self click: (settings buttonLabeled: 'Blue').
	self assert: session settings boardTheme equals: 'Blue'.
	self assert: settings previewBoard theme equals: 'Blue'.
	settings chessComField text: 'nobody'.
	self click: (settings buttonLabeled: 'Validate').
	self assert:
		(settings texts includes: 'Not found: no such Chess.com player').
	self assert: session chessComUsername isNil.
	settings chessComField text: 'Bob'.
	"A second click on the same button right away would count as a double click"
	settings validateChessCom.
	scripter pulse.
	self assert: session chessComUsername equals: 'Bob'.
	self click: (settings buttonLabeled: 'Test').
	self assert: (settings texts includes: 'OK: Stockfish stub').
	self click: (settings buttonLabeled: 'Load models').
	self assert: (settings texts includes: '2 models installed').
	self click: (settings buttonLabeled: 'llama3.1:8b').
	self assert: session settings ollamaModel equals: 'llama3.1:8b'.
	self assert:
		(settings texts includes: 'Validated only with qwen2.5:7b-instruct').
	self click: (settings buttonLabeled: 'Long thinks').
	self deny: (session settings at: 'findLongThinks')
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testSetupWizard [

	| wizard |
	session settings at: 'setupDone' put: false.
	self assert: session isFirstRun.
	wizard := app showWizard.
	scripter pulse.
	self deny: app navigation isAttachedToSceneGraph.
	self assert: wizard currentStep equals: #welcome.
	wizard next.
	self assert: wizard currentStep equals: #accounts.
	self assert: (wizard texts includes: 'Login').
	session login.
	wizard next.
	self assert: (wizard texts includes:
			 'If Test fails, install it with: brew install stockfish').
	wizard next.
	self assert: wizard currentStep equals: #ollama.
	wizard next.
	self assert: wizard currentStep equals: #done.
	wizard finish.
	scripter pulse.
	self assert: (session settings at: 'setupDone').
	self assert: app navigation isAttachedToSceneGraph.
	self assert: app games size equals: 20.
	self deny: session isFirstRun
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testSortingKeepsTheShownGameSelected [

	| reviewed column |
	session login.
	session loadMoreGames.
	scripter pulse.
	reviewed := app games last.
	session saveReview: (session newReviewFor: reviewed).
	scripter pulse.
	app selectGameAt: app games size.
	scripter pulse.
	column := app gameTable columns last.
	column nextSort.
	app gameTable dispatchEvent:
		(ToTableColumnSortRequestEvent column: column).
	scripter pulse.
	self assert:
		(app games first == reviewed or: [ app games last == reviewed ]).
	self
		deny: app games last == reviewed
		description: 'reviewed games first'.
	self assert:
		(app games at: app gameList selectionModel firstIndex) == reviewed
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testSpeedFiltersAreToggleButtonsOnOneRow [

	| buttons |
	buttons := #( nil 'bullet' 'blitz' 'rapid' 'classical' 'correspondence' )
		           collect: [ :each | app speedButtonFor: each ].
	self assert:
		(buttons allSatisfy: [ :each | each isKindOf: ToToggleButton ]).
	self assert: buttons first isChecked.
	self assert:
		(buttons allButFirst noneSatisfy: [ :each | each isChecked ]).
	self
		assert:
		(buttons collect: [ :each | each bounds inSpace top ]) asSet size
		equals: 1.
	app filterBySpeed: 'rapid'.
	self assert: (app speedButtonFor: 'rapid') isChecked.
	self deny: buttons first isChecked
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testStartsLoggedOut [

	self assert: app loginButton labelText asString equals: 'Login'.
	self assert: app loadMoreButton isDisabled.
	self assert: app games isEmpty.
	self assert: app gameView isNil
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testStatsFilterByTimeControl [

	app showPage: #Stats.
	scripter pulse.
	app dashboard chooseSpeed: 'rapid'.
	scripter pulse.
	self assert: app dashboard speed equals: 'rapid'.
	self assert: (app dashboard
			 allChildrenBreadthFirstDetect: [ :each |
					 (each isKindOf: ToToggleButton) and: [
						 each isChecked and: [ each labelText asString = 'Rapid' ] ] ]
			 ifFound: [ :each | true ]
			 ifNone: [ false ])
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testSwitchingBackToGamesWithGamesListed [
	"The list is reloaded while its page is hidden; the selection is kept and the page lays out again when it comes back"

	self click: app loginButton.
	self click: app loadMoreButton.
	app selectGameAt: 3.
	scripter pulse.
	app showPage: #Stats.
	scripter pulse.
	app updateFromSession.
	scripter pulse.
	app showPage: #Games.
	scripter pulse.
	self assert: app selectedEntry == app games third.
	app selectGameAt: 2.
	scripter pulse.
	self deny: scripter space hasLayoutError.
	self assert: app gameView isAttachedToSceneGraph
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testTheBellShowsUnreadNotifications [

	self deny: app bellBadge isVisible description: 'no dot at first'.
	session notifications post: (ChessCoachNotification
			 key: 'new-games'
			 kind: #newGames
			 title: '2 new games'
			 text: 'Downloaded from your accounts').
	scripter pulse.
	self assert: app bellBadge isVisible description: 'dot after posting'.
	self
		assert: app bell bounds inSpace right > (app space extent x - 60)
		description: 'bell at the right'.
	BlSpace simulateMouseDownOn: app bell.
	scripter pulse.
	self
		assert: app notificationsWindow currentWindow notNil
		description: 'popup open'.
	self assert: session notifications unreadCount equals: 0.
	scripter pulse.
	self deny: app bellBadge isVisible description: 'no dot once read'
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testTheGameListScrollbarIsBesideTheRows [

	| scrollbar |
	self click: app loginButton.
	self click: app loadMoreButton.
	scripter pulse.
	scrollbar := app gameList children detect: [ :each |
		             each isKindOf: ToScrollbarElement ].
	self assert: scrollbar constraints ignoredByLayout.
	self
		assert: app gameList innerElement bounds inSpace bottom
		closeTo:
		app gameList bounds inSpace bottom - app gameList padding bottom
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testTheGameTableKeepsItsColumnsWhenFirstShownFromAnotherPage [
	"The app opens on Stats when there are reviewed mistakes: the table is first laid out in a hidden tab"

	| statsApp statsScripter lefts |
	statsApp := ChessCoachAppElement session: session.
	statsApp showPage: #Stats.
	statsScripter := self scripterOn: statsApp.
	statsApp showPage: #Games.
	4 timesRepeat: [ statsScripter pulse ].
	lefts := statsApp gameTable header cellContainers collect: [ :each |
		         each bounds inSpace left ].
	self assert: lefts asSet size equals: lefts size
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testUnexpectedErrorIsShownAndLogged [

	self click: app loginButton.
	api error: (ZeroDivide new messageText: 'boom').
	self click: app loadMoreButton.
	self assert: (app statusLabel text asString beginsWith:
			 'Something went wrong: ZeroDivide: boom').
	self assert:
		(session errorLog contents includesSubstring: 'ZeroDivide: boom')
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testUpdateButtonAppearsWhenANewerVersionExists [

	self assert: app updateButton visibility equals: BlVisibility gone.
	session updater: (ChessCoachUpdaterStub new
			 current: 'v1.1.1' tags: #( 'v1.2.0' ) failure: nil;
			 yourself).
	session checkForUpdate.
	scripter pulse.
	self assert: app updateButton visibility equals: BlVisibility visible.
	self
		assert: app updateButton labelText asString
		equals: 'Update to v1.2.0'
]
