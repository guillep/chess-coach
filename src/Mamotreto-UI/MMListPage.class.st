"
I am the skeleton of a Mamotreto page that lists things: the filters and the list on the left, taking all the room they can; on the right a pane of a fixed width with the actions on top and tabs below.

- The actions are always there. A page adds its buttons once and enables or disables them as the selection changes; buttons never appear or disappear.
- Each tab is a name and a block that fills it for the current selection. refreshPane fills them again, for example when the selection changes.
- A confirmation, such as 'Close 2 items?', is shown with showInPane: in place of the tabs, under the same actions; refreshPane brings the tabs back.

	page := MMListPage new.
	page filterBar addChild: aDropdown.
	page list: aTable.
	page addAction: aButton.
	page addTab: 'Overview' building: [ :holder | holder addChild: ... ].
"
Class {
	#name : 'MMListPage',
	#superclass : 'ToElement',
	#instVars : [
		'filterBar',
		'listHolder',
		'actionBar',
		'tabPane',
		'tabs',
		'body'
	],
	#category : 'Mamotreto-UI',
	#package : 'Mamotreto-UI'
}

{ #category : 'sizes' }
MMListPage class >> paneWidth [
	"The list is what matters: the pane takes only what it needs to read one thing"

	^ 340
]

{ #category : 'building' }
MMListPage >> addAction: aButton [
	"An action on the selection, at the top of the pane. It stays there: enable or disable it instead of removing it."

	aButton margin: (BlInsets
			 top: 0
			 left: 0
			 bottom: 4
			 right: 8).
	actionBar addChild: aButton.
	^ aButton
]

{ #category : 'building' }
MMListPage >> addTab: aString building: aBlock [
	"A tab of the pane; aBlock fills its scrollable holder for the current selection, now and on each refreshPane. The tab pane builds a tab's pane each time it is shown, so the same scroller moves into it."

	| holder scroller |
	holder := ToElement new
		          id: (#tab , aString) asSymbol;
		          layout: (BlLinearLayout vertical cellSpacing: 8);
		          hMatchParent;
		          vFitContent;
		          padding: (BlInsets all: 12);
		          yourself.
	scroller := MMWidgets scrollable: holder.
	tabs add: aBlock -> holder.
	tabPane addItem: (ToTabButton new
			 id: aString asSymbol;
			 labelText: aString;
			 removable: false;
			 paneBuilder: [ :pane :button :itemHolder |
					 scroller removeFromParent.
					 pane addChild: scroller ];
			 yourself).
	tabs size = 1 ifTrue: [ tabPane selecter selectIndex: 1 ].
	self fill: holder with: aBlock
]

{ #category : 'private' }
MMListPage >> fill: aHolder with: aBlock [

	aHolder removeChildren.
	aBlock value: aHolder
]

{ #category : 'accessing' }
MMListPage >> filterBar [
	"Where the page puts its filters, above the list; they flow onto more lines when they don't fit"

	^ filterBar
]

{ #category : 'initialization' }
MMListPage >> initialize [

	super initialize.
	tabs := OrderedCollection new.
	filterBar := ToElement new
		             id: #filterBar;
		             layout: BlFlowLayout horizontal;
		             hMatchParent;
		             vFitContent;
		             yourself.
	listHolder := ToElement new
		              layout: BlFrameLayout new;
		              matchParent;
		              yourself.
	actionBar := ToElement new
		             id: #actionBar;
		             layout: BlFlowLayout horizontal;
		             hMatchParent;
		             vFitContent;
		             padding: (BlInsets
				              top: 0
				              left: 12
				              bottom: 8
				              right: 12);
		             yourself.
	tabPane := ToTabPaneElement new.
	tabPane matchParent.
	tabPane showAddTabItemButton: false.
	body := ToElement new
		        layout: BlFrameLayout new;
		        matchParent;
		        addChild: tabPane;
		        yourself.
	self
		layout: (BlLinearLayout horizontal cellSpacing: 12);
		matchParent;
		addChild: (ToElement new
				 layout: (BlLinearLayout vertical cellSpacing: 8);
				 matchParent;
				 addChild: filterBar;
				 addChild: listHolder;
				 yourself);
		addChild: (ToElement new
				 id: #pane;
				 layout: BlLinearLayout vertical;
				 constraintsDo: [ :c |
						 c horizontal exact: self class paneWidth.
						 c vertical matchParent ];
				 addChild: actionBar;
				 addChild: body;
				 yourself)
]

{ #category : 'building' }
MMListPage >> list: anElement [
	"The list or table, filling the left side"

	listHolder
		removeChildren;
		addChild: anElement
]

{ #category : 'updating' }
MMListPage >> refreshPane [
	"Fill every tab again for the current selection, and bring them back if a confirmation was shown in their place"

	tabs do: [ :each | self fill: each value with: each key ].
	(body children includes: tabPane) ifFalse: [
			body
				removeChildren;
				addChild: tabPane ]
]

{ #category : 'updating' }
MMListPage >> showInPane: anElement [
	"Show anElement, such as a confirmation, in place of the tabs, under the same actions, until refreshPane"

	body
		removeChildren;
		addChild: (MMWidgets scrollable: (anElement
						  padding: (BlInsets all: 12);
						  yourself))
]

{ #category : 'updating' }
MMListPage >> showTab: aString [
	"Bring the tab named aString to the front"

	tabPane selecter selectIndex:
		(tabPane items asArray findFirst: [ :each |
			 each id = aString asSymbol ])
]
