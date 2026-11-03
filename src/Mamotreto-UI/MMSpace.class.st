"
I am the space of a Mamotreto app window. When the user closes the window, I ask closeRequestBlock instead of closing at once, so that the app can ask first, for example while tasks are still running. Bloc offers no cancellable close request, so my event listener answers it.
"
Class {
	#name : 'MMSpace',
	#superclass : 'BlSpace',
	#instVars : [
		'closeRequestBlock'
	],
	#category : 'Mamotreto-UI',
	#package : 'Mamotreto-UI'
}

{ #category : 'closing' }
MMSpace >> closeRequested [
	"The user closed the window"

	closeRequestBlock ifNil: [ ^ self close ].
	closeRequestBlock value
]

{ #category : 'initialization' }
MMSpace >> defaultEventListener [

	^ MMSpaceEventListener space: self
]

{ #category : 'closing' }
MMSpace >> whenCloseRequestedDo: aBlock [
	"aBlock runs when the user closes the window; it closes me, now or after asking"

	closeRequestBlock := aBlock
]
