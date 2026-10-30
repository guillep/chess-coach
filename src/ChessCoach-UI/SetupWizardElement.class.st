"
The first-run setup: welcome, accounts, Stockfish, Ollama and done, one step at a time with Next and Skip. The account, Stockfish and Ollama steps reuse the rows of SettingsElement. The last step downloads the first games; finishBlock then runs and settings remember that setup was done.
"
Class {
	#name : 'SetupWizardElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'backgroundRunner',
		'step',
		'content',
		'status',
		'finishBlock'
	],
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'accessing' }
SetupWizardElement >> backgroundRunner: aBlock [

	backgroundRunner := aBlock
]

{ #category : 'building' }
SetupWizardElement >> buildDone [

	content
		addChild: (self paragraph: 'All set');
		addChild: (self paragraph: (session canImport
						  ifTrue: [
							  'Your first games will be downloaded and analysed in the background.' ]
						  ifFalse: [
							  'No account is set: add one later in Settings to download your games.' ]));
		addChild: (ToButton new
				 labelText: 'Start';
				 clickAction: [ self finish ];
				 yourself)
]

{ #category : 'building' }
SetupWizardElement >> buildSection: aSection title: aTitle text: aString [
	"One part of the settings, reused from SettingsElement"

	content
		addChild: (ChessCoachWidgets section: aTitle help: nil rows: {
						 (self paragraph: aString).
						 (SettingsElement new
							  backgroundRunner: backgroundRunner;
							  session: session section: aSection;
							  vFitContent;
							  yourself) });
		addChild: self navigationRow
]

{ #category : 'building' }
SetupWizardElement >> buildWelcome [

	content
		addChild: (self paragraph: 'Welcome to Chess Coach');
		addChild: (self paragraph:
					 'It downloads your games, finds the moments that mattered, asks you how you thought about them, and keeps track of your typical mistakes.');
		addChild: (self paragraph:
					 'Everything runs on this computer: Stockfish analyses the games and a local model (Ollama) classifies your answers.');
		addChild: self navigationRow
]

{ #category : 'accessing' }
SetupWizardElement >> currentStep [

	^ self steps at: step
]

{ #category : 'actions' }
SetupWizardElement >> finish [
	"Remember that setup was done, download the first games when an account is set, then hand over to the app"

	session settings at: 'setupDone' put: true.
	session canImport ifFalse: [ ^ finishBlock value ].
	status text: 'Downloading your games…'.
	backgroundRunner value: [
			[ session loadMoreGames ]
				on: LichessError , NetworkError
				do: [ :error |
						self enqueueTask: (BlTaskAction new action: [
								 status text: 'Could not download games: ' , error messageText ]) ].
			self enqueueTask: (BlTaskAction new action: [ finishBlock value ]) ]
]

{ #category : 'initialization' }
SetupWizardElement >> initialize [

	super initialize.
	backgroundRunner := [ :aBlock |
	                    aBlock forkAt: Processor userBackgroundPriority ].
	finishBlock := [ ].
	step := 1.
	self layout: BlLinearLayout vertical.
	self matchParent.
	self padding: (BlInsets all: 32).
	content := ToElement new
		           layout: (BlLinearLayout vertical cellSpacing: 12);
		           hMatchParent;
		           vFitContent;
		           yourself.
	status := ToLabel new
		          beMultiLine;
		          hMatchParent;
		          yourself.
	self
		addChild: content;
		addChild: status
]

{ #category : 'building' }
SetupWizardElement >> navigationRow [
	"Skip and Next both go on; Next is the usual path"

	^ ToElement new
		  layout: (BlLinearLayout horizontal cellSpacing: 8);
		  hMatchParent;
		  vFitContent;
		  addChild: (ToButton new
				   labelText: 'Skip';
				   clickAction: [ self next ];
				   yourself);
		  addChild: (ChessCoachWidgets
				   primaryButton: 'Next'
				   icon: 'filled_arrowforward'
				   do: [ self next ]);
		  yourself
]

{ #category : 'actions' }
SetupWizardElement >> next [

	step := step + 1 min: self steps size.
	self showStep
]

{ #category : 'building' }
SetupWizardElement >> paragraph: aString [

	^ ChessCoachWidgets paragraph: aString
]

{ #category : 'accessing' }
SetupWizardElement >> session: aChessCoachSession [

	session := aChessCoachSession.
	self showStep
]

{ #category : 'building' }
SetupWizardElement >> showStep [

	| kind |
	kind := self currentStep.
	content removeChildren.
	status text: ''.
	content addChild: (ToLabel new
			 text: ('Step {1} of {2}' format: {
							  step.
							  self steps size });
			 yourself).
	kind = #welcome ifTrue: [ self buildWelcome ].
	kind = #accounts ifTrue: [
			self
				buildSection: #accounts
				title: 'Your accounts'
				text:
				'Set your Lichess and/or Chess.com username to download your games; both sites publish them. Logging in to Lichess is optional: it adds opening statistics.' ].
	kind = #stockfish ifTrue: [
			self
				buildSection: #stockfish
				title: 'Stockfish'
				text:
				'Stockfish analyses your games in the background. Check its path with Test.' ].
	kind = #ollama ifTrue: [
			self
				buildSection: #ollama
				title: 'Coach model (Ollama)'
				text:
				'A local model sorts your answers into mistake types. Load the installed models and Test one.' ].
	kind = #done ifTrue: [ self buildDone ]
]

{ #category : 'accessing' }
SetupWizardElement >> steps [

	^ #( #welcome #accounts #stockfish #ollama #done )
]

{ #category : 'accessing' }
SetupWizardElement >> texts [
	"Every label, paragraph and button text shown (for tests)"

	| texts |
	texts := OrderedCollection new.
	self allChildrenBreadthFirstDo: [ :each |
			(each isKindOf: ToLabel) ifTrue: [ texts add: each text asString ].
			(each isKindOf: ToTextField) ifTrue: [
				texts add: each text asString ].
			(each isKindOf: ToButton) ifTrue: [
				texts add: each labelText asString ] ].
	^ texts
]

{ #category : 'accessing' }
SetupWizardElement >> whenFinishedDo: aBlock [

	finishBlock := aBlock
]
