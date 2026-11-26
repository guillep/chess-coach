"
I check that `MMSpaceTestCase` gives each test an open space and closes every space a test leaves open.
"
Class {
	#name : 'MMSpaceTestCaseTest',
	#superclass : 'MMSpaceTestCase',
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'support' }
MMSpaceTestCaseTest >> openExtraSpace [

	| extra |
	extra := BlSpace new.
	extra host: self host.
	extra open
]

{ #category : 'tests' }
MMSpaceTestCaseTest >> testRunCaseClosesTheSpacesATestOpens [

	| before |
	before := self host spaces copy.
	(self class selector: #openExtraSpace) runCase.
	self assert: (self host spaces allSatisfy: [ :each | before includes: each ])
]

{ #category : 'tests' }
MMSpaceTestCaseTest >> testSpaceIsOpenOnTheHost [

	self assert: space isOpened.
	self assert: (self host spaces includes: space)
]
