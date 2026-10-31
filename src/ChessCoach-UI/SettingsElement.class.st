"
The settings mode of the right pane: accounts (Lichess login, Chess.com username), games per Load more, piece set, Stockfish and the coach's LLM. Every change goes straight to the session's ChessCoachSettings. Network and engine checks run through backgroundRunner.
"
Class {
	#name : 'SettingsElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'backgroundRunner',
		'loginButton',
		'cancelButton',
		'lichessStatus',
		'chessComField',
		'chessComStatus',
		'numberLabels',
		'pieceSetButtons',
		'previewBoard',
		'stockfishField',
		'stockfishStatus',
		'ollamaField',
		'modelsZone',
		'llmStatus',
		'multiPVNote',
		'setupBlock',
		'lichessField',
		'lichessUserStatus',
		'themeButtons',
		'appThemeButtons',
		'sections',
		'indexElement'
	],
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'accessing' }
SettingsElement class >> repositoryUrl [

	^ 'https://github.com/guillep/chess-coach'
]

{ #category : 'accessing' }
SettingsElement class >> sectionTitles [
	"In the order build adds them"

	^ #( 'Accounts' 'Games' 'Appearance' 'Board' 'Analysis' 'Moments' 'Openings' 'Coach' 'About' )
]

{ #category : 'building' }
SettingsElement >> aboutSection [
	"Version, credits, copyright, license and a link to the repository"

	^ ChessCoachWidgets section: 'About' help: nil rows: {
			  (ToLabel text: 'Chessmate ' , session appVersion).
			  (ToLabel text: 'Built with Pharo and Bloc with Love by GuilleP').
			  (ToLabel text: 'Copyright © 2026 Guille Polito').
			  (ToLabel text: 'Released under the MIT License').
			  (ToButton new
				   id: #repository;
				   labelText: self class repositoryUrl;
				   clickAction: [ WebBrowser openOn: self class repositoryUrl ];
				   yourself) }
]

{ #category : 'building' }
SettingsElement >> appThemeRow [
	"One button per app theme; the chosen one is shown in brackets"

	^ self row: (#( 'Light' 'Dark' ) collect: [ :name |
				   appThemeButtons at: name put: (ToButton new
						    clickAction: [
								    session settings at: 'appTheme' put: name.
								    self updateAppTheme ];
						    yourself) ])
]

{ #category : 'accessing' }
SettingsElement >> backgroundRunner: aBlock [
	"aBlock receives the work block to run; tests pass [ :work | work value ]"

	backgroundRunner := aBlock
]

{ #category : 'building' }
SettingsElement >> build [

	| content widgets |
	widgets := ChessCoachWidgets.
	self removeChildren.
	content := ToElement new
		           layout: (BlLinearLayout vertical cellSpacing: 12);
		           hMatchParent;
		           vFitContent;
		           padding: (BlInsets right: 16);
		           yourself.
	content
		addChild: (ToButton new
				 labelText: 'Run setup again';
				 clickAction: [ setupBlock value ];
				 yourself);
		addChild: (widgets
				 section: 'Accounts'
				 help:
				 'Your games are public on Lichess and Chess.com: a username is enough to download them. Validate checks that the player exists. Logging in to Lichess is optional and only adds opening statistics from its database.'
				 rows: {
						 self lichessRow.
						 self chessComRow });
		addChild: (widgets
				 section: 'Games'
				 help:
				 'How many games Load more downloads from each site at a time, and how often new games are looked for while the app is open (they are also looked for when it opens). Refresh always downloads every newer game.'
				 rows: {
						 (self
							  numberRow: 'Games per Load more'
							  key: 'gamesPerLoad'
							  from: 10
							  to: 100
							  by: 10).
						 (self
							  numberRow: 'Check for new games every (minutes)'
							  key: 'gamesCheckMinutes'
							  from: 5
							  to: 120
							  by: 5) });
		addChild: (widgets
				 section: 'Appearance'
				 help:
				 'Light or dark colours for the whole app. The board keeps its own colours.'
				 rows: { self appThemeRow });
		addChild: (widgets
				 section: 'Board'
				 help:
				 'The pieces and the square colours of every board of the app.'
				 rows: { self pieceSetRow });
		addChild: (widgets
				 section: 'Analysis (Stockfish)'
				 help:
				 'Stockfish analyses the games you review to find mistakes and only moves. Depth is how far it looks (higher is slower and stronger); lines is how many alternatives it keeps per position (2 or more are needed to detect only moves).'
				 rows: {
						 self stockfishRow.
						 (self
							  numberRow: 'Depth'
							  key: 'depth'
							  from: 10
							  to: 30
							  by: 1).
						 (self
							  numberRow: 'Lines (MultiPV)'
							  key: 'multiPV'
							  from: 1
							  to: 5
							  by: 1).
						 (multiPVNote := ToLabel new).
						 (self note:
							  'Changes apply to games analysed from now on; stored analyses are kept.') });
		addChild: (widgets
				 section: 'Moments'
				 help:
				 'How the coach finds the moments to review; the blue ones are on. Evaluation drops are moves that lost ground according to Stockfish; only moves are positions where a single move kept the balance; long thinks are moves that took at least 10 s and 3 times your average; opening choices compare your moves with the Lichess database. The moves you mark are always included. Changes apply to new analyses.'
				 rows: {
						 (self note: 'Find moments from:').
						 (self row: {
								  (self
									   heuristicRow: 'Evaluation drops'
									   key: 'findEvaluationJumps').
								  (self heuristicRow: 'Only moves' key: 'findOnlyMoves').
								  (self heuristicRow: 'Long thinks' key: 'findLongThinks').
								  (self
									   heuristicRow: 'Opening choices'
									   key: 'findOpeningChoices') }) });
		addChild: (widgets
				 section: 'Openings'
				 help:
				 'In an opening tree, positions with more games than this load their database data when clicked. The others show a button, to save Lichess requests.'
				 rows: { (self
						  numberRow: 'Load database data above (games)'
						  key: 'openingDatabaseMinGames'
						  from: 1
						  to: 50
						  by: 1) });
		addChild: (widgets
				 section: 'Coach (local LLM)'
				 help:
				 'A local model, run by Ollama on this computer, sorts your written answers into mistake types. Load models lists the installed ones; Test classifies a sample answer and shows how long it took.'
				 rows: {
						 self ollamaRow.
						 (modelsZone := self row: #(  )).
						 (llmStatus := ToLabel new
							               beMultiLine;
							               hMatchParent;
							               yourself) }).
	content addChild: self aboutSection.
	self addChild: (widgets
			 page: 'Settings'
			 subtitle:
			 'Accounts, the board, the engine and the coach model. Every change is saved at once.'
			 body: (self newTabsOn: content)).
	self updateAccounts.
	self updateNumbers.
	self updateAppTheme.
	self updatePieceSet.
	self updateModels: { session settings ollamaModel }
]

{ #category : 'accessing' }
SettingsElement >> buttonLabeled: aString [
	"The first button showing aString (for tests)"

	self allChildrenBreadthFirstDo: [ :each |
			((each isKindOf: ToButton) and: [
				 each labelText asString = aString ]) ifTrue: [ ^ each ] ].
	^ NotFound signalFor: aString
]

{ #category : 'actions' }
SettingsElement >> change: aKey by: aStep from: aMinimum to: aMaximum [

	session settings
		at: aKey
		put:
		(((session settings at: aKey) + aStep max: aMinimum) min: aMaximum).
	self updateNumbers
]

{ #category : 'accessing' }
SettingsElement >> chessComField [

	^ chessComField
]

{ #category : 'building' }
SettingsElement >> chessComRow [

	chessComField := ToTextField new
		                 width: 180;
		                 yourself.
	chessComStatus := ToLabel new.
	^ self row: {
			  (ToLabel text: 'Chess.com user:').
			  chessComField.
			  (ToButton new
				   labelText: 'Validate';
				   clickAction: [ self validateChessCom ];
				   yourself).
			  (ToButton new
				   labelText: 'Forget';
				   clickAction: [ self forgetChessCom ];
				   yourself).
			  chessComStatus }
]

{ #category : 'updating' }
SettingsElement >> chosen: aName is: aChosenName [
	"The label of a choice: the chosen one has a check mark"

	^ aName = aChosenName
		  ifTrue: [ '✓ ' , aName ]
		  ifFalse: [ aName ]
]

{ #category : 'actions' }
SettingsElement >> forgetChessCom [

	session chessComUsername: nil.
	chessComField text: ''.
	chessComStatus text: ''
]

{ #category : 'actions' }
SettingsElement >> forgetLichess [

	session lichessUsername: nil.
	lichessField text: ''.
	lichessUserStatus text: ''
]

{ #category : 'building' }
SettingsElement >> heading: aString [

	^ ToLabel new
		  text: (aString asRopedText
				   bold;
				   yourself);
		  yourself
]

{ #category : 'building' }
SettingsElement >> heuristicRow: aLabel key: aKey [
	"A toggle that turns one way of finding moments on or off, saved at once"

	| toggle |
	toggle := ToToggleButton new
		          labelText: aLabel;
		          yourself.
	(session settings at: aKey) ifTrue: [ toggle check ].
	toggle newCheckAction: [
		session settings at: aKey put: toggle isChecked ].
	^ toggle
]

{ #category : 'private' }
SettingsElement >> inBackground: aBlock then: aUIBlock showingErrorsIn: aStatusLabel [
	"Run aBlock off the UI thread and give its result to aUIBlock in the UI. This is the UI boundary: a failure (Stockfish missing, Ollama or Chess.com unreachable) is shown in aStatusLabel instead of being lost in a background process."

	backgroundRunner value: [
			| result |
			result := [ aBlock value ]
				          on: Error
				          do: [ :error |
						          self enqueueTask: (BlTaskAction new action: [
								           aStatusLabel text:
									           'Error: ' , error messageText asString ]).
						          ^ nil ].
			self enqueueTask:
				(BlTaskAction new action: [ aUIBlock cull: result ]) ]
]

{ #category : 'accessing' }
SettingsElement >> indexButtons [

	^ indexElement items asArray
]

{ #category : 'initialization' }
SettingsElement >> initialize [

	super initialize.
	backgroundRunner := [ :aBlock |
	                    aBlock forkAt: Processor userBackgroundPriority ].
	setupBlock := [ ].
	numberLabels := Dictionary new.
	pieceSetButtons := Dictionary new.
	themeButtons := Dictionary new.
	appThemeButtons := Dictionary new.
	self layout: BlLinearLayout vertical.
	self matchParent
]

{ #category : 'accessing' }
SettingsElement >> lichessField [

	^ lichessField
]

{ #category : 'building' }
SettingsElement >> lichessRow [
	"The username is enough to download games; logging in is optional and only enables the opening statistics"

	lichessField := ToTextField new
		                width: 180;
		                yourself.
	lichessUserStatus := ToLabel new.
	lichessStatus := ToLabel new.
	loginButton := ToButton new
		               labelText: 'Login';
		               clickAction: [ self loginOrLogout ];
		               yourself.
	cancelButton := ToButton new
		                labelText: 'Cancel';
		                clickAction: [ session cancelLogin ];
		                visibility: BlVisibility gone;
		                yourself.
	^ ToElement new
		  layout: (BlLinearLayout vertical cellSpacing: 6);
		  hMatchParent;
		  vFitContent;
		  addChild: (self row: {
						   (ToLabel text: 'Lichess user:').
						   lichessField.
						   (ToButton new
							    labelText: 'Validate';
							    clickAction: [ self validateLichess ];
							    yourself).
						   (ToButton new
							    labelText: 'Forget';
							    clickAction: [ self forgetLichess ];
							    yourself).
						   lichessUserStatus });
		  addChild: (self row: {
					   (ToLabel text:
						    'Lichess login (optional, for opening statistics):').
					   lichessStatus.
					   loginButton.
					   cancelButton });
		  yourself
]

{ #category : 'actions' }
SettingsElement >> loadModels [
	"Save the Ollama URL and list the models installed there"

	session settings
		at: 'ollamaUrl'
		put: ollamaField text asString trimBoth.
	llmStatus text: 'asking Ollama…'.
	self
		inBackground: [ session classifier client installedModels ]
		then: [ :names |
				llmStatus text: names size printString , ' models installed'.
				self updateModels: names ]
		showingErrorsIn: llmStatus
]

{ #category : 'accessing' }
SettingsElement >> loginButton [

	^ loginButton
]

{ #category : 'actions' }
SettingsElement >> loginOrLogout [

	session isLoggedIn ifTrue: [ ^ session logout ].
	cancelButton visibility: BlVisibility visible.
	self
		inBackground: [ session login ]
		then: [ cancelButton visibility: BlVisibility gone ]
		showingErrorsIn: lichessStatus
]

{ #category : 'building' }
SettingsElement >> newTabsOn: aContent [
	"One tab per section of aContent, on top, the content scrolling below. Run setup again goes to the first section."

	| pane setup |
	setup := aContent children first.
	aContent removeChild: setup.
	sections := aContent children asArray.
	aContent removeChildren.
	sections first addChild: setup.
	pane := ToTabPaneElement new.
	pane horizontal: false.
	pane matchParent.
	pane showAddTabItemButton: false.
	self class sectionTitles with: sections do: [ :title :section |
		| scrollable |
		scrollable := ChessCoachWidgets scrollable: (ToElement new
				               layout: BlLinearLayout vertical;
				               hMatchParent;
				               vFitContent;
				               padding: (BlInsets top: 12 left: 0 bottom: 0 right: 16);
				               addChild: section;
				               yourself).
		pane addItem: (ToTabButton new
				 id: title asSymbol;
				 labelText: title;
				 removable: false;
				 paneBuilder: [ :page :button :holder | page addChild: scrollable ];
				 yourself) ].
	pane selecter selectIndex: 1.
	indexElement := pane.
	^ pane
]

{ #category : 'building' }
SettingsElement >> note: aString [

	^ ChessCoachWidgets paragraph: aString
]

{ #category : 'building' }
SettingsElement >> numberRow: aLabel key: aKey from: aMinimum to: aMaximum by: aStep [
	"− and + buttons that change an integer setting within its range, saved at once"

	| label |
	label := ToLabel new.
	numberLabels at: aKey put: aLabel -> label.
	^ self row: {
			  (ToButton new
				   labelText: '−';
				   clickAction: [
						   self
							   change: aKey
							   by: aStep negated
							   from: aMinimum
							   to: aMaximum ];
				   yourself).
			  label.
			  (ToButton new
				   labelText: '+';
				   clickAction: [
						   self
							   change: aKey
							   by: aStep
							   from: aMinimum
							   to: aMaximum ];
				   yourself) }
]

{ #category : 'building' }
SettingsElement >> ollamaRow [

	ollamaField := ToTextField new
		               width: 220;
		               yourself.
	ollamaField text: session settings ollamaUrl.
	^ self row: {
			  (ToLabel text: 'Ollama:').
			  ollamaField.
			  (ToButton new
				   labelText: 'Load models';
				   clickAction: [ self loadModels ];
				   yourself).
			  (ToButton new
				   labelText: 'Test';
				   clickAction: [ self testModel ];
				   yourself) }
]

{ #category : 'building' }
SettingsElement >> pieceSetRow [
	"The piece-set and colour-theme choices on the left, every piece on two rows on the right"

	| pieceSets themes |
	previewBoard := PieceSetPreviewElement new.
	pieceSets := ToElement new
		             layout: (BlLinearLayout vertical cellSpacing: 4);
		             fitContent;
		             addChild: (ToLabel text: 'Pieces');
		             yourself.
	ChessPieceSet byName keysDo: [ :name |
			| button |
			button := ToButton new
				          clickAction: [
						          session settings at: 'pieceSet' put: name.
						          self updatePieceSet ];
				          yourself.
			pieceSetButtons at: name put: button.
			pieceSets addChild: button ].
	themes := ToElement new
		          layout: (BlLinearLayout vertical cellSpacing: 4);
		          fitContent;
		          addChild: (ToLabel text: 'Colours');
		          yourself.
	ChessBoardElement themes keysDo: [ :name |
			| button |
			button := ToButton new
				          clickAction: [
						          session settings at: 'boardTheme' put: name.
						          self updatePieceSet ];
				          yourself.
			themeButtons at: name put: button.
			themes addChild: button ].
	^ self row: {
			  pieceSets.
			  themes.
			  previewBoard }
]

{ #category : 'accessing' }
SettingsElement >> previewBoard [

	^ previewBoard
]

{ #category : 'building' }
SettingsElement >> row: someElements [

	| row |
	row := ToElement new
		       layout: (BlLinearLayout horizontal cellSpacing: 8);
		       hMatchParent;
		       vFitContent;
		       yourself.
	someElements do: [ :each | row addChild: each ].
	^ row
]

{ #category : 'building' }
SettingsElement >> sectionElement: aSection [
	"The rows of one section, with their state"

	| content |
	content := ToElement new
		           layout: (BlLinearLayout vertical cellSpacing: 8);
		           hMatchParent;
		           vFitContent;
		           yourself.
	aSection = #accounts ifTrue: [
			content
				addChild: self lichessRow;
				addChild: self chessComRow.
			self updateAccounts ].
	aSection = #stockfish ifTrue: [
			content
				addChild: self stockfishRow;
				addChild:
					(self note:
							 'If Test fails, install it with: brew install stockfish') ].
	aSection = #ollama ifTrue: [
			content
				addChild: self ollamaRow;
				addChild: (modelsZone := self row: #(  ));
				addChild: (llmStatus := ToLabel new
						              beMultiLine;
						              hMatchParent;
						              yourself);
				addChild: (self note:
						 'If Ollama is missing: brew install ollama, then ollama pull qwen2.5:7b-instruct').
			self updateModels: { session settings ollamaModel } ].
	^ content
]

{ #category : 'accessing' }
SettingsElement >> session: aChessCoachSession [

	session := aChessCoachSession.
	session announcer
		when: ChessCoachSessionChanged
		do: [ :announcement |
			self enqueueTask:
				(BlTaskAction new action: [ self updateAccounts ]) ]
		for: self.
	self build
]

{ #category : 'accessing' }
SettingsElement >> session: aChessCoachSession section: aSection [
	"Show only one section (#accounts, #stockfish or #ollama), as the setup wizard does"

	session := aChessCoachSession.
	aSection = #accounts ifTrue: [
			session announcer
				when: ChessCoachSessionChanged
				do: [ :announcement |
					self enqueueTask:
						(BlTaskAction new action: [ self updateAccounts ]) ]
				for: self ].
	self removeChildren.
	self addChild: (self sectionElement: aSection)
]

{ #category : 'actions' }
SettingsElement >> showSection: aTitle [
	"As clicking its tab does"

	indexElement selecter selectIndex:
		(self class sectionTitles indexOf: aTitle)
]

{ #category : 'accessing' }
SettingsElement >> shownSections [

	^ sections select: [ :each | each isAttachedToSceneGraph ]
]

{ #category : 'building' }
SettingsElement >> stockfishRow [

	stockfishField := ToTextField new
		                  width: 260;
		                  yourself.
	stockfishField text: (session settings at: 'stockfishPath').
	stockfishStatus := ToLabel new.
	^ self row: {
			  (ToLabel text: 'Stockfish:').
			  stockfishField.
			  (ToButton new
				   labelText: 'Test';
				   clickAction: [ self testStockfish ];
				   yourself).
			  stockfishStatus }
]

{ #category : 'actions' }
SettingsElement >> testModel [
	"Classify a sample answer with the chosen model and show the tags and the time it took"

	llmStatus text: 'classifying a sample answer…'.
	self
		inBackground: [
				| labels milliseconds |
				milliseconds := [
					                labels := session classifier
						                          classify:
						                          'I did not see that his knight could fork my king and queen'
						                          question: 'Why did you play Qd2?'
						                          context: 'Sample' ] timeToRun
					                asMilliSeconds.
				labels -> milliseconds ]
		then: [ :result |
				llmStatus text: ('OK: {1} in {2} s' format: {
							 (', ' join: (result key collect: [ :each | each tagId ])).
							 (result value / 1000.0 printShowingDecimalPlaces: 1) }) ]
		showingErrorsIn: llmStatus
]

{ #category : 'actions' }
SettingsElement >> testStockfish [
	"Save the path and ask that binary for its name over UCI"

	session settings
		at: 'stockfishPath'
		put: stockfishField text asString trimBoth.
	stockfishStatus text: 'starting…'.
	self
		inBackground: [ session analyser engine version ]
		then: [ :version | stockfishStatus text: 'OK: ' , version ]
		showingErrorsIn: stockfishStatus
]

{ #category : 'accessing' }
SettingsElement >> texts [
	"Every label text shown, in order (for tests)"

	| texts |
	texts := OrderedCollection new.
	self allChildrenBreadthFirstDo: [ :each |
		(each isKindOf: ToLabel) ifTrue: [ texts add: each text asString ] ].
	^ texts
]

{ #category : 'updating' }
SettingsElement >> updateAccounts [

	| loggedIn |
	loggedIn := session isLoggedIn.
	lichessStatus text: (loggedIn
			 ifTrue: [ 'connected' ]
			 ifFalse: [ 'not connected' ]).
	loginButton labelText: (loggedIn
			 ifTrue: [ 'Logout' ]
			 ifFalse: [ 'Login' ]).
	session username ifNotNil: [ :name |
			lichessField text asString isEmpty ifTrue: [
				lichessField text: name ].
			lichessUserStatus text: 'OK: ' , name ].
	session chessComUsername ifNotNil: [ :name |
			chessComField text asString isEmpty ifTrue: [
				chessComField text: name ].
			chessComStatus text: 'OK: ' , name ]
]

{ #category : 'updating' }
SettingsElement >> updateAppTheme [

	appThemeButtons keysAndValuesDo: [ :name :button |
		button labelText: (self chosen: name is: session settings appTheme) ]
]

{ #category : 'updating' }
SettingsElement >> updateModels: someModelNames [
	"One button per installed model; the chosen one has a check mark"

	| chosen |
	chosen := session settings ollamaModel.
	modelsZone removeChildren.
	modelsZone addChild: (ToLabel text: 'Model:').
	someModelNames do: [ :name |
			modelsZone addChild: (ToButton new
					 labelText: (self chosen: name is: chosen);
					 clickAction: [
							 session settings at: 'ollamaModel' put: name.
							 self updateModels: someModelNames ];
					 yourself) ].
	chosen = 'qwen2.5:7b-instruct' ifFalse: [
			modelsZone addChild:
				(ToLabel text: 'Validated only with qwen2.5:7b-instruct') ]
]

{ #category : 'updating' }
SettingsElement >> updateNumbers [

	numberLabels keysAndValuesDo: [ :key :nameAndLabel |
			nameAndLabel value text:
				nameAndLabel key , ': ' , (session settings at: key) printString ].
	multiPVNote text: (session settings multiPV < 2
			 ifTrue: [
			 'With one line the "only move" moments are not detected.' ]
			 ifFalse: [ '' ])
]

{ #category : 'updating' }
SettingsElement >> updatePieceSet [
	"Check the chosen piece set and colour theme, and show them on the preview board"

	pieceSetButtons keysAndValuesDo: [ :name :button |
		button labelText: (self chosen: name is: session settings pieceSet) ].
	themeButtons keysAndValuesDo: [ :name :button |
		button labelText:
			(self chosen: name is: session settings boardTheme) ].
	previewBoard
		pieceSet: (ChessPieceSet named: session settings pieceSet);
		theme: session settings boardTheme
]

{ #category : 'actions' }
SettingsElement >> validateChessCom [

	| name |
	name := chessComField text asString trimBoth.
	name ifEmpty: [ ^ self ].
	chessComStatus text: 'checking…'.
	self
		inBackground: [ session validateChessComUsername: name ]
		then: [ :exists |
				chessComStatus text: (exists
						 ifTrue: [ 'OK: ' , name ]
						 ifFalse: [ 'Not found: no such Chess.com player' ]) ]
		showingErrorsIn: chessComStatus
]

{ #category : 'actions' }
SettingsElement >> validateLichess [

	| name |
	name := lichessField text asString trimBoth.
	name ifEmpty: [ ^ self ].
	lichessUserStatus text: 'checking…'.
	self
		inBackground: [ session validateLichessUsername: name ]
		then: [ :exists |
				lichessUserStatus text: (exists
						 ifTrue: [ 'OK: ' , name ]
						 ifFalse: [ 'Not found: no such Lichess player' ]) ]
		showingErrorsIn: lichessUserStatus
]

{ #category : 'accessing' }
SettingsElement >> whenSetupRequestedDo: aBlock [
	"aBlock runs when Run setup again is pressed"

	setupBlock := aBlock
]
