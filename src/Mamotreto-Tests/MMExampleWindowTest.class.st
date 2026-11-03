"
The shell on its own: the example app's window, with its session on a memory file system and an updater stub.
"
Class {
	#name : 'MMExampleWindowTest',
	#superclass : 'TestCase',
	#instVars : [
		'session',
		'window',
		'scripter'
	],
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'helpers' }
MMExampleWindowTest >> buttonLabelled: aString [
	"The shown button with that label"

	window allChildrenBreadthFirstDo: [ :each |
			((each isKindOf: ToButton) and: [
				 each isAttachedToSceneGraph and: [
					 each labelText asString = aString ] ]) ifTrue: [ ^ each ] ].
	^ self fail: 'No button ' , aString
]

{ #category : 'running' }
MMExampleWindowTest >> setUp [

	super setUp.
	session := MMExampleSession onDirectory: FileSystem memory root.
	session updater: (MMUpdaterStub new
			 current: 'v1.0.0' tags: #(  ) failure: nil;
			 yourself).
	window := (MMWindow app: MMExampleApp new)
		          backgroundRunner: [ :work | work value ];
		          session: session;
		          yourself.
	scripter := BlDevScripter new.
	scripter element: window.
	scripter space extent: 1000 @ 700.
	scripter pulse
]

{ #category : 'tests' }
MMExampleWindowTest >> testGreetButtonRunsTheService [

	| button |
	window showPage: #Greetings.
	scripter pulse.
	button := self buttonLabelled: 'Greet'.
	scripter testClick onChildFromBlock: [ :root | button ].
	scripter syncContinue.
	scripter pulse.
	self
		assert: session notifications visible first title
		equals: 'Hello'
]

{ #category : 'tests' }
MMExampleWindowTest >> testLinksAreButtons [
	"A label with a click handler does not look nor behave as something to click"

	| link |
	link := MMWidgets link: 'Pharo' to: 'https://pharo.org'.
	self assert: (link isKindOf: ToButton).
	self assert: link labelText asString equals: 'Pharo'
]

{ #category : 'tests' }
MMExampleWindowTest >> testManyNotificationsScrollInsteadOfLeavingTheScreen [

	| panel panelScripter |
	1 to: 30 do: [ :i |
			session notifications post: (MMNotification
					 key: 'n' , i printString
					 kind: #info
					 title: 'Note ' , i printString
					 text: 'Something happened that is worth a line of text.') ].
	panel := window newNotificationsPanel.
	panelScripter := BlDevScripter new.
	panelScripter element: panel.
	panelScripter space extent: 400 @ 2000.
	panelScripter pulse.
	self assert: panel height > 300.
	self assert: panel height <= (700 * 0.7 + 80).
	self assert: (panel childWithId: #clearNotifications) isEnabled
]

{ #category : 'tests' }
MMExampleWindowTest >> testShowPage [

	window showPage: #Look.
	scripter pulse.
	self assert: window navigation selecter selectedIndex equals: 2.
	window showPage: #Greetings.
	scripter pulse.
	self assert: window navigation selecter selectedIndex equals: 1
]

{ #category : 'tests' }
MMExampleWindowTest >> testTheBarsTouchWithLinesBetweenThem [
	"Title bar, line, pages, line, status bar: no gaps and no app margin"

	| children |
	children := window children asArray.
	self assert: children size equals: 5.
	self assert: children first id asSymbol equals: #topBar.
	self assert: (children at: 3) equals: window navigation.
	{
		(children at: 2).
		(children at: 4) } do: [ :line |
			self assert: line height equals: 1.
			self assert: line margin equals: BlInsets empty ].
	self assert: window padding equals: BlInsets empty
]

{ #category : 'tests' }
MMExampleWindowTest >> testTheRailShowsTheAppPages [

	self
		assert:
		(window navigation items asArray collect: [ :each | each id ])
		equals: #( #Greetings #Look ).
	self assert: window appName equals: 'Mamotreto Example'
]

{ #category : 'tests' }
MMExampleWindowTest >> testTheServiceIsNotifiedUnderTheBell [

	self deny: window bellBadge visibility isVisible.
	session greet.
	scripter pulse.
	self assert: window bellBadge visibility isVisible.
	self
		assert: session notifications visible first title
		equals: 'Hello'
]

{ #category : 'tests' }
MMExampleWindowTest >> testTheServiceIsScheduledWithTheUpdates [

	| scheduler |
	scheduler := MMScheduler new.
	session scheduleChecksIn: scheduler.
	self assert: scheduler intervals asArray equals: {
			1 hour.
			6 hours }
]

{ #category : 'tests' }
MMExampleWindowTest >> testTheThemeFollowsTheSetting [

	session settings at: 'appTheme' put: 'Dark'.
	scripter pulse.
	self
		assert: window background paint color
		equals: (MMExampleApp new palette at: #darkBackground).
	session settings at: 'appTheme' put: 'Light'.
	scripter pulse.
	self
		assert: window background paint color
		equals: (MMExampleApp new palette at: #lightBackground)
]
