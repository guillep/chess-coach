Class {
	#name : 'HomeElementTest',
	#superclass : 'TestCase',
	#instVars : [
		'root',
		'api',
		'session',
		'home',
		'space'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'support' }
HomeElementTest >> buttonsIn: anElement [
	"The buttons below anElement with their text, in order"

	| found |
	found := OrderedCollection new.
	anElement allChildrenBreadthFirstDo: [ :each |
		(each isKindOf: ToButton) ifTrue: [ found add: each ] ].
	^ found
]

{ #category : 'support' }
HomeElementTest >> click: aPrefix [
	"Click the first button whose text starts so"

	BlSpace simulateClickOn: ((self buttonsIn: home) detect: [ :each |
			 (self textOf: each) beginsWith: aPrefix ]).
	self pulse
]

{ #category : 'support' }
HomeElementTest >> pulse [

	3 timesRepeat: [ space pulse ]
]

{ #category : 'running' }
HomeElementTest >> setUp [

	super setUp.
	root := FileSystem memory root.
	api := LichessAPIClientStub withGames: 25.
	session := api newSessionOn: root.
	session login.
	session loadMoreGames.
	home := HomeElement new.
	space := BlSpace new.
	space extent: 1000 @ 800.
	space root addChild: home.
	home session: session.
	self pulse
]

{ #category : 'tests' }
HomeElementTest >> testCancelDiscardsChanges [

	self click: 'Customize'.
	self click: '+ Your numbers'.
	self click: 'Remove'.
	self click: 'Cancel'.
	self assert: home cards size equals: 4.
	self deny: (root / 'home.json') exists
]

{ #category : 'tests' }
HomeElementTest >> testCardsScaleWithTheWindow [

	| before |
	before := home cards first extent.
	space extent: 2000 @ 1600.
	self pulse.
	self assert: home cards first extent x > before x.
	self assert: home cards first extent y > before y.
	self
		assert: self widgets first cell extent
		equals: 12 @ 3
]

{ #category : 'tests' }
HomeElementTest >> testConfigureCyclesAnOptionLive [

	session homeConfiguration grid
		place: self widgets first
		at: (0 @ 0 extent: 12 @ 14).
	self click: 'Customize'.
	self click: 'Configure'.
	self click: 'Result: any'.
	self assert: (self widgets first filter at: 'result') equals: 'won'.
	self click: 'Result: won'.
	self assert: (self widgets first filter at: 'result') equals: 'lost'
]

{ #category : 'tests' }
HomeElementTest >> testDefaultHomeShowsItsFourCards [

	self assert: home cards size equals: 4
]

{ #category : 'tests' }
HomeElementTest >> testDraggingABarMovesTheCard [

	| widget bar |
	self click: 'Customize'.
	widget := self widgets last.
	bar := home cards last childWithId: #bar.
	BlSpace simulateDragOn: bar by: 0 @ -300.
	self pulse.
	self assert: widget cell top < 7
]

{ #category : 'tests' }
HomeElementTest >> testDraggingTheCornerResizesTheCard [

	| widget corner |
	self click: 'Customize'.
	widget := self widgets last.
	corner := home cards last childWithId: #corner.
	BlSpace simulateDragOn: corner by: -300 @ -120.
	self pulse.
	self assert: widget cell width < 12.
	self assert: widget cell height < 6
]

{ #category : 'tests' }
HomeElementTest >> testDroppingAndResizingSnapToCells [

	| widget |
	widget := self widgets last.
	home drop: widget at: 3 @ -50.
	self assert: widget cell origin equals: 0 @ 0.
	home resize: widget to: 1 @ 1.
	self assert: widget cell extent equals: widget class minimumExtent
]

{ #category : 'tests' }
HomeElementTest >> testEditingAddsAndDoneSaves [

	self click: 'Customize'.
	self click: '+ Your numbers'.
	self assert: home cards size equals: 5.
	self click: 'Done'.
	self assert: (root / 'home.json') exists.
	session homeConfiguration reload.
	self assert: self widgets size equals: 5
]

{ #category : 'tests' }
HomeElementTest >> testEditingTheTitleIsKeptOnDone [

	self click: 'Customize'.
	self click: 'Configure'.
	home titleField text: 'Mine'.
	self click: 'Done'.
	self assert: self widgets first title equals: 'Mine'
]

{ #category : 'tests' }
HomeElementTest >> testEveryUnreviewedMomentKeepsAReviewOpen [

	| moment |
	moment := '{"ply":10,"color":"black","kinds":["inaccuracy"],"pending":[],"answers":[],"candidates":{},"labels":[]}'.
	root / 'games' / 'g25.review-1.json' writeStreamDo: [ :stream |
		stream nextPutAll: '{"marking":false,"moments":[' , moment , ']}' ].
	self assert: (session reviewStates at: 'g25') equals: 'inProgress'
]

{ #category : 'tests' }
HomeElementTest >> testFilterCriteria [

	| filter |
	filter := GameFilter new.
	self
		assert: (session gamesPassing: filter) size
		equals: session games size.
	filter at: 'source' put: 'nowhere'.
	self assert: (session gamesPassing: filter) isEmpty.
	filter := GameFilter new.
	filter at: 'days' put: 1.
	filter at: 'source' put: session games first source.
	self assert:
		(session gamesPassing: filter) size <= session games size.
	filter := GameFilter new.
	filter at: 'speed' put: 'none'.
	self assert: (session gamesPassing: filter) isEmpty
]

{ #category : 'tests' }
HomeElementTest >> testGameWidgetsHonourTheirCount [

	{
		HomeSuggestionsWidget.
		HomeLatestGamesWidget } do: [ :class |
			| widget |
			widget := class atCell: (0 @ 0 extent: 6 @ 4).
			widget option: 'count' put: 3.
			self assert: (widget rowsOn: home) size equals: 3 ]
]

{ #category : 'tests' }
HomeElementTest >> testGameWidgetsWithoutMatchesSayNoGamesRightNow [

	HomeSuggestionsWidget withAllSuperclasses.
	{
		HomeSuggestionsWidget.
		HomeLatestGamesWidget } do: [ :class |
			| widget rows |
			widget := class atCell: (0 @ 0 extent: 6 @ 4).
			widget filterAt: 'source' put: 'nowhere'.
			rows := widget rowsOn: home.
			self assert: rows size equals: 1.
			self assert: rows first text asString equals: 'No games right now' ]
]

{ #category : 'tests' }
HomeElementTest >> testNarrowWindowStacksWithoutChangingCells [

	| cells tops |
	cells := self widgets collect: [ :each | each cell ].
	space extent: 500 @ 800.
	self pulse.
	home placeCards.
	self pulse.
	tops := home cards collect: [ :each | each position y ].
	self assert: tops asSet size equals: 4.
	self assert: (home cards allSatisfy: [ :each | each position x = 0 ]).
	self
		assert: (self widgets collect: [ :each | each cell ])
		equals: cells
]

{ #category : 'tests' }
HomeElementTest >> testNotificationsHonourKindsUnreadAndCount [

	| widget |
	#( #newGames #update #error ) doWithIndex: [ :kind :index |
			session notifications post: (ChessCoachNotification
					 key: 'k' , index printString
					 kind: kind
					 title: kind asString
					 text: '') ].
	widget := HomeNotificationsWidget atCell: (0 @ 0 extent: 6 @ 4).
	self assert: (widget rowsOn: home) size equals: 3.
	widget option: 'count' put: 2.
	self assert: (widget rowsOn: home) size equals: 2.
	widget option: 'count' put: nil.
	widget option: 'hiddenKinds' put: #( 'error' ).
	self assert: (widget rowsOn: home) size equals: 2.
	session notifications markAllRead.
	widget option: 'unreadOnly' put: true.
	self
		assert: (widget rowsOn: home) first text asString
		equals: 'No notifications'
]

{ #category : 'tests' }
HomeElementTest >> testNumbersShowWhatWasChosen [

	| widget texts |
	self writeReviewOf: 'g25' marking: true.
	widget := HomeNumbersWidget atCell: (0 @ 0 extent: 6 @ 4).
	texts := (widget rowsOn: home) collect: [ :each | each text asString ].
	self assert: texts first equals: '20 games'.
	self assert: texts second equals: '1 reviewed'.
	self assert: texts size equals: 3.
	widget option: 'numbers' put: #( 'winrate' 'streak' 'rating' ).
	texts := (widget rowsOn: home) collect: [ :each | each text asString ].
	self assert: (texts first beginsWith: 'Winrate: ').
	self assert: (texts second beginsWith: 'Winning streak: ')
		| (texts second beginsWith: 'Rating')
]

{ #category : 'tests' }
HomeElementTest >> testRemovingAConfiguredWidgetAsksFirst [

	self click: 'Customize'.
	self widgets first option: 'count' put: 2.
	self click: 'Remove'.
	self assert: home cards size equals: 4.
	self click: 'No'.
	self assert: home cards size equals: 4.
	self click: 'Remove'.
	self click: 'Yes'.
	self assert: home cards size equals: 3
]

{ #category : 'tests' }
HomeElementTest >> testResetAsksAndGoesBackToTheDefault [

	self click: 'Customize'.
	self click: 'Remove'.
	self assert: home cards size equals: 3.
	self click: 'Reset'.
	self click: 'Yes'.
	self assert: home cards size equals: 4
]

{ #category : 'tests' }
HomeElementTest >> testResultsPartitionTheGames [

	| counts |
	counts := #( 'won' 'lost' 'draw' ) collect: [ :result |
			          | filter |
			          filter := GameFilter new.
			          filter at: 'result' put: result.
			          (session gamesPassing: filter) size ].
	self assert: counts sum equals: session games size
]

{ #category : 'tests' }
HomeElementTest >> testReviewStates [

	| filter |
	self writeReviewOf: 'g25' marking: true.
	self writeReviewOf: 'g24' marking: false.
	self assert: (session reviewStates at: 'g25') equals: 'inProgress'.
	self assert: (session reviewStates at: 'g24') equals: 'reviewed'.
	#( 'inProgress' 'g25' 'reviewed' 'g24' ) pairsDo: [ :state :id |
			filter := GameFilter new.
			filter at: 'review' put: state.
			self
				assert:
					((session gamesPassing: filter) collect: [ :each | each gameId ])
						asArray
				equals: { id } ].
	filter := GameFilter new.
	filter at: 'review' put: 'unreviewed'.
	self assert: (session gamesPassing: filter) size equals: 18
]

{ #category : 'tests' }
HomeElementTest >> testSuggestionsPutGamesInProgressFirstAndLeaveFinishedOut [

	| games |
	self writeReviewOf: 'g20' marking: true.
	self writeReviewOf: 'g25' marking: false.
	games := session suggestedGames: GameFilter new.
	self assert: games first gameId equals: 'g20'.
	self deny: (games anySatisfy: [ :each | each gameId = 'g25' ]).
	self
		assert: (games collect: [ :each | each gameId ]) asSet size
		equals: games size
]

{ #category : 'support' }
HomeElementTest >> textOf: aButton [

	^ aButton label
		  ifNil: [ '' ]
		  ifNotNil: [ :label | label text asString ]
]

{ #category : 'support' }
HomeElementTest >> widgets [

	^ session homeConfiguration grid widgets
]

{ #category : 'support' }
HomeElementTest >> writeReviewOf: aGameId marking: aBoolean [

	root / 'games' / (aGameId , '.review-1.json') writeStreamDo: [
			:stream |
			stream nextPutAll: (STONJSON toString: (Dictionary new
						  at: 'marking' put: aBoolean;
						  at: 'moments' put: #(  );
						  yourself)) ]
]
