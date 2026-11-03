"
I check the skeleton of list pages: fixed actions, tabs filled for the selection, and confirmations in place of the tabs.
"
Class {
	#name : 'MMListPageTest',
	#superclass : 'TestCase',
	#instVars : [
		'page',
		'scripter',
		'selection'
	],
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'running' }
MMListPageTest >> setUp [

	super setUp.
	selection := 'nothing'.
	page := MMListPage new.
	page list: (ToLabel text: 'the list').
	page addAction: (ToButton new
			 id: #act;
			 labelText: 'Act';
			 yourself).
	page addTab: 'Overview' building: [ :holder |
		holder addChild: (ToLabel text: 'Overview of ' , selection) ].
	page
		addTab: 'More'
		building: [ :holder |
		holder addChild: (ToLabel text: 'More on ' , selection) ].
	scripter := BlDevScripter new.
	scripter element: page.
	scripter space extent: 1000 @ 700.
	scripter pulse
]

{ #category : 'helpers' }
MMListPageTest >> shownTexts [

	| texts |
	texts := OrderedCollection new.
	page allChildrenBreadthFirstDo: [ :each |
			((each isKindOf: ToLabel) and: [ each isAttachedToSceneGraph ])
				ifTrue: [ texts add: each text asString ] ].
	^ texts
]

{ #category : 'tests' }
MMListPageTest >> testTheTabsFollowTheSelectionAndAConfirmationTakesTheirPlace [

	self assert: (self shownTexts includes: 'Overview of nothing').
	selection := 'PR 5'.
	page refreshPane.
	scripter pulse.
	self assert: (self shownTexts includes: 'Overview of PR 5').
	page showTab: 'More'.
	scripter pulse.
	self assert: (self shownTexts includes: 'More on PR 5').
	page showInPane: (ToLabel text: 'Really?').
	scripter pulse.
	self assert: (self shownTexts includes: 'Really?').
	self deny: (self shownTexts includes: 'More on PR 5').
	self assert: (page childWithId: #act) isAttachedToSceneGraph.
	page refreshPane.
	scripter pulse.
	self deny: (self shownTexts includes: 'Really?').
	self assert: (self shownTexts includes: 'More on PR 5')
]
