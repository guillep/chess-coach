"
I am an analysis board, like Lichess's: I start from a position (a moment of a game), I move the pieces of both sides freely, and Stockfish shows its evaluation and best lines for the position on the board, from the side to move, in the unit of the settings. Evaluations are kept by FEN, so going back shows them at once.
Stockfish runs through runner (a block taking a block, the app's background worker). While I am open the background analysis queue is paused, so that the engine answers me; it resumes when I am closed (see close), if it was running.
The panel has its actions on top (Back, Start position, FEN), then the moves played, then the engine's view.
"
Class {
	#name : 'AnalysisBoardElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'positions',
		'board',
		'panel',
		'runner',
		'evaluations',
		'message',
		'resumeQueue'
	],
	#category : 'ChessCoach-UI-Board',
	#package : 'ChessCoach-UI',
	#tag : 'Board'
}

{ #category : 'instance creation' }
AnalysisBoardElement class >> session: aSession position: aChessPosition runner: aBlock [

	^ self new
		  setSession: aSession
		  position: aChessPosition
		  runner: aBlock
]

{ #category : 'engine' }
AnalysisBoardElement >> analyseShownPosition [
	"Ask Stockfish about the position on the board in the background, once per FEN; the answer redraws me when that position is still shown"

	| fen |
	fen := self chessPosition fen.
	(evaluations includesKey: fen) ifTrue: [ ^ self ].
	session isEngineAvailable ifFalse: [ ^ self ].
	self chessPosition hasLegalMove ifFalse: [ ^ self ].
	evaluations at: fen put: nil.
	runner value: [
			| lines |
			lines := session analyser engine
				         analyse: fen
				         multiPV: (session settings multiPV max: 3)
				         depth: session settings depth.
			self linesArrived: lines for: fen ]
]

{ #category : 'actions' }
AnalysisBoardElement >> back [
	"Take back the last move; the start position stays"

	positions size > 1 ifTrue: [ positions removeLast ].
	message := nil.
	self refresh
]

{ #category : 'accessing' }
AnalysisBoardElement >> board [

	^ board
]

{ #category : 'accessing' }
AnalysisBoardElement >> chessPosition [
	"The position on the board"

	^ positions last
]

{ #category : 'queue' }
AnalysisBoardElement >> close [
	"I am closed: the background analysis goes on if I paused it"

	resumeQueue == true ifTrue: [ session analysisQueue resume ].
	resumeQueue := false
]

{ #category : 'building' }
AnalysisBoardElement >> engineRows [
	"One row per line: its first moves and its evaluation; a spinner while Stockfish calculates"

	| position lines format |
	session isEngineAvailable ifFalse: [
		^ { (ChessCoachWidgets paragraph: 'Stockfish isn''t available.') } ].
	position := self chessPosition.
	position hasLegalMove ifFalse: [
		^ { (ChessCoachWidgets paragraph:
			   'The game is over in this position.') } ].
	lines := evaluations at: position fen ifAbsent: [ nil ].
	lines ifNil: [
			^ { (ToElement new
				   layout:
					   (BlLinearLayout horizontal alignCenterLeft cellSpacing: 8);
				   hMatchParent;
				   vFitContent;
				   addChild: (ToProgressCircle new
						    isInfinite: true;
						    extent: 20 @ 20;
						    yourself);
				   addChild: (ToLabel text: 'Calculating…');
				   yourself) } ].
	format := session settings evaluationFormat.
	^ lines collect: [ :line |
			  ChessCoachWidgets paragraph:
				  (format line: line for: position turn) , '  '
				  , (self lineInSAN: line moves from: position) ]
]

{ #category : 'building' }
AnalysisBoardElement >> lineInSAN: someUCIMoves from: aChessPosition [
	"The first moves of an engine line, in SAN"

	| position |
	position := aChessPosition.
	^ ' ' join:
		  ((someUCIMoves first: (someUCIMoves size min: 6)) collect: [ :each |
				   | san |
				   san := position sanForUCI: each.
				   position := position move: san.
				   san ])
]

{ #category : 'engine' }
AnalysisBoardElement >> linesArrived: someLines for: aFEN [
	"Back from the background: kept by FEN, shown in the UI thread when I am in a space, at once otherwise"

	| apply |
	apply := [
		         evaluations at: aFEN put: someLines.
		         self chessPosition fen = aFEN ifTrue: [ self refresh ] ].
	self isAttachedToSceneGraph
		ifTrue: [ self enqueueTask: (BlTaskAction new action: apply) ]
		ifFalse: [ apply value ]
]

{ #category : 'accessing' }
AnalysisBoardElement >> message [

	^ message
]

{ #category : 'building' }
AnalysisBoardElement >> movesText [
	"'Moves: Nf3 d5 c4' from the start position, or what to do"

	| sans position |
	positions size = 1 ifTrue: [
		^ 'Move the pieces of either side; Back takes a move back.' ].
	position := positions first.
	sans := (positions allButFirst collect: [ :each |
			         | san |
			         san := position sanForUCI: each lastMoveUCI.
			         position := each.
			         san ]) asArray.
	^ 'Moves: ' , (' ' join: sans)
]

{ #category : 'queue' }
AnalysisBoardElement >> pauseQueue [
	"While I am open Stockfish answers me: the background analysis waits, and resumes on close if it was running"

	| queue |
	queue := session analysisQueue.
	resumeQueue := queue isPaused not.
	resumeQueue ifTrue: [ queue pause ]
]

{ #category : 'actions' }
AnalysisBoardElement >> play: aUCIMove [
	"A move of the side to move, whichever it is"

	(self chessPosition isLegalUCI: aUCIMove) ifFalse: [
			message := 'Illegal move'.
			^ self refresh ].
	message := nil.
	positions add: (self chessPosition moveUCI: aUCIMove).
	self refresh
]

{ #category : 'building' }
AnalysisBoardElement >> refresh [
	"The board shows the position with the engine's best move as an arrow; the panel its actions, the moves played and the engine's view"

	| lines |
	board chessPosition: self chessPosition.
	self analyseShownPosition.
	lines := evaluations at: self chessPosition fen ifAbsent: [ nil ].
	board arrows: ((lines isNil or: [ lines isEmpty ])
			 ifTrue: [ #(  ) ]
			 ifFalse: [
			 { (ChessArrow uci: lines first firstMove style: #engine) } ]).
	panel removeChildren.
	panel addChild: (ToElement new
			 layout: (BlLinearLayout horizontal cellSpacing: 8);
			 hMatchParent;
			 vFitContent;
			 addChildren: {
					 ((ToButton new
						   labelText: 'Back';
						   icon:
							   ((ToMaterialDesignIconProvider iconNamed:
									     'outlined_chevronleft')
								    extent: 18 @ 18;
								    yourself);
						   clickAction: [ self back ];
						   yourself)
						  enabled: positions size > 1;
						  yourself).
					 ((ToButton new
						   labelText: 'Start position';
						   clickAction: [ self restart ];
						   yourself)
						  enabled: positions size > 1;
						  yourself).
					 (ChessCoachWidgets
						  copyButton: 'FEN'
						  tooltip: 'Copy the position on the board (FEN)'
						  text: [ self chessPosition fen ]) };
			 yourself).
	panel addChild: (ChessCoachWidgets paragraph: self movesText).
	message ifNotNil: [
		panel addChild: (ChessCoachWidgets paragraph: message) ].
	panel addChild: (ChessCoachWidgets
			 section: 'The engine''s view'
			 help:
			 'Stockfish''s best lines for the position on the board, from the side to move, in the unit chosen in the settings. The background analysis of your games waits while this board is open.'
			 rows: self engineRows)
]

{ #category : 'actions' }
AnalysisBoardElement >> restart [
	"Back to the start position"

	positions := OrderedCollection with: positions first.
	message := nil.
	self refresh
]

{ #category : 'initialization' }
AnalysisBoardElement >> setSession: aSession position: aChessPosition runner: aBlock [
	"The board on the left takes the space left by the 340 px panel"

	session := aSession.
	positions := OrderedCollection with: aChessPosition.
	runner := aBlock.
	evaluations := Dictionary new.
	self
		layout: BlLinearLayout horizontal;
		matchParent.
	board := ChessBoardElement new
		         matchParent;
		         pieceSet: (ChessPieceSet named: session settings pieceSet);
		         theme: session settings boardTheme;
		         orientation: aChessPosition turn;
		         yourself.
	board whenMoveMarkedDo: [ :uci | self play: uci ].
	panel := ToElement new
		         layout: (BlLinearLayout vertical cellSpacing: 10);
		         width: 340;
		         vFitContent;
		         padding: (BlInsets all: 10);
		         yourself.
	self
		addChild: (ChessCoachWidgets centered: board);
		addChild: (ToElement new
				 layout: BlFrameLayout new;
				 width: 360;
				 vMatchParent;
				 addChild: (ChessCoachWidgets scrollable: panel);
				 yourself).
	self pauseQueue.
	self refresh
]
