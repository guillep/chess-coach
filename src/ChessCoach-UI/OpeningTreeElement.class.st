"
I explore an opening tree: a board, my moves from the shown position against the database's, its games and the weak-spot lists. path holds the nodes clicked from the root.
"
Class {
	#name : 'OpeningTreeElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'tree',
		'backgroundRunner',
		'gameBlock',
		'board',
		'panel',
		'path',
		'entries',
		'newGames',
		'message',
		'builtBlock',
		'engineLines',
		'treePanel',
		'tabs'
	],
	#category : 'ChessCoach-UI-Openings',
	#package : 'ChessCoach-UI',
	#tag : 'Openings'
}

{ #category : 'instance creation' }
OpeningTreeElement class >> session: aChessCoachSession tree: anOpeningTree runner: aBlock [

	^ self new
		  session: aChessCoachSession
		  tree: anOpeningTree
		  runner: aBlock
]

{ #category : 'actions' }
OpeningTreeElement >> analyseWithEngine: anOpeningNode [
	"Ask Stockfish for its top moves, off the UI thread, since it takes a few seconds. They are not stored."

	session isEngineAvailable ifFalse: [ ^ self ].
	self inBackground: [
			| lines |
			lines := session analyser engine
				         analyse: anOpeningNode fen
				         multiPV: (session settings multiPV max: 3)
				         depth: session settings depth.
			self enqueueTask: (BlTaskAction new action: [
						 anOpeningNode == self shownNode ifTrue: [
								 engineLines := lines.
								 self refresh ] ]) ]
]

{ #category : 'accessing' }
OpeningTreeElement >> board [

	^ board
]

{ #category : 'building' }
OpeningTreeElement >> buildDatabase [

	| node |
	node := self shownNode.
	node database ifNil: [
			session canUseDatabase ifFalse: [
				^ panel addChild: (ToLabel text: 'Log in to Lichess') ].
			^ panel addChild: (ToButton new
					   labelText: 'Load database data';
					   clickAction: [ self loadDatabase ];
					   yourself) ].
	node topDatabaseMoves do: [ :each |
			panel addChild: (ToLabel text: ('{1} · {2} games · {3}' format: {
							  (each at: 'san').
							  (self thousands: (node gamesOfDatabaseMove: each)).
							  (self percent:
								   (node databaseScoreOf: (each at: 'uci') for: tree color)) })) ]
]

{ #category : 'building' }
OpeningTreeElement >> buildEngine [

	| position |
	session isEngineAvailable ifFalse: [
		^ panel addChild: (ToLabel text: 'Stockfish isn''t available') ].
	engineLines ifNil: [
		^ panel addChild: (ToLabel text: 'Calculating…') ].
	position := ChessPosition fromFEN: self shownNode fen.
	engineLines do: [ :each |
			each firstMove ifNotNil: [ :move |
					panel addChild: (ToLabel text: ('{1} · {2}' format: {
									  (position sanForUCI: move).
									  each scoreString })) ] ]
]

{ #category : 'building' }
OpeningTreeElement >> buildGames [

	entries ifNil: [
		^ panel addChild: (ToLabel text: 'Looking for them…') ].
	entries do: [ :each |
			panel addChild: (ToButton new
					 labelText: ('{1} – {2} · {3}' format: {
									  each players first.
									  each players second.
									  each date });
					 clickAction: [ gameBlock value: each ];
					 yourself) ]
]

{ #category : 'building' }
OpeningTreeElement >> buildHeader [

	treePanel addChild: (ChessCoachWidgets
			 section: 'This tree'
			 help: 'Rebuild counts the games again, including new ones.'
			 rows: {
					 (ChessCoachWidgets paragraph:
						  ('{1}: {2} games, built on {3}{4}' format: {
								   tree name.
								   tree gameCount.
								   tree builtOn.
								   ((newGames isNil or: [ newGames = 0 ])
									    ifTrue: [ '' ]
									    ifFalse: [
									    ', ' , newGames printString , ' new games match' ]) })).
					 (ToButton new
						  labelText: 'Rebuild';
						  clickAction: [ self rebuild ];
						  yourself) })
]

{ #category : 'building' }
OpeningTreeElement >> buildMoves [

	panel addChild: (self tableRow:
			 (#( 'Move' 'Games' 'You' 'DB' 'Time' ) collect: [ :each |
					  ToLabel new
						  text: each asRopedText bold;
						  yourself ])).
	self shownNode moves do: [ :each |
			| database row |
			database := self shownNode
				            databaseScoreOf: each uci
				            for: tree color.
			row := self tableRow: {
					       ((tree nodeAt: each nextKey)
						        ifNil: [ ToLabel text: each san ]
						        ifNotNil: [ :next |
								        ToButton new
									        labelText: each san;
									        clickAction: [ self goTo: next ];
									        yourself ]).
					       (ToLabel text: each games printString).
					       (ToLabel text: (self percent: each score)).
					       (ToLabel text: (self percent: database)).
					       (ToLabel text: (each averageSeconds
							         ifNil: [ '–' ]
							         ifNotNil: [ :seconds |
							         seconds rounded printString , ' s' ])) }.
			(self isBelowDatabase: each) ifTrue: [
					row addChild:
						((ToMaterialDesignIconProvider iconNamed: 'outlined_warning')
							 extent: 16 @ 16;
							 tooltipText: 'Scores at least 10 points below the database';
							 yourself) ].
			panel addChild: row ]
]

{ #category : 'building' }
OpeningTreeElement >> buildPath [

	| row |
	row := ToElement new
		       layout: BlFlowLayout horizontal;
		       hMatchParent;
		       vFitContent;
		       yourself.
	path withIndexDo: [ :node :index |
			row addChild: (ToButton new
					 labelText: (index = 1
							  ifTrue: [ 'Start' ]
							  ifFalse: [
									  ((path at: index - 1) moves detect: [ :each |
											   each nextKey = node key ]) san ]);
					 clickAction: [ self goTo: node ];
					 yourself) ].
	panel addChild: row
]

{ #category : 'building' }
OpeningTreeElement >> buildSpots: someSpots title: aTitle help: aHelpString [
	"The ten worst, each with where it happens"

	treePanel addChild: (ChessCoachWidgets
			 section: aTitle
			 help: aHelpString
			 rows:
				 (someSpots ifEmpty: [ { (ToLabel text: 'None') } ] ifNotEmpty: [
						  (someSpots first: (someSpots size min: 10)) collect: [ :each |
								  ToButton new
									  labelText: ('{1} · {2} games · {3}' format: {
													   (each positionLabelFrom: (tree nodeAt: each key)).
													   each games.
													   (self percent: each score) });
									  clickAction: [ self jumpTo: each ];
									  yourself ] ]))
]

{ #category : 'building' }
OpeningTreeElement >> buildWeakSpots [

	self
		buildSpots: tree scoreGapSpots
		title: 'Below the database'
		help:
		'Your moves with at least 5 games, scoring at least 10 points below the database, most points lost first. Only positions whose database data was loaded count, so this list grows as you explore.'.
	self
		buildSpots: tree lowScoreSpots
		title: 'Low score'
		help: 'Your moves with at least 5 games and a score below 40%.'.
	self
		buildSpots: tree prepGapSpots
		title: 'Prep gaps'
		help:
		'Opponent replies faced at least 3 times, where you score below 40%.'
]

{ #category : 'actions' }
OpeningTreeElement >> goTo: anOpeningNode [
	"Show a position: go back to it when it is on the path, otherwise extend the path. Its games are looked up, Stockfish is asked for its top moves, and its database data is fetched above the threshold in the settings."

	| index |
	index := path indexOf: anOpeningNode.
	index > 0
		ifTrue: [ path := path first: index ]
		ifFalse: [ path add: anOpeningNode ].
	entries := nil.
	engineLines := nil.
	message := nil.
	self refresh.
	self analyseWithEngine: anOpeningNode.
	self inBackground: [
			| found count |
			(anOpeningNode database isNil and: [
					 session canUseDatabase and: [
						 anOpeningNode games
						 > (session settings at: 'openingDatabaseMinGames') ] ])
				ifTrue: [ session fetchDatabaseOf: anOpeningNode in: tree ].
			found := session entriesOf: tree at: anOpeningNode key.
			count := session newGameCountOf: tree.
			self enqueueTask: (BlTaskAction new action: [
						 newGames := count.
						 anOpeningNode == self shownNode ifTrue: [
								 entries := found.
								 self refresh ] ]) ]
]

{ #category : 'private' }
OpeningTreeElement >> inBackground: aBlock [
	"Run aBlock off the UI thread. An error is shown on the page and appended to errors.log."

	backgroundRunner value: [
			[ aBlock value ]
				on: Error
				do: [ :error |
						session logError: error.
						self enqueueTask: (BlTaskAction new action: [
									 message := 'Something went wrong: '
									            ,
									            (error messageText ifNil: [ error class name ])
										            asString , ' (details in errors.log)'.
									 entries ifNil: [ entries := #(  ) ].
									 self refresh ]) ] ]
]

{ #category : 'testing' }
OpeningTreeElement >> isBelowDatabase: anOpeningMove [
	"Whether I score at least 10 points below the database, as the weak-spot list counts it"

	^ (self shownNode databaseScoreOf: anOpeningMove uci for: tree color)
		  ifNil: [ false ]
		  ifNotNil: [ :database | database - anOpeningMove score >= 0.1 ]
]

{ #category : 'actions' }
OpeningTreeElement >> jumpTo: anOpeningWeakSpot [
	"A weak spot is reached directly, so the path restarts at it and its position's tab is shown"

	path := OrderedCollection new.
	tabs selecter selectIndex: 1.
	self goTo: (tree nodeAt: anOpeningWeakSpot key)
]

{ #category : 'actions' }
OpeningTreeElement >> loadDatabase [

	| node |
	node := self shownNode.
	self inBackground: [
			session fetchDatabaseOf: node in: tree.
			self enqueueTask: (BlTaskAction new action: [ self refresh ]) ]
]

{ #category : 'accessing' }
OpeningTreeElement >> message [

	^ message
]

{ #category : 'initialization' }
OpeningTreeElement >> newPanel [

	^ ToElement new
		  layout: (BlLinearLayout vertical cellSpacing: 10);
		  hMatchParent;
		  vFitContent;
		  padding: (BlInsets
				   top: 8
				   left: 0
				   bottom: 0
				   right: 16);
		  yourself
]

{ #category : 'initialization' }
OpeningTreeElement >> newTab: aString panel: anElement [

	^ ToTabButton new
		  labelText: aString;
		  removable: false;
		  paneBuilder: [ :pane :button :holder |
			  pane addChild: (ChessCoachWidgets scrollable: anElement) ];
		  yourself
]

{ #category : 'building' }
OpeningTreeElement >> percent: aNumberOrNil [

	aNumberOrNil ifNil: [ ^ '–' ].
	^ (aNumberOrNil * 100) rounded printString , '%'
]

{ #category : 'actions' }
OpeningTreeElement >> rebuild [

	message := 'Building the tree…'.
	self refresh.
	self inBackground: [
			session buildOpeningTree: tree.
			self enqueueTask: (BlTaskAction new action: [
						 message := nil.
						 builtBlock value.
						 self showRoot ]) ]
]

{ #category : 'updating' }
OpeningTreeElement >> refresh [

	panel removeChildren.
	treePanel removeChildren.
	message ifNotNil: [
		panel addChild: (ChessCoachWidgets paragraph: message) ].
	tree builtOn ifNil: [ ^ self ].
	self buildHeader.
	path ifEmpty: [
			^ panel addChild:
				  (ChessCoachWidgets paragraph: (tree gameCount = 0
						    ifTrue: [
								    'No games match: ' , tree filtersDescription
								    ,
								    '. Only games you played count, so check your usernames in Settings too.' ]
						    ifFalse: [
						    'Only one game matches, so there is no tree to show yet.' ])) ].
	board chessPosition: (ChessPosition fromFEN: self shownNode fen).
	self buildWeakSpots.
	self buildPath.
	self
		section: 'Moves'
		help:
		'Moves played here, with my score after each one and the database''s score for my colour. A warning marks a move scoring at least 10 points below the database. A move without a button is where a line reached a single game.'
		build: [ self buildMoves ].
	self
		section: 'Engine top moves'
		help: 'Stockfish''s best moves here. Scores are from White''s side.'
		build: [ self buildEngine ].
	self
		section: 'Database top moves'
		help:
		'The five moves most played in the database from this position.'
		build: [ self buildDatabase ].
	self
		section: 'Games'
		help: 'Your games that reached this position.'
		build: [ self buildGames ]
]

{ #category : 'building' }
OpeningTreeElement >> section: aTitle help: aHelpString build: aBlock [
	"Build a bordered group: aBlock adds its rows to panel, which points to the group meanwhile"

	| page box |
	page := panel.
	box := ChessCoachWidgets
		       section: aTitle
		       help: aHelpString
		       rows: #(  ).
	panel := box.
	aBlock ensure: [ panel := page ].
	panel addChild: box
]

{ #category : 'initialization' }
OpeningTreeElement >> session: aChessCoachSession tree: anOpeningTree runner: aBlock [

	session := aChessCoachSession.
	tree := anOpeningTree.
	backgroundRunner := aBlock.
	gameBlock := [ :entry |  ].
	builtBlock := [ ].
	self layout: BlLinearLayout horizontal.
	self matchParent.
	board := ChessBoardElement new
		         matchParent;
		         yourself.
	board orientation: tree color.
	panel := self newPanel.
	treePanel := self newPanel.
	tabs := ToTabPaneElement new.
	tabs horizontal: false.
	tabs matchParent.
	tabs showAddTabItemButton: false.
	tabs addItem: (self newTab: 'This position' panel: panel).
	tabs addItem: (self newTab: 'Whole tree' panel: treePanel).
	tabs selecter selectIndex: 1.
	self
		addChild: board;
		addChild: (ToElement new
				 layout: BlFrameLayout new;
				 width: 460;
				 vMatchParent;
				 addChild: tabs;
				 yourself).
	path := OrderedCollection new
]

{ #category : 'actions' }
OpeningTreeElement >> showRoot [

	path := OrderedCollection new.
	tree root
		ifNil: [ self refresh ]
		ifNotNil: [ :root | self goTo: root ]
]

{ #category : 'accessing' }
OpeningTreeElement >> shownNode [

	^ path last
]

{ #category : 'actions' }
OpeningTreeElement >> start [
	"Build a new tree, or show a saved one at its root"

	tree builtOn ifNil: [ ^ self rebuild ].
	self showRoot
]

{ #category : 'building' }
OpeningTreeElement >> tableRow: someElements [
	"A row of fixed-width cells; the first one is the widest"

	| row |
	row := ToElement new
		       layout:
			       (BlLinearLayout horizontal alignCenterLeft cellSpacing: 6);
		       hMatchParent;
		       vFitContent;
		       yourself.
	someElements withIndexDo: [ :each :index |
			row addChild: (ToElement new
					 layout: BlLinearLayout horizontal alignCenterLeft;
					 width: (index = 1
							  ifTrue: [ 96 ]
							  ifFalse: [ 58 ]);
					 vFitContent;
					 addChild: each;
					 yourself) ].
	^ row
]

{ #category : 'building' }
OpeningTreeElement >> thousands: anInteger [
	"164086610 as 164,086,610"

	| digits |
	digits := anInteger printString.
	^ String streamContents: [ :stream |
			  digits withIndexDo: [ :digit :index |
					  stream nextPut: digit.
					  (index < digits size and: [ digits size - index \\ 3 = 0 ])
						  ifTrue: [ stream nextPut: $, ] ] ]
]

{ #category : 'accessing' }
OpeningTreeElement >> whenBuiltDo: aBlock [

	builtBlock := aBlock
]

{ #category : 'accessing' }
OpeningTreeElement >> whenGameChosenDo: aBlock [
	"aBlock receives the index entry of a game to open"

	gameBlock := aBlock
]
