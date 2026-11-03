"
A titled group that looks like an accordion but stays open: same header and body, no arrow, and clicks don't close it. Rows go to my rows element.
"
Class {
	#name : 'MMGroupElement',
	#superclass : 'ToAccordionElement',
	#instVars : [
		'rows',
		'collapsible'
	],
	#category : 'Mamotreto-UI-Widgets',
	#package : 'Mamotreto-UI',
	#tag : 'Widgets'
}

{ #category : 'accessing' }
MMGroupElement >> beCollapsible [
	"Behave as a real accordion: the header opens and closes me"

	collapsible := true.
	self switchToNextCheckStateOnClick: true
]

{ #category : 'initialization' }
MMGroupElement >> initialize [

	super initialize.
	rows := ToElement new
		        layout: (BlLinearLayout vertical cellSpacing: 8);
		        hMatchParent;
		        vFitContent;
		        padding: MMWidgets groupBodyPadding;
		        yourself.
	self bodyBuilder: [ :body | body addChild: rows ].
	self switchToNextCheckStateOnClick: false.
	self expand
]

{ #category : 'testing' }
MMGroupElement >> isCollapsible [

	^ collapsible == true
]

{ #category : 'skin' }
MMGroupElement >> newRawSkin [

	^ MMGroupElementSkin new
]

{ #category : 'accessing' }
MMGroupElement >> rows [
	"The element that holds my rows"

	^ rows
]

{ #category : 'accessing' }
MMGroupElement >> title: aTitle help: aHelpStringOrNil [
	"A title bar slightly darker than the body, on both themes, with a line below"

	self clipChildren: true.
	self header
		background: (Color gray alpha: 0.14);
		border: (BlBorder paint: (Color gray alpha: 0.25) width: 1);
		padding: MMWidgets groupTitlePadding.
	self headerBuilder: [ :header |
		header addChild: (MMWidgets heading: aTitle help: aHelpStringOrNil) ]
]

{ #category : 'layout' }
MMGroupElement >> vMatchParent [
	"Pass the height down, for rows that scroll"

	super vMatchParent.
	body vMatchParent.
	body content vMatchParent.
	rows vMatchParent
]
