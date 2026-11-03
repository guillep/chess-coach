"
The accordion's skin without its arrow: a group doesn't close.
"
Class {
	#name : 'MMGroupElementSkin',
	#superclass : 'ToAccordionElementSkin',
	#category : 'Mamotreto-UI-Widgets',
	#package : 'Mamotreto-UI',
	#tag : 'Widgets'
}

{ #category : 'event handling' }
MMGroupElementSkin >> checkedSkinEvent: anEvent [

	super checkedSkinEvent: anEvent.
	anEvent elementDo: [ :e | self removeArrowOf: e ]
]

{ #category : 'private' }
MMGroupElementSkin >> collapseHeader: aHeader [
	"No arrow to turn, unless it is collapsible"

	aHeader parent isCollapsible ifTrue: [ super collapseHeader: aHeader ]
]

{ #category : 'private' }
MMGroupElementSkin >> expandHeader: aHeader [
	"No arrow to turn, unless it is collapsible"

	aHeader parent isCollapsible ifTrue: [ super expandHeader: aHeader ]
]

{ #category : 'event handling' }
MMGroupElementSkin >> installSkinEvent: anEvent [

	super installSkinEvent: anEvent.
	anEvent elementDo: [ :e | self removeArrowOf: e ]
]

{ #category : 'private' }
MMGroupElementSkin >> removeArrowOf: aGroup [

	aGroup isCollapsible ifTrue: [ ^ self ].
	aGroup header icon: (BlElement new
			 extent: 0 @ 0;
			 yourself)
]

{ #category : 'event handling' }
MMGroupElementSkin >> uncheckedSkinEvent: anEvent [

	super uncheckedSkinEvent: anEvent.
	anEvent elementDo: [ :e | self removeArrowOf: e ]
]
