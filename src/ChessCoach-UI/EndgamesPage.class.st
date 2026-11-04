"
The Endgames page, a Mamotreto list page: a table of the endgame configurations of my games (my pieces against my opponent's, kings and pawns not counted), sortable by every column, filtered by two dropdowns (how many pieces make an endgame, and whether a configuration has upsets), both remembered in the settings. Score % is my score in its games (a draw is half a point). Saved is how many of the games I entered at 'worse' or below I didn't lose; Converted how many I entered at 'better' or above I won. Upsets counts the surprises both ways: the saved games (for me) plus the games I entered better and didn't win (against me).
The pane shows the selected configuration: an Overview tab (results by pawns) and a Games tab (a table of its games). Play through, on top of the pane, opens the selected game at the move where it entered the endgame.
"
Class {
	#name : 'EndgamesPage',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'runner',
		'stats',
		'counting',
		'listPage',
		'table',
		'gamesTable',
		'selected',
		'openBlock',
		'openButton',
		'status'
	],
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'counting' }
EndgamesPage >> count [
	"Go through my games in the background (through the window's guarded runner); the answer redraws me. Games I didn't play are left out; a game that can't be read is skipped, counted and logged, so that one bad game neither stops the count nor the app."

	| maxPieces |
	maxPieces := self maxPieces.
	counting := true.
	status text: 'Counting your endgames…'.
	runner value: [
			| result skipped |
			result := EndgameStats maxPieces: maxPieces.
			skipped := 0.
			session games do: [ :entry |
					[
						| game colors |
						game := session gameFor: entry.
						colors := session myColorsIn: game.
						colors size = 1 ifTrue: [
								result
									addGame: game
									id: entry gameId
									color: colors first
									points: (session pointsIn: game as: colors first)
									analysis: ((session isAnalysed: entry)
											 ifTrue: [ session analysisFor: entry ]
											 ifFalse: [ nil ]) ] ]
						on: Error
						do: [ :error |
								session logError: error.
								skipped := skipped + 1 ] ].
			result skipped: skipped.
			self stats: result for: maxPieces ]
]

