"
I am one page of an app's rail: a name, an icon and how to build the page. The icon is a Material Design icon name, or a block answering an element (the logo of the Home tab). The builder receives the window; the page is built once and kept.
"
Class {
	#name : 'MMPage',
	#superclass : 'Object',
	#instVars : [
		'name',
		'icon',
		'builder'
	],
	#category : 'Mamotreto-UI-App',
	#package : 'Mamotreto-UI',
	#tag : 'App'
}

{ #category : 'instance creation' }
MMPage class >> named: aString icon: anIconNameOrBlock build: aBlock [

	^ self new setName: aString icon: anIconNameOrBlock builder: aBlock
]

{ #category : 'accessing' }
MMPage >> name [

	^ name
]

{ #category : 'initialization' }
MMPage >> setName: aString icon: anIconNameOrBlock builder: aBlock [

	name := aString.
	icon := anIconNameOrBlock.
	builder := aBlock
]

{ #category : 'building' }
MMPage >> tabIn: aWindow [
	"The tab of the rail that shows me, built for aWindow"

	| button |
	button := aWindow
		          newPageButton: name
		          icon: (icon isString
				           ifTrue: [ icon ]
				           ifFalse: [ 'outlined_home' ])
		          page: (builder cull: aWindow).
	icon isString ifFalse: [ button icon: icon value ].
	^ button
]
