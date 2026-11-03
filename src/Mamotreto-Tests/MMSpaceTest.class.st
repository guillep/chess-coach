"
I check that closing the window asks the app before closing.
"
Class {
	#name : 'MMSpaceTest',
	#superclass : 'TestCase',
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'tests' }
MMSpaceTest >> testAClosedWindowAsksTheAppInsteadOfClosing [

	| space asked |
	space := MMSpace new.
	asked := false.
	space whenCloseRequestedDo: [ asked := true ].
	BlSpaceCloseRequest new sendTo: (MMSpaceEventListener space: space).
	self assert: asked
]
