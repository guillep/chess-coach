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

	scripter testClick onChildFromBlock: [ :root | anElement ].
	scripter syncContinue.
	scripter pulse
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

	super setUp.
	api := LichessAPIClientStub withGames: 25.
	session := api newSessionOn: FileSystem memory root.
	app := self newAppElement.
	scripter := self scripterOn: app
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLichessErrorIsShownInline [

	self click: app loginButton.
	api error: (LichessError new messageText: 'rate limited').
	self click: app loadMoreButton.
	self assert: app statusLabel text asString equals: 'rate limited'
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLoadMoreAddsRows [

	self click: app loginButton.
	self click: app loadMoreButton.
	self assert: app gameList dataAccessor size equals: 20.
	self
		assert: (app rowTextFor: app gameList dataAccessor first)
		equals: 'alice – Stockfish level 3, 1-0, 1970-01-01'
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLoadMoreButtonIsVisibleBelowTheList [

	| buttonBounds target |
	buttonBounds := app loadMoreButton bounds inSpace bounds.
	self assert: buttonBounds height > 0.
	self assert: buttonBounds bottom <= 700.
	self assert: app gameList width equals: 280.
	target := app space root findMouseEventTargetAt: buttonBounds center.
	self assert: (target == app loadMoreButton or: [
			 target allParentsInclude: app loadMoreButton ])
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLoginShowsUserAndLogoutButton [

	self click: app loginButton.
	self assert: app loginButton labelText asString equals: 'Logout'.
	self assert: app userLabel text asString equals: 'tester'.
	self assert: app loadMoreButton isEnabled
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testLogoutKeepsGamesListed [

	self click: app loginButton.
	self click: app loadMoreButton.
	self click: app loginButton.
	self assert: app loginButton labelText asString equals: 'Login'.
	self assert: app gameList dataAccessor size equals: 20
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testSelectingARowOpensItsAnalysis [

	self click: app loginButton.
	self click: app loadMoreButton.
	app gameList selecter selectIndex: 1.
	scripter pulse.
	self assert: (app analysis game metadata at: 'White') equals: 'alice'
]

{ #category : 'tests' }
ChessCoachAppElementTest >> testStartsLoggedOut [

	self assert: app loginButton labelText asString equals: 'Login'.
	self assert: app loadMoreButton isDisabled.
	self assert: app gameList dataAccessor isEmpty.
	self assert: app analysis isNil
]
