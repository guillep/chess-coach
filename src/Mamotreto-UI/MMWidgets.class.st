"
The building blocks every page of a Mamotreto app shares, so they look alike: page titles in a larger font, section headings, groups of rows, toggles, dropdowns, links and help icons whose tooltip explains the thing next to them. The sizes the shell uses everywhere are named here too.

The icon tint is a class variable, so an app's subclass of me and I share it.
"
Class {
	#name : 'MMWidgets',
	#superclass : 'Object',
	#classVars : [
		'IconColor'
	],
	#category : 'Mamotreto-UI-Widgets',
	#package : 'Mamotreto-UI',
	#tag : 'Widgets'
}

{ #category : 'building' }
MMWidgets class >> bigButton: aString icon: anIconName do: aBlock [
	"A main action of a page: a full-width primary button"

	^ (self primaryButton: aString icon: anIconName do: aBlock)
		  hMatchParent;
		  padding: (BlInsets all: 12);
		  yourself
]

{ #category : 'building' }
MMWidgets class >> centered: anElement [
	"anElement centred in the space it gets"

	anElement constraintsDo: [ :c |
			c frame horizontal alignCenter.
			c frame vertical alignCenter ].
	^ ToElement new
		  layout: BlFrameLayout new;
		  matchParent;
		  addChild: anElement;
		  yourself
]

{ #category : 'building' }
MMWidgets class >> choiceBar: someAssociations selected: aValue do: aBlock [
	"One toggle per label -> value association, in one row, exactly one checked. The chosen one has the toggle's colour and a tick, as everywhere in the app."

	| bar group buttons mark |
	bar := ToElement new
		       layout: BlFlowLayout horizontal;
		       fitContent;
		       yourself.
	group := ToCheckableGroup new.
	buttons := someAssociations collect: [ :each |
			           | button |
			           button := ToToggleButton new.
			           group register: button.
			           bar addChild: button.
			           each -> button ].
	mark := [
		        buttons do: [ :each |
				        each value labelText: (each value isChecked
						         ifTrue: [ '✓ ' , each key key ]
						         ifFalse: [ each key key ]) ] ].
	buttons do: [ :each |
		each key value = aValue ifTrue: [ each value check ] ].
	mark value.
	buttons do: [ :each |
			each value newCheckAction: [
					each value isChecked ifTrue: [
							mark value.
							aBlock value: each key value ] ] ].
	^ bar
]

{ #category : 'building' }
MMWidgets class >> credits [
	"Done with Pharo, Bloc and love, by me"

	^ ToElement new
		  layout: (BlLinearLayout horizontal alignCenterLeft cellSpacing: 4);
		  fitContent;
		  addChild: (ToLabel text: 'Done with Pharo');
		  addChild: self pharoLogo;
		  addChild: (ToLabel text: ', Bloc and love');
		  addChild: (self icon: 'filled_favorite' extent: 14 @ 14);
		  addChild: (ToLabel text: 'by');
		  addChild: (self link: 'Guille' to: 'https://github.com/guillep');
		  yourself
]

{ #category : 'building' }
MMWidgets class >> dropdown: someAssociations [
	"A dropdown of label -> value associations with the first one selected. Its list stops at the bottom of the window and scrolls."

	| select |
	select := ToSingleSelectElement new.
	select manager maxHeightPolicy:
		ToSelectPopupMatchParentMaxHeightPolicy new.
	select popupListElement nodeBuilder: [ :node :assoc :holder |
		node addChild: (ToLabel text: assoc key) ].
	select dataViewBuilder: [ :view :assoc |
		view addChild: (ToLabel text: assoc key) ].
	select popupDataAccessor addAll: someAssociations.
	select selecter selectIndex: 1.
	^ select
]

{ #category : 'sizes' }
MMWidgets class >> groupBodyPadding [
	"The rows of a group, inside Toplo's own body padding"

	^ BlInsets left: 8 right: 8
]

{ #category : 'sizes' }
MMWidgets class >> groupTitlePadding [
	"The title bar of a group"

	^ BlInsets
		  top: 6
		  left: 12
		  bottom: 6
		  right: 12
]

{ #category : 'building' }
MMWidgets class >> heading: aString help: aHelpStringOrNil [
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
MMWidgets class >> help: aString [
	"A small help icon; its tooltip says aString, on hover or on click. The tooltip stays open after the click (not closed on release); a click outside closes it."

	| icon |
	icon := (self icon: 'outlined_helpoutline' extent: 16 @ 16)
		        tooltipString: aString;
		        yourself.
	icon tooltipManagerDo: [ :manager | manager closeOnReleased: false ].
	icon addEventHandlerOn: BlClickEvent do: [ :event |
		icon tooltipManagerDo: [ :manager | manager popupEvent: event ] ].
	^ icon
]

{ #category : 'accessing' }
MMWidgets class >> humanize: aKind [
	"A kind as people read it: 'longThink' as 'long think'"

	^ String streamContents: [ :stream |
			  aKind do: [ :each |
					  each isUppercase ifTrue: [ stream space ].
					  stream nextPut: each asLowercase ] ]
]

{ #category : 'building' }
MMWidgets class >> icon: aName extent: aPoint [
	"A Material Design icon outside a button, in the tint of the app theme"

	| icon |
	icon := (ToMaterialDesignIconProvider iconNamed: aName)
		        extent: aPoint;
		        yourself.
	IconColor ifNotNil: [ icon innerImageColor: IconColor ].
	^ icon
]

{ #category : 'accessing' }
MMWidgets class >> iconColor: aColor [
	"The tint of the icons outside buttons, which Toplo's skins don't reach"

	IconColor := aColor
]

{ #category : 'building' }
MMWidgets class >> link: aString to: anUrl [
	"A label that opens anUrl; a label, not a button, so it fits the status bar"

	| label |
	label := ToLabel new
		         text: (aString asRopedText
				          foreground: (Color fromHexString: '#c98a4b');
				          yourself);
		         yourself.
	label
		addEventHandlerOn: BlClickEvent
		do: [ :event | WebBrowser openOn: anUrl ].
	^ label
]

{ #category : 'building' }
MMWidgets class >> page: someElements [
	"A page's top-level column, with the same margins on every page"

	| page |
	page := ToElement new
		        layout: BlLinearLayout vertical;
		        matchParent;
		        padding: self pagePadding;
		        yourself.
	someElements do: [ :each | page addChild: each ].
	^ page
]

{ #category : 'building' }
MMWidgets class >> page: aTitle subtitle: aSubtitle actions: someElements body: anElement [
	"A page with buttons at the top right of its title, for closable pages"

	| title |
	title := self pageTitle: aTitle subtitle: aSubtitle.
	^ self page: {
			  (ToElement new
				   layout: (BlLinearLayout horizontal cellSpacing: 4);
				   hMatchParent;
				   vFitContent;
				   addChildren: { title } , someElements;
				   yourself).
			  anElement }
]

{ #category : 'building' }
MMWidgets class >> page: aTitle subtitle: aSubtitle body: anElement [
	"Every page: the same margins, its title on top (it doesn't scroll) and anElement filling the rest"

	^ self page: {
			  (self pageTitle: aTitle subtitle: aSubtitle).
			  anElement }
]

{ #category : 'sizes' }
MMWidgets class >> pagePadding [
	"Every page: 16 at the top and sides, none at the bottom, so the content reaches the status bar"

	^ BlInsets
		  top: 16
		  left: 16
		  bottom: 0
		  right: 16
]

{ #category : 'building' }
MMWidgets class >> pageTitle: aTitle subtitle: aSubtitle [
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
MMWidgets class >> paragraph: aString [
	"A text that wraps at word boundaries: short ones are a label, longer ones one label per word in a flow layout, since multi-line Toplo labels fit their content and don't wrap (logged as an upstream candidate)"

	| flow |
	aString size <= 45 ifTrue: [
			^ ToLabel new
				  hMatchParent;
				  text: aString;
				  yourself ].
	flow := ToElement new
		        layout: BlFlowLayout horizontal;
		        hMatchParent;
		        vFitContent;
		        yourself.
	aString substrings do: [ :word |
			flow addChild: (ToLabel new
					 text: word;
					 margin: (BlInsets right: 4);
					 yourself) ].
	^ flow
]

{ #category : 'accessing' }
MMWidgets class >> paragraphTextOf: anElement [
	"The whole text of a long paragraph (a flow of word labels), or nil for any other element"

	((anElement layout isKindOf: BlFlowLayout) and: [
			 anElement children notEmpty and: [
				 anElement children allSatisfy: [ :each | each isKindOf: ToLabel ] ] ])
		ifFalse: [ ^ nil ].
	^ ' ' join:
		  (anElement children asArray collect: [ :each | each text asString ])
]

{ #category : 'building' }
MMWidgets class >> pharoLogo [

	^ ((Smalltalk ui icons iconNamed: #pharo) scaledToSize: 16 @ 16)
		  asElement yourself
]

{ #category : 'building' }
MMWidgets class >> primaryButton: aString icon: anIconName do: aBlock [
	"The main action of a view: a filled button with an icon. The raw themes ignore the #primary stamp, so the button's own tokens give it the primary colours."

	| button primary |
	button := ToButton new
		          labelText: aString;
		          icon:
			          ((ToMaterialDesignIconProvider iconNamed: anIconName)
				           extent: 20 @ 20;
				           yourself);
		          clickAction: aBlock;
		          padding: (BlInsets
				           top: 8
				           left: 16
				           bottom: 8
				           right: 16);
		          yourself.
	primary := Color fromHexString: '#2f6b45'.
	button
		addTokenNamed: #'color-bg-container' withValue: primary;
		addTokenNamed: #'color-border' withValue: primary;
		addTokenNamed: #'color-text' withValue: Color white;
		addTokenNamed: #'color-primary' withValue: Color white;
		addTokenNamed: #'color-primary-hover' withValue: Color white;
		addTokenNamed: #'color-primary-pressed' withValue: Color white.
	^ button
]

{ #category : 'building' }
MMWidgets class >> scrollable: anElement [
	"anElement in a vertically scrollable area filling its parent, with a scrollbar along its right side"

	| scrollable scrollbar |
	scrollable := anElement asScrollableElement.
	scrollable constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ].
	scrollbar := ToScrollbarElement horizontal: false.
	scrollbar constraintsDo: [ :c |
			c ignoreByLayout.
			c vertical matchParent.
			c horizontal exact: 10.
			c ignored horizontal alignRight.
			c ignored vertical alignTop ].
	scrollbar attachTo: scrollable.
	^ ToElement new
		  layout: BlFrameLayout new;
		  matchParent;
		  addChild: scrollable;
		  addChild: scrollbar;
		  yourself
]

{ #category : 'building' }
MMWidgets class >> section: aTitle help: aHelpStringOrNil rows: someElements [
	"A heading followed by a group of rows, that looks like an accordion and stays open"

	| group |
	group := MMGroupElement new.
	group title: aTitle help: aHelpStringOrNil.
	someElements do: [ :each | group rows addChild: each ].
	^ group
]

{ #category : 'building' }
MMWidgets class >> selectableParagraph: aString [
	"Read-only text that wraps and can be selected and copied"

	^ ToTextField new
		  wrappingMode: true;
		  hMatchParent;
		  vFitContent;
		  text: aString;
		  beReadonlyWithSelection;
		  yourself
]

{ #category : 'building' }
MMWidgets class >> separator [
	"A 1 px translucent horizontal line, for light and dark themes"

	^ BlElement new
		  height: 1;
		  constraintsDo: [ :c | c horizontal matchParent ];
		  background: (Color gray alpha: 0.3);
		  margin: (BlInsets
				   top: 4
				   left: 0
				   bottom: 4
				   right: 0);
		  yourself
]

{ #category : 'building' }
MMWidgets class >> withHelp: anElement text: aString [
	"anElement followed by a help icon"

	^ ToElement new
		  layout: (BlLinearLayout horizontal cellSpacing: 6);
		  hMatchParent;
		  vFitContent;
		  addChild: anElement;
		  addChild: (self help: aString);
		  yourself
]