{ #category : 'building' }
EndgamesPage >> dropdown: someAssociations key: aSettingKey width: aWidth then: aBlock [
	"A filter remembered in the settings"

	^ (MMWidgets
		   dropdown: someAssociations
		   selecting: (session settings at: aSettingKey)
		   do: [ :value |
				   session settings at: aSettingKey put: value.
				   aBlock value ])
		  width: aWidth;
		  margin: (BlInsets right: 8);
		  yourself
]

{ #category : 'building' }
EndgamesPage >> fillGames: aHolder [
	"A table of the selected configuration's games; selecting one enables Play through"

	| zones format |
	selected ifNil: [
			^ aHolder addChild:
				  (ChessCoachWidgets paragraph: 'Choose an endgame in the table.') ].
	zones := self zones.
	format := session settings evaluationFormat.
	gamesTable := MMTableElement new
		              hMatchParent;
		              height: 400;
		              yourself.
	gamesTable columns: {
			(MMTableElement
				 column: 'Move'
				 width: 50
				 value: [ :each | each ply // 2 + 1 ]).
			(MMTableElement column: 'Result' width: 60 value: [ :each |
					 each points = 1
						 ifTrue: [ 'won' ]
						 ifFalse: [
								 each points = 0
									 ifTrue: [ 'lost' ]
									 ifFalse: [ 'draw' ] ] ]).
			((MMTableElement column: 'Eval' width: 70 value: [ :each |
						  each evaluation ifNil: [ '—' ] ifNotNil: [ :pawns |
								  format winPercent:
										  (EngineLine winPercentForCentipawns: pawns * 100) ] ])
				 sorterBlock: [ :each | each evaluation ifNil: [ 0 ] ];
				 yourself).
			(MMTableElement
				 column: 'Upset'
				 width: 70
				 value: [ :each | ((each upsetIn: zones) ifNil: [ '' ]) asString ]) }.
	gamesTable beSingleSelection.
	gamesTable list dataAccessor addAll: selected occurrences.
	gamesTable list
		addEventHandlerOn: ToListPrimarySelectionChangedEvent
		do: [ :event |
				openButton enabled: (gamesTable list selectionModel firstIndex
						 ifNil: [ false ]
						 ifNotNil: [ :index | index > 0 ]) ].
	aHolder addChild: gamesTable
]

{ #category : 'building' }
EndgamesPage >> fillOverview: aHolder [

	selected ifNil: [
			^ aHolder addChild:
				  (ChessCoachWidgets paragraph: 'Choose an endgame in the table.') ].
	aHolder addChild: (ChessCoachWidgets paragraph: selected name).
	self overviewTexts do: [ :each |
		aHolder addChild: (ChessCoachWidgets paragraph: each) ]
]

{ #category : 'initialization' }
EndgamesPage >> initialize [
	"Empty until session:runner: builds the page (the window builds its pages before it has a session)"

	super initialize.
	openBlock := [ :entry :ply |  ].
	self
		layout: BlLinearLayout vertical;
		matchParent
]

{ #category : 'accessing' }
EndgamesPage >> maxPieces [

	^ session settings at: 'endgameMaxPieces'
]

{ #category : 'building' }
EndgamesPage >> newTable [
	"One row per configuration; every column sorts (click the arrow in its header)"

	| newTable |
	newTable := MMTableElement new
		            matchParent;
		            yourself.
	newTable columns: {
			(MMTableElement
				 column: 'Endgame'
				 width: 140
				 value: [ :row | row name ]).
			(MMTableElement
				 column: 'Games'
				 width: 60
				 value: [ :row | row games ]).
			(MMTableElement
				 column: 'W'
				 width: 40
				 value: [ :row | row countPoints: 1 ]).
			(MMTableElement
				 column: 'D'
				 width: 40
				 value: [ :row | row countPoints: 1 / 2 ]).
			(MMTableElement
				 column: 'L'
				 width: 40
				 value: [ :row | row countPoints: 0 ]).
			(MMTableElement
				 column: 'Score %'
				 width: 70
				 value: [ :row | row score ]).
			((MMTableElement
				  column: 'Saved'
				  width: 65
				  value: [ :row | row savedText: self zones ])
				 sorterBlock: [ :row | (row enteredWorseIn: self zones) size ];
				 yourself).
			((MMTableElement
				  column: 'Converted'
				  width: 85
				  value: [ :row | row convertedText: self zones ])
				 sorterBlock: [ :row | (row enteredBetterIn: self zones) size ];
				 yourself).
			(MMTableElement
				 column: 'Upsets'
				 width: 65
				 value: [ :row | row upsetsIn: self zones ]) }.
	newTable beSingleSelection.
	newTable list
		addEventHandlerOn: ToListPrimarySelectionChangedEvent
		do: [ :event | self selectionChanged ].
	^ newTable
]

{ #category : 'actions' }
EndgamesPage >> openSelectedGame [
	"Play through the game selected in the Games tab, from the move where it entered the endgame"

	| index occurrence |
	gamesTable ifNil: [ ^ self ].
	index := gamesTable list selectionModel firstIndex.
	(index isNil or: [ index = 0 ]) ifTrue: [ ^ self ].
	occurrence := gamesTable list dataAccessor at: index.
	session games
		detect: [ :each | each gameId = occurrence gameId ]
		ifFound: [ :entry | openBlock value: entry value: occurrence ply ]
]

{ #category : 'building' }
EndgamesPage >> overviewTexts [
	"The selected configuration's results, how I did when I entered worse or better, and results by pawns"

	| zones byPawns texts |
	selected ifNil: [ ^ #(  ) ].
	zones := self zones.
	texts := OrderedCollection new.
	texts
		add: ('{1} games · {2}' format: {
						 selected games.
						 (EndgameStats resultsText: selected occurrences) });
		add:
			('Entered worse: saved {1}' format: { (selected savedText: zones) });
		add: ('Entered better: converted {1}' format:
					 { (selected convertedText: zones) }).
	(selected occurrences anySatisfy: [ :each | each evaluation isNil ])
		ifTrue: [ texts add: 'Games not analysed have no evaluation.' ].
	byPawns := (selected occurrences groupedBy: [ :each | each pawnsText ])
		           associations asArray sort: [ :a :b | a key <= b key ].
	byPawns do: [ :each |
		texts add: each key , ': ' , (EndgameStats resultsText: each value) ].
	^ texts
]

{ #category : 'updating' }
EndgamesPage >> refreshPane [

	gamesTable := nil.
	openButton enabled: false.
	listPage refreshPane
]

{ #category : 'accessing' }
EndgamesPage >> rows [
	"The configurations the upset filter keeps"

	| zones |
	stats ifNil: [ ^ #(  ) ].
	zones := self zones.
	^ stats rows select: [ :row |
			  self upsetFilter = #all or: [
				  (row upsetsIn: zones) > 0 = (self upsetFilter = #with) ] ]
]

{ #category : 'actions' }
EndgamesPage >> select: aConfigurationName [
	"Select the row of that configuration, as a click would"

	| index |
	index := (1 to: table list dataAccessor size)
		         detect: [ :each |
			         (table list dataAccessor at: each) name
			         = aConfigurationName ]
		         ifNone: [ ^ NotFound signalFor: aConfigurationName ].
	table list selecter selectOnlyIndex: index.
	selected := table list dataAccessor at: index.
	self refreshPane
]

{ #category : 'updating' }
EndgamesPage >> selectionChanged [

	| index |
	index := table list selectionModel firstIndex.
	selected := (index isNil or: [ index = 0 ])
		            ifTrue: [ nil ]
		            ifFalse: [ table list dataAccessor at: index ].
	self refreshPane
]

{ #category : 'initialization' }
EndgamesPage >> session: aSession runner: aBlock [
	"Build the page: the filters and the table on the left, the pane with Play through and two tabs on the right. Counting starts the first time the page is shown."

	session := aSession.
	runner := aBlock.
	status := ToLabel new.
	listPage := MMListPage new.
	listPage filterBar
		addChild: (self
				 dropdown: ((0 to: 6) collect: [ :each |
								  'Endgame: at most ' , each printString , (each = 1
										   ifTrue: [ ' piece' ]
										   ifFalse: [ ' pieces' ]) -> each ])
				 key: 'endgameMaxPieces'
				 width: 220
				 then: [ self count ]);
		addChild: (self
				 dropdown: {
						 ('All endgames' -> 'all').
						 ('With upsets' -> 'with').
						 ('Without upsets' -> 'without') }
				 key: 'endgameUpsetFilter'
				 width: 170
				 then: [ self showRows ]);
		addChild: status.
	table := self newTable.
	listPage list: table.
	openButton := listPage addAction: ((ToButton new
			                labelText: 'Play through';
			                icon:
				                ((ToMaterialDesignIconProvider iconNamed:
						                  'outlined_slideshow')
					                 extent: 18 @ 18;
					                 yourself);
			                clickAction: [ self openSelectedGame ];
			                yourself)
			               enabled: false;
			               yourself).
	listPage
		addTab: 'Overview'
		building: [ :holder | self fillOverview: holder ].
	listPage
		addTab: 'Games'
		building: [ :holder | self fillGames: holder ].
	self removeChildren.
	self addChild: (ChessCoachWidgets
			 page: 'Endgames'
			 subtitle:
			 'Your endgames, by the pieces on the board (kings and pawns not counted). Saved: entered worse and didn''t lose. Converted: entered better and won.'
			 body: listPage).
	self
		addEventHandlerOn: BlElementAddedToSceneGraphEvent
		do: [ :event |
			(stats isNil and: [ counting ~~ true ]) ifTrue: [ self count ] ].
	self isAttachedToSceneGraph ifTrue: [ self count ]
]

{ #category : 'updating' }
EndgamesPage >> showRows [
	"Fill the table with the configurations the filters keep, keeping the sort of its headers; the selection is cleared"

	| rows |
	rows := self rows.
	selected := nil.
	table list dataAccessor removeAll.
	table list dataAccessor addAll: rows.
	table resort.
	status text: (stats ifNil: [ '' ] ifNotNil: [
				 '{1} endgames{2}' format: {
						 rows size.
						 (stats skipped > 0
							  ifTrue: [
									  ' · ' , stats skipped printString
									  , ' games could not be read (see errors.log)' ]
							  ifFalse: [ '' ]) } ]).
	self refreshPane
]

{ #category : 'accessing' }
EndgamesPage >> stats [

	^ stats
]

{ #category : 'counting' }
EndgamesPage >> stats: anEndgameStats for: aMaxPieces [
	"Back from the background: shown in the UI thread when I am in a space, at once otherwise; an answer for an older choice is dropped"

	| apply |
	apply := [
		         aMaxPieces = self maxPieces ifTrue: [
				         stats := anEndgameStats.
				         counting := false.
				         self showRows ] ].
	self isAttachedToSceneGraph
		ifTrue: [ self enqueueTask: (BlTaskAction new action: apply) ]
		ifFalse: [ apply value ]
]

{ #category : 'accessing' }
EndgamesPage >> upsetFilter [
	"#all, #with or #without upsets"

	^ (session settings at: 'endgameUpsetFilter') asSymbol
]

{ #category : 'accessing' }
EndgamesPage >> whenGameChosenDo: aBlock [
	"aBlock receives the index entry of a game and the ply where it entered the configuration"

	openBlock := aBlock
]

{ #category : 'accessing' }
EndgamesPage >> zones [

	^ EvaluationZones thresholds: session settings momentThresholds
]
