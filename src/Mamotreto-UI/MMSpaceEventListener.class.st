"
I pass the request to close the window to my MMSpace, which decides whether to close.
"
Class {
	#name : 'MMSpaceEventListener',
	#superclass : 'BlSpaceEventListener',
	#category : 'Mamotreto-UI',
	#package : 'Mamotreto-UI'
}

{ #category : 'window handlers' }
MMSpaceEventListener >> spaceCloseRequest: anEvent [

	space closeRequested
]
