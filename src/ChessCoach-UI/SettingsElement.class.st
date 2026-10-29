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
		'setupBlock'
	],
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'accessing' }
SettingsElement >> backgroundRunner: aBlock [
	"aBlock receives the work block to run; tests pass [ :work | work value ]"

	backgroundRunner := aBlock
]

{ #category : 'building' }
SettingsElement >> build [

	| content |
	self removeChildren.
	content := ToElement new
		           layout: (BlLinearLayout vertical cellSpacing: 8);
		           hMatchParent;
		           vFitContent;
		           padding: (BlInsets all: 16);
		           yourself.
	content
		addChild: (self row: {
						 (self heading: 'Settings').
						 (ToButton new
							  labelText: 'Run setup again';
							  clickAction: [ setupBlock value ];
							  yourself) });
		addChild: (self heading: 'Accounts');
		addChild: self lichessRow;
		addChild: self chessComRow;
		addChild: (self heading: 'Games');
		addChild: (self
				 numberRow: 'Games per Load more'
				 key: 'gamesPerLoad'
				 from: 10
				 to: 100
				 by: 10);
		addChild: (self heading: 'Board');
		addChild: self pieceSetRow;
		addChild: (self heading: 'Analysis (Stockfish)');
		addChild: self stockfishRow;
		addChild: (self
				 numberRow: 'Depth'
				 key: 'depth'
				 from: 10
				 to: 30
				 by: 1);
		addChild: (self
				 numberRow: 'Lines (MultiPV)'
				 key: 'multiPV'
				 from: 1
				 to: 5
				 by: 1);
		addChild: (multiPVNote := ToLabel new);
		addChild: (self note:
				 'Changes apply to games analysed from now on; stored analyses are kept.');
		addChild: (self heading: 'Coach (local LLM)');
		addChild: self ollamaRow;
		addChild: (modelsZone := self row: #(  ));
		addChild: (llmStatus := ToLabel new
				              beMultiLine;
				              hMatchParent;
				              yourself).
	self addChild: (content asScrollableElement
			 matchParent;
			 yourself).
	self updateAccounts.
	self updateNumbers.
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

{ #category : 'actions' }
SettingsElement >> forgetChessCom [

	session chessComUsername: nil.
	chessComField text: ''.
	chessComStatus text: ''
]

{ #category : 'building' }
SettingsElement >> heading: aString [

	^ ToLabel new
		  text: (aString asRopedText
				   bold;
				   yourself);
		  yourself
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

{ #category : 'initialization' }
SettingsElement >> initialize [

	super initialize.
	backgroundRunner := [ :aBlock |
	                    aBlock forkAt: Processor userBackgroundPriority ].
	setupBlock := [ ].
	numberLabels := Dictionary new.
	pieceSetButtons := Dictionary new.
	self layout: BlLinearLayout vertical.
	self matchParent
]

{ #category : 'building' }
SettingsElement >> lichessRow [

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
	^ self row: {
			  (ToLabel text: 'Lichess:').
			  lichessStatus.
			  loginButton.
			  cancelButton }
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
SettingsElement >> note: aString [
	"A read-only text that wraps at word boundaries (Toplo labels don't wrap)"

	^ ToTextField new
		  wrappingMode: true;
		  hMatchParent;
		  vFitContent;
		  text: aString;
		  beReadonlyWithoutSelection;
		  yourself
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

	| buttons |
	previewBoard := ChessBoardElement new
		                extent: 160 @ 160;
		                chessPosition: ChessPosition initial;
		                yourself.
	buttons := ToElement new
		           layout: (BlLinearLayout vertical cellSpacing: 4);
		           fitContent;
		           yourself.
	ChessPieceSet byName keysDo: [ :name |
			| button |
			button := ToButton new
				          clickAction: [
						          session settings at: 'pieceSet' put: name.
						          self updatePieceSet ];
				          yourself.
			pieceSetButtons at: name put: button.
			buttons addChild: button ].
	^ self row: {
			  buttons.
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
			 ifTrue: [ 'connected as ' , (session username ifNil: [ '?' ]) ]
			 ifFalse: [ 'not connected' ]).
	loginButton labelText: (loggedIn
			 ifTrue: [ 'Logout' ]
			 ifFalse: [ 'Login' ]).
	session chessComUsername ifNotNil: [ :name |
			chessComField text asString isEmpty ifTrue: [
				chessComField text: name ].
			chessComStatus text: 'OK: ' , name ]
]

{ #category : 'updating' }
SettingsElement >> updateModels: someModelNames [
	"One button per installed model; the chosen one is shown in brackets"

	| chosen |
	chosen := session settings ollamaModel.
	modelsZone removeChildren.
	modelsZone addChild: (ToLabel text: 'Model:').
	someModelNames do: [ :name |
			modelsZone addChild: (ToButton new
					 labelText: (name = chosen
							  ifTrue: [ '[' , name , ']' ]
							  ifFalse: [ name ]);
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

	pieceSetButtons keysAndValuesDo: [ :name :button |
			button labelText: (name = session settings pieceSet
					 ifTrue: [ '[' , name , ']' ]
					 ifFalse: [ name ]) ].
	previewBoard pieceSet:
		(ChessPieceSet named: session settings pieceSet)
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

{ #category : 'accessing' }
SettingsElement >> whenSetupRequestedDo: aBlock [
	"aBlock runs when Run setup again is pressed"

	setupBlock := aBlock
]
