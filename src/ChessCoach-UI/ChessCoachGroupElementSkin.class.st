"
The accordion's skin without its arrow: a group doesn't close.
"
Class {
	#name : 'ChessCoachGroupElementSkin',
	#superclass : 'ToAccordionElementSkin',
	#category : 'ChessCoach-UI-Widgets',
	#package : 'ChessCoach-UI',
	#tag : 'Widgets'
}

{ #category : 'event handling' }
ChessCoachGroupElementSkin >> checkedSkinEvent: anEvent [

	super checkedSkinEvent: anEvent.
	anEvent elementDo: [ :e | self removeArrowOf: e ]
]

{ #category : 'private' }
ChessCoachGroupElementSkin >> collapseHeader: aHeader [
	"No arrow to turn, unless it is collapsible"

	aHeader parent isCollapsible ifTrue: [ super collapseHeader: aHeader ]
]

{ #category : 'private' }
ChessCoachGroupElementSkin >> expandHeader: aHeader [
	"No arrow to turn, unless it is collapsible"

	aHeader parent isCollapsible ifTrue: [ super expandHeader: aHeader ]
]

{ #category : 'event handling' }
ChessCoachGroupElementSkin >> installSkinEvent: anEvent [

	super installSkinEvent: anEvent.
	anEvent elementDo: [ :e | self removeArrowOf: e ]
]

{ #category : 'private' }
ChessCoachGroupElementSkin >> removeArrowOf: aGroup [

	aGroup isCollapsible ifTrue: [ ^ self ].
	aGroup header icon: (BlElement new
			 extent: 0 @ 0;
			 yourself)
]

{ #category : 'event handling' }
ChessCoachGroupElementSkin >> uncheckedSkinEvent: anEvent [

	super uncheckedSkinEvent: anEvent.
	anEvent elementDo: [ :e | self removeArrowOf: e ]
]
