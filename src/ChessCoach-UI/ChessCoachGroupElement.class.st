"
A titled group that looks like an accordion but stays open: same header and body, no arrow, and clicks don't close it. Rows go to my rows element.
"
Class {
	#name : 'ChessCoachGroupElement',
	#superclass : 'ToAccordionElement',
	#instVars : [
		'rows',
		'collapsible'
	],
	#category : 'ChessCoach-UI-Widgets',
	#package : 'ChessCoach-UI',
	#tag : 'Widgets'
}

{ #category : 'accessing' }
ChessCoachGroupElement >> beCollapsible [
	"Behave as a real accordion: the header opens and closes me"

	collapsible := true.
	self switchToNextCheckStateOnClick: true
]

{ #category : 'initialization' }
ChessCoachGroupElement >> initialize [

	super initialize.
	rows := ToElement new
		        layout: (BlLinearLayout vertical cellSpacing: 8);
		        hMatchParent;
		        vFitContent;
		        padding: (BlInsets all: 12);
		        yourself.
	self bodyBuilder: [ :body | body addChild: rows ].
	self switchToNextCheckStateOnClick: false.
	self expand
]

{ #category : 'testing' }
ChessCoachGroupElement >> isCollapsible [

	^ collapsible == true
]

{ #category : 'skin' }
ChessCoachGroupElement >> newRawSkin [

	^ ChessCoachGroupElementSkin new
]

{ #category : 'accessing' }
ChessCoachGroupElement >> rows [
	"The element that holds my rows"

	^ rows
]

{ #category : 'accessing' }
ChessCoachGroupElement >> title: aTitle help: aHelpStringOrNil [
	"A title bar slightly darker than the body, on both themes, with a line below"

	self clipChildren: true.
	self header
		background: (Color gray alpha: 0.14);
		border: (BlBorder paint: (Color gray alpha: 0.25) width: 1);
		padding: (BlInsets top: 6 left: 12 bottom: 6 right: 12).
	self headerBuilder: [ :header |
		header addChild: (ChessCoachWidgets heading: aTitle help: aHelpStringOrNil) ]
]

{ #category : 'layout' }
ChessCoachGroupElement >> vMatchParent [
	"Pass the height down, for rows that scroll"

	super vMatchParent.
	body vMatchParent.
	body content vMatchParent.
	rows vMatchParent
]
