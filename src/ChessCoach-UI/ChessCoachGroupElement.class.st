"
A titled group that looks like an accordion but stays open: same header and body, no arrow, and clicks don't close it. Rows go to my rows element.
"
Class {
	#name : 'ChessCoachGroupElement',
	#superclass : 'ToAccordionElement',
	#instVars : [
		'rows'
	],
	#category : 'ChessCoach-UI-Widgets',
	#package : 'ChessCoach-UI',
	#tag : 'Widgets'
}

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
