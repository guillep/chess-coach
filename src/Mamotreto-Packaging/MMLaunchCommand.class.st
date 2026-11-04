"
I start a packaged Mamotreto app: the launcher made by PharoApplicationGenerator runs the image with `mamotreto --embedded`, and I open the app's window without the Pharo world; closing the window quits. The build sets which app (MMPackager does it before saving the image).
"
Class {
	#name : 'MMLaunchCommand',
	#superclass : 'CommandLineHandler',
	#classInstVars : [
		'app'
	],
	#category : 'Mamotreto-Packaging',
	#package : 'Mamotreto-Packaging'
}

{ #category : 'accessing' }
MMLaunchCommand class >> app [
	"The MMApp subclass the image opens, set at build time"

	^ app
]

{ #category : 'accessing' }
MMLaunchCommand class >> app: anAppClass [

	app := anAppClass
]

{ #category : 'accessing' }
MMLaunchCommand class >> commandName [

	^ 'mamotreto'
]

{ #category : 'accessing' }
MMLaunchCommand class >> description [

	^ 'Open the packaged Mamotreto app'
]

{ #category : 'activation' }
MMLaunchCommand >> activate [
	"Open the app on the SDL driver of the headless VM; closing its window quits without saving, the bundle is read-only"

	| window |
	self class app ifNil: [
		^ self exitFailure: 'No app was set when the image was built' ].
	OSWindowDriver current startUp: true.
	window := self class app new open.
	window space
		addEventHandlerOn: BlSpaceClosedEvent
		do: [ :event | Smalltalk snapshot: false andQuit: true ]
]
