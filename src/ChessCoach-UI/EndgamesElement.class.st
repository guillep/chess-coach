"
The Endgames page: on the left, the endgame configurations of my games (my pieces against my opponent's, kings and pawns not counted), the most frequent first, with their results; on the right, a 340 px pane with the selected configuration: results, upsets (games where the engine's evaluation on entering and the result disagree, by evaluation zone), the results by pawns, and the games, which open played through.
A dropdown on top chooses how many pieces at most make an endgame (remembered as 'endgameMaxPieces'). Counting goes through every game, so it runs in the background (runner) when the page is built or the dropdown changes; it is never redrawn by other background work.
"
Class {
	#name : 'EndgamesElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'runner',
		'stats',
		'selected',
		'list',
		'detail',
		'openBlock',
		'counting'
	],
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'instance creation' }
EndgamesElement class >> session: aSession runner: aBlock [

	^ self new session: aSession runner: aBlock
]

{ #category : 'building' }
EndgamesElement >> buildDetail [
	"The 340 px pane: the configuration's numbers, then its games (button: open it played through)"

	| zones format |
	selected ifNil: [
			^ detail addChild:
				  (ChessCoachWidgets paragraph: 'Choose an endgame on the left.') ].
	zones := EvaluationZones thresholds:
		         session settings momentThresholds.
	format := session settings evaluationFormat.
	detail addChild: (ChessCoachWidgets
			 section: selected
			 help:
			 'Every game that went through these pieces for at least 2 moves. Upsets compare the zone of Stockfish''s evaluation when the game entered them with your result.'
			 rows: (self detailTexts collect: [ :each |
					  ChessCoachWidgets paragraph: each ])).
	detail addChild: (ChessCoachWidgets
			 section: 'Games'
			 help: 'Open a game to play it through.'
			 rows: ((stats configurations at: selected) collect: [ :each |
						  | upset |
						  upset := each upsetIn: zones.
						  (ToButton new
							   labelText: ('{1} · move {2} · {3}{4}{5}' format: {
											    each gameId.
											    (each ply // 2 + 1).
											    (each points = 1
												     ifTrue: [ 'won' ]
												     ifFalse: [
														     each points = 0
															     ifTrue: [ 'lost' ]
															     ifFalse: [ 'draw' ] ]).
											    (each evaluation ifNil: [ '' ] ifNotNil: [ :pawns |
														     ' · '
														     ,
															     (format winPercent:
																	      (EngineLine winPercentForCentipawns:
																			       pawns * 100)) ]).
											    (upset ifNil: [ '' ] ifNotNil: [ ' · upset ' , upset ]) });
							   clickAction: [ self openGame: each ];
							   yourself)
							  hMatchParent;
							  yourself ]))
]

{ #category : 'counting' }
EndgamesElement >> count [
	"Go through my games in the background; the answer redraws me. Games I didn't play (both colours or none) are left out; the evaluation on entering is known for the analysed games only."

	| maxPieces |
	maxPieces := self maxPieces.
	counting := true.
	self rebuild.
	runner value: [
			| result |
			result := EndgameStats maxPieces: maxPieces.
			session games do: [ :entry |
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
										 ifFalse: [ nil ]) ] ].
			self stats: result for: maxPieces ]
]

{ #category : 'building' }
EndgamesElement >> detailTexts [
	"The selected configuration's results, upsets and results by pawns, as lines of text"

	| occurrences zones upsets byPawns texts |
	occurrences := stats configurations at: selected.
	zones := EvaluationZones thresholds:
		         session settings momentThresholds.
	upsets := occurrences collect: [ :each | each upsetIn: zones ].
	texts := OrderedCollection new.
	texts
		add: ('{1} games · {2}' format: {
						 occurrences size.
						 (EndgameStats resultsText: occurrences) });
		add:
			('Upsets: {1} for you (you entered worse and didn''t lose), {2} against you (you entered better and didn''t win){3}'
				 format: {
						 (upsets count: [ :each | each = #for ]).
						 (upsets count: [ :each | each = #against ]).
						 ((occurrences anySatisfy: [ :each | each evaluation isNil ])
							  ifTrue: [ '; games not analysed have no evaluation' ]
							  ifFalse: [ '' ]) }).
	byPawns := (occurrences groupedBy: [ :each | each pawnsText ])
		           associations asArray sort: [ :a :b | a key <= b key ].
	byPawns do: [ :each |
		texts add: each key , ': ' , (EndgameStats resultsText: each value) ].
	^ texts
]

{ #category : 'building' }
EndgamesElement >> filterRow [
	"How many pieces at most make an endgame"

	^ ToElement new
		  layout: (BlLinearLayout horizontal alignCenterLeft cellSpacing: 8);
		  hMatchParent;
		  vFitContent;
		  addChild: (ToLabel text: 'An endgame has at most');
		  addChild: ((MMWidgets
				    dropdown: ((0 to: 6) collect: [ :each |
								     (each = 1
									      ifTrue: [ '1 piece' ]
									      ifFalse: [ each printString , ' pieces' ]) -> each ])
				    selecting: self maxPieces
				    do: [ :each |
						    session settings at: 'endgameMaxPieces' put: each.
						    self count ])
				   width: 110;
				   yourself);
		  addChild: (ToLabel text: '(kings and pawns not counted)');
		  yourself
]

{ #category : 'initialization' }
EndgamesElement >> initialize [
	"Empty until session:runner: builds the page (the window builds its pages before it has a session)"

	super initialize.
	openBlock := [ :entry :ply |  ].
	self
		layout: BlLinearLayout vertical;
		matchParent
]

{ #category : 'accessing' }
EndgamesElement >> maxPieces [

	^ session settings at: 'endgameMaxPieces'
]

{ #category : 'actions' }
EndgamesElement >> openGame: anEndgameOccurrence [

	session games
		detect: [ :each | each gameId = anEndgameOccurrence gameId ]
		ifFound: [ :entry |
		openBlock value: entry value: anEndgameOccurrence ply ]
]

{ #category : 'building' }
EndgamesElement >> rebuild [
	"The list of configurations and the detail of the selected one"

	list removeChildren.
	detail removeChildren.
	counting == true ifTrue: [
			list addChild: (ToElement new
					 layout:
						 (BlLinearLayout horizontal alignCenterLeft cellSpacing: 8);
					 hMatchParent;
					 vFitContent;
					 addChild: (ToProgressCircle new
							  isInfinite: true;
							  extent: 20 @ 20;
							  yourself);
					 addChild: (ToLabel text: 'Counting your endgames…');
					 yourself).
			^ self ].
	stats configurations ifEmpty: [
			list addChild: (ChessCoachWidgets paragraph:
					 'None of your games reached an endgame with so few pieces.').
			^ self ].
	stats configurations keysAndValuesDo: [ :key :occurrences |
			list addChild: ((ToButton new
					  labelText: ('{1} · {2} games · {3}' format: {
									   key.
									   occurrences size.
									   (EndgameStats resultsText: occurrences) });
					  clickAction: [ self select: key ];
					  yourself)
					 hMatchParent;
					 yourself) ].
	self buildDetail
]

{ #category : 'actions' }
EndgamesElement >> select: aConfiguration [

	selected := aConfiguration.
	self rebuild
]

{ #category : 'initialization' }
EndgamesElement >> session: aSession runner: aBlock [
	"Build the page. Counting starts the first time the page is shown, not when the window opens."

	session := aSession.
	runner := aBlock.
	list := ToElement new
		        layout: (BlLinearLayout vertical cellSpacing: 4);
		        hMatchParent;
		        vFitContent;
		        yourself.
	detail := ToElement new
		          layout: (BlLinearLayout vertical cellSpacing: 8);
		          width: 340;
		          vFitContent;
		          padding: (BlInsets all: 10);
		          yourself.
	self removeChildren.
	self addChild: (ChessCoachWidgets
			 page: 'Endgames'
			 subtitle:
			 'The endgames of your games, by the pieces on the board (kings and pawns not counted).'
			 body: (ToElement new
					  layout: (BlLinearLayout vertical cellSpacing: 8);
					  matchParent;
					  addChild: self filterRow;
					  addChild: (ToElement new
							   layout: (BlLinearLayout horizontal cellSpacing: 12);
							   matchParent;
							   addChild: (ChessCoachWidgets scrollable: list);
							   addChild: (ToElement new
									    layout: BlFrameLayout new;
									    width: 360;
									    vMatchParent;
									    addChild: (ChessCoachWidgets scrollable: detail);
									    yourself);
							   yourself);
					  yourself)).
	self
		addEventHandlerOn: BlElementAddedToSceneGraphEvent
		do: [ :event |
			(stats isNil and: [ counting ~~ true ]) ifTrue: [ self count ] ].
	self isAttachedToSceneGraph ifTrue: [ self count ]
]

{ #category : 'accessing' }
EndgamesElement >> stats [

	^ stats
]

{ #category : 'counting' }
EndgamesElement >> stats: anEndgameStats for: aMaxPieces [
	"Back from the background: shown in the UI thread when I am in a space, at once otherwise; an answer for an older choice is dropped"

	| apply |
	apply := [
		         aMaxPieces = self maxPieces ifTrue: [
				         stats := anEndgameStats.
				         counting := false.
				         (selected notNil and: [
					          (stats configurations includesKey: selected) not ])
					         ifTrue: [ selected := nil ].
				         self rebuild ] ].
	self isAttachedToSceneGraph
		ifTrue: [ self enqueueTask: (BlTaskAction new action: apply) ]
		ifFalse: [ apply value ]
]

{ #category : 'accessing' }
EndgamesElement >> whenGameChosenDo: aBlock [
	"aBlock receives the index entry of a game and the ply where it entered the configuration"

	openBlock := aBlock
]
