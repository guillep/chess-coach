"
The building blocks every page shares, so they look alike: page titles in a larger font, section headings, bordered groups of rows, and help icons whose tooltip explains the thing next to them.
"
Class {
	#name : 'ChessCoachWidgets',
	#superclass : 'Object',
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'building' }
ChessCoachWidgets class >> group: someElements [
	"A bordered, padded box that keeps related rows together"

	| box |
	box := ToElement new
		       layout: (BlLinearLayout vertical cellSpacing: 8);
		       hMatchParent;
		       vFitContent;
		       padding: (BlInsets all: 12);
		       border: (BlBorder paint: (Color gray alpha: 0.35) width: 1);
		       geometry: (BlRoundedRectangleGeometry cornerRadius: 6);
		       yourself.
	someElements do: [ :each | box addChild: each ].
	^ box
]

{ #category : 'building' }
ChessCoachWidgets class >> heading: aString help: aHelpStringOrNil [
	"A section heading, larger than the text, with a help icon when there is something to explain"

	| row |
	row := ToElement new
		       layout: (BlLinearLayout horizontal cellSpacing: 6);
		       hMatchParent;
		       vFitContent;
		       yourself.
	row addChild: (ToLabel new
			 text: (aString asRopedText
					  fontSize: 17;
					  bold;
					  yourself);
			 yourself).
	aHelpStringOrNil ifNotNil: [
		row addChild: (self help: aHelpStringOrNil) ].
	^ row
]

{ #category : 'building' }
ChessCoachWidgets class >> help: aString [
	"A small help icon; its tooltip says aString"

	^ (ToMaterialDesignIconProvider iconNamed: 'outlined_helpoutline')
		  extent: 16 @ 16;
		  tooltipString: aString;
		  yourself
]

{ #category : 'building' }
ChessCoachWidgets class >> pageTitle: aTitle subtitle: aSubtitle [
	"The title on top of a page, in a larger font, with one line of context"

	^ ToElement new
		  layout: (BlLinearLayout vertical cellSpacing: 2);
		  hMatchParent;
		  vFitContent;
		  padding: (BlInsets bottom: 8);
		  addChild: (ToLabel new
				   text: (aTitle asRopedText
						    fontSize: 24;
						    bold;
						    yourself);
				   yourself);
		  addChild: (ToLabel new
				   text: (aSubtitle asRopedText
						    foreground: Color gray;
						    yourself);
				   yourself);
		  yourself
]

{ #category : 'building' }
ChessCoachWidgets class >> paragraph: aString [
	"A label for short texts. Longer ones are read-only text fields, which wrap at word boundaries. Workaround: Toplo labels don't wrap (logged as an upstream candidate)."

	aString size <= 45 ifTrue: [
			^ ToLabel new
				  hMatchParent;
				  text: aString;
				  yourself ].
	^ ToTextField new
		  wrappingMode: true;
		  hMatchParent;
		  vFitContent;
		  text: aString;
		  beReadonlyWithoutSelection;
		  yourself
]

{ #category : 'building' }
ChessCoachWidgets class >> section: aTitle help: aHelpStringOrNil rows: someElements [
	"A heading followed by a group of rows"

	^ self group:
		  { (self heading: aTitle help: aHelpStringOrNil) } , someElements
]

{ #category : 'building' }
ChessCoachWidgets class >> withHelp: anElement text: aString [
	"anElement followed by a help icon"

	^ ToElement new
		  layout: (BlLinearLayout horizontal cellSpacing: 6);
		  hMatchParent;
		  vFitContent;
		  addChild: anElement;
		  addChild: (self help: aString);
		  yourself
]
