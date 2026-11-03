"
I compare, for the position before a move of a game, what the engine says and what the opening database says, one row per move: the engine's best lines, the move played, my candidates and the moves most played in the database. Columns: move, evaluation (in the unit of the settings, from the mover's side), its zone, the database games and the mover's win/draw/loss.
Two dropdowns choose the database (Lichess players at the mover's rating and the game's speed, or masters) and how many engine lines to show; both are remembered in the settings ('coachDatabase', 'coachEngineLines'). The database is asked in the background, through runner (a block taking a block), and I redraw myself when it answers.
"
Class {
	#name : 'MoveComparisonTable',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'game',
		'ply',
		'analysis',
		'candidates',
		'runner',
		'database',
		'databaseKey',
		'rows'
	],
	#category : 'ChessCoach-UI-Coach',
	#package : 'ChessCoach-UI',
	#tag : 'Coach'
}

{ #category : 'constants' }
MoveComparisonTable class >> columnWidths [

	^ #( 100 50 60 45 65 )
]

{ #category : 'instance creation' }
MoveComparisonTable class >> session: aSession game: aGame ply: aPly analysis: aGameAnalysis candidates: aDictionary runner: aBlock [
	"The position before aPly. aDictionary maps my candidates (UCI) to my win % after each."

	^ self new
		  setSession: aSession
		  game: aGame
		  ply: aPly
		  analysis: aGameAnalysis
		  candidates: aDictionary
		  runner: aBlock
]

{ #category : 'database' }
MoveComparisonTable >> canUseDatabase [
	"The explorer needs a Lichess login"

	^ session canUseDatabase
]

{ #category : 'building' }
MoveComparisonTable >> cellsFor: aUCIMove role: aString [
	"Move, role, evaluation, zone, database games, mover's win/draw/loss"

	| format zones line pawns evaluation entry games |
	format := session settings evaluationFormat.
	zones := EvaluationZones thresholds:
		         session settings momentThresholds.
	line := self evaluationOf: aUCIMove.
	line
		ifNotNil: [
				evaluation := format line: line for: self mover.
				pawns := line pawnsFor: self mover ]
		ifNil: [
				(candidates at: aUCIMove ifAbsent: [ nil ]) ifNotNil: [ :win |
						evaluation := format winPercent: win.
						pawns := EngineLine pawnsForWinPercent: win ] ].
	entry := self databaseEntryFor: aUCIMove.
	games := entry ifNotNil: [
		         (entry at: 'white') + (entry at: 'draws')
		         + (entry at: 'black') ].
	^ {
		  (self positionBefore sanForUCI: aUCIMove).
		  aString.
		  (evaluation ifNil: [ '—' ]).
		  (pawns
			   ifNil: [ '—' ]
			   ifNotNil: [ EvaluationZones zoneNames at: (zones zoneOf: pawns) ]).
		  (games ifNil: [ '—' ] ifNotNil: [ games printString ]).
		  ((games isNil or: [ games = 0 ])
			   ifTrue: [ '—' ]
			   ifFalse: [ self winDrawLossOf: entry games: games ]) }
]

{ #category : 'database' }
MoveComparisonTable >> databaseArrived: aDictionary for: aKey [
	"Back from the background: shown in the UI thread when I am in a space, at once otherwise (nobody sees me redraw)"

	| apply |
	apply := [
		         databaseKey = aKey ifTrue: [
				         database := aDictionary.
				         self rebuild ] ].
	self isAttachedToSceneGraph
		ifTrue: [ self enqueueTask: (BlTaskAction new action: apply) ]
		ifFalse: [ apply value ]
]

{ #category : 'database' }
MoveComparisonTable >> databaseEntryFor: aUCIMove [
	"The explorer's entry for aUCIMove (with 'white', 'draws', 'black' counts), or nil"

	database ifNil: [ ^ nil ].
	^ (database at: 'moves' ifAbsent: [ #(  ) ])
		  detect: [ :each | (self uciOfEntry: each) = aUCIMove ]
		  ifNone: [ nil ]
]

{ #category : 'accessing' }
MoveComparisonTable >> databaseSource [
	"'lichess' (players at the mover's rating) or 'masters'"

	^ session settings at: 'coachDatabase'
]

{ #category : 'building' }
MoveComparisonTable >> dropdownRow [
	"The database and the number of engine lines, remembered in the settings"

	^ ToElement new
		  layout: (BlLinearLayout horizontal alignCenterLeft cellSpacing: 8);
		  hMatchParent;
		  vFitContent;
		  addChildren: {
				  ((MMWidgets
					    dropdown: {
							    ('Players at this level' -> 'lichess').
							    ('Masters' -> 'masters') }
					    selecting: self databaseSource
					    do: [ :value |
							    session settings at: 'coachDatabase' put: value.
							    self rebuild.
							    self fetchDatabase ])
					   width: 170;
					   yourself).
				  (ToLabel text: 'Lines').
				  ((MMWidgets
					    dropdown:
						    (#( 1 2 3 5 ) collect: [ :each | each printString -> each ])
					    selecting: self lineCount
					    do: [ :value |
							    session settings at: 'coachEngineLines' put: value.
							    self rebuild ])
					   width: 60;
					   yourself) };
		  yourself
]

{ #category : 'building' }
MoveComparisonTable >> evaluationOf: aUCIMove [
	"The mover's evaluation after aUCIMove, as pawns from the mover's side, or nil when unknown: an engine line, the stored analysis of the played move, or my candidate's win %"

	| before line |
	before := analysis atPly: ply - 1.
	line := before lines
		        detect: [ :each | each firstMove = aUCIMove ]
		        ifNone: [ nil ].
	line ifNotNil: [ ^ line ].
	(aUCIMove = (game uciMoves at: ply) and: [
		 (analysis atPly: ply) lines notEmpty ]) ifTrue: [
		^ (analysis atPly: ply) bestLine ].
	^ nil
]

{ #category : 'database' }
MoveComparisonTable >> fetchDatabase [
	"Ask the explorer in the background; the answer redraws me. Without a Lichess login the database columns stay empty; when it can't be reached, the reason is shown under the table."

	| key explorer position |
	self canUseDatabase ifFalse: [ ^ self ].
	explorer := session explorer.
	position := self positionBefore.
	key := self databaseSource.
	database := nil.
	databaseKey := key.
	runner value: [
			| data |
			data := [
				        key = 'masters'
					        ifTrue: [ explorer mastersMovesFor: position fen ]
					        ifFalse: [
							        explorer
								        lichessMovesFor: position fen
								        speed: (LichessExplorerClient speedForTimeControl:
										         (game metadata at: 'TimeControl' ifAbsent: [ nil ]))
								        ratings: ((game metadata
										          at: (position turn = #white
												           ifTrue: [ 'WhiteElo' ]
												           ifFalse: [ 'BlackElo' ])
										          ifAbsent: [ nil ])
										         ifNil: [ #(  ) ]
										         ifNotNil: [ :elo |
										         LichessExplorerClient ratingBucketsAround:
											         elo asInteger ]) ] ]
				        on: LichessError , NetworkError
				        do: [ :error |
						        Dictionary new
							        at: 'problem'
							        put: 'Database unavailable: ' , error messageText;
							        yourself ].
			self databaseArrived: data for: key ]
]

{ #category : 'accessing' }
MoveComparisonTable >> lineCount [

	^ session settings at: 'coachEngineLines'
]

{ #category : 'accessing' }
MoveComparisonTable >> mover [

	^ self positionBefore turn
]

{ #category : 'accessing' }
MoveComparisonTable >> positionBefore [
	"The position before the move"

	^ game positionAfterPly: ply - 1
]

{ #category : 'building' }
MoveComparisonTable >> rebuild [
	"The two dropdowns, then a header and one row per move. The rows are kept as text for tests."

	self removeChildren.
	self addChild: self dropdownRow.
	rows := self rowMoves associations collect: [ :each |
		        self cellsFor: each key role: each value ].
	self addChild:
		(self
			 rowElement: #( 'Move' 'Eval' 'Zone' 'Games' 'W/D/L' )
			 bold: true).
	rows do: [ :cells |
			self addChild: (self
					 rowElement:
					 { (cells first , ' (' , cells second , ')') }
					 , (cells allButFirst: 2)
					 bold: false) ].
	self lineCount > (analysis atPly: ply - 1) lines size ifTrue: [
			self addChild: (ChessCoachWidgets paragraph:
					 'Only ' , (analysis atPly: ply - 1) lines size printString
					 ,
					 ' engine lines are stored for this game: raise Lines in Settings > Analysis for new analyses.') ].
	database ifNotNil: [
			database
				at: 'problem'
				ifPresent: [ :problem |
				self addChild: (ChessCoachWidgets paragraph: problem) ] ].
	database isNil ifTrue: [
			self addChild: (ChessCoachWidgets paragraph: (self canUseDatabase
						  ifTrue: [ 'Asking the database…' ]
						  ifFalse: [ 'Log in to Lichess to see the database.' ])) ]
]

{ #category : 'building' }
MoveComparisonTable >> rowElement: someTexts bold: aBoolean [
	"One row of fixed-width cells, so that the columns line up in the 340 px pane: move (with its role), evaluation, zone, games, win/draw/loss"

	| row |
	row := ToElement new
		       layout: (BlLinearLayout horizontal cellSpacing: 4);
		       hMatchParent;
		       vFitContent;
		       yourself.
	someTexts with: self class columnWidths do: [ :text :width |
			row addChild: (ToLabel new
					 text: (aBoolean
							  ifTrue: [
									  text asRopedText
										  bold;
										  yourself ]
							  ifFalse: [ text asRopedText ]);
					 width: width;
					 yourself) ].
	^ row
]

{ #category : 'building' }
MoveComparisonTable >> rowMoves [
	"UCI move -> how it is known, in order: the engine lines shown, the move played, my candidates, then the database's most played moves (up to 3 more)"

	| moves before played others |
	moves := OrderedDictionary new.
	before := analysis atPly: ply - 1.
	(before lines first: (before lines size min: self lineCount))
		withIndexDo: [ :line :index |
			moves at: line firstMove put: 'engine ' , index printString ].
	played := game uciMoves at: ply.
	moves at: played put: 'played'.
	candidates keysDo: [ :each |
		moves at: each ifAbsentPut: [ 'candidate' ] ].
	database ifNotNil: [
			others := ((database at: 'moves' ifAbsent: [ #(  ) ]) collect: [
				           :each | self uciOfEntry: each ]) reject: [ :each |
				          moves includesKey: each ].
			(others first: (others size min: 3)) do: [ :each |
				moves at: each put: 'database' ] ].
	^ moves
]

{ #category : 'accessing' }
MoveComparisonTable >> rows [
	"The table's rows, each an array of cell texts"

	^ rows
]

{ #category : 'initialization' }
MoveComparisonTable >> setSession: aSession game: aGame ply: aPly analysis: aGameAnalysis candidates: aDictionary runner: aBlock [

	session := aSession.
	game := aGame.
	ply := aPly.
	analysis := aGameAnalysis.
	candidates := aDictionary.
	runner := aBlock.
	self
		layout: (BlLinearLayout vertical cellSpacing: 6);
		hMatchParent;
		vFitContent.
	self rebuild.
	self fetchDatabase
]

{ #category : 'database' }
MoveComparisonTable >> uciOfEntry: anEntry [
	"The explorer gives 'uci' and 'san'; only the SAN is required"

	^ anEntry
		  at: 'uci'
		  ifAbsent: [
		  (self positionBefore move: (anEntry at: 'san')) lastMoveUCI ]
]

{ #category : 'building' }
MoveComparisonTable >> winDrawLossOf: anEntry games: aNumber [
	"'45/30/25' in %, from the mover's side"

	| wins losses percent |
	percent := [ :count | (count * 100 / aNumber) rounded printString ].
	wins := self mover = #white
		        ifTrue: [ anEntry at: 'white' ]
		        ifFalse: [ anEntry at: 'black' ].
	losses := self mover = #white
		          ifTrue: [ anEntry at: 'black' ]
		          ifFalse: [ anEntry at: 'white' ].
	^ '/' join: {
			  (percent value: wins).
			  (percent value: (anEntry at: 'draws')).
			  (percent value: losses) }
]
