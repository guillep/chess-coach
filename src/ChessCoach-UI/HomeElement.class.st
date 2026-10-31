"
I am the landing page: a game to review, usage numbers, the latest games and the notifications. I refresh each time I am shown.
"
Class {
	#name : 'HomeElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'gameBlock',
		'zone',
		'editing',
		'configured',
		'confirming',
		'toolbar',
		'titleField'
	],
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'actions' }
HomeElement >> addWidgetOf: aClass [

	self grid widgets add: (aClass atCell: (0 @ 1000 extent: 6 @ 4)).
	self grid compact.
	self update
]

{ #category : 'building' }
HomeElement >> barOf: aWidget in: aCard [
	"Drag it to move the card: the position follows the mouse from where the drag started, whether or not a layout has run"

	| bar start startPosition target |
	bar := ToElement new
		       id: #bar;
		       layout:
			       (BlLinearLayout horizontal alignCenterRight cellSpacing: 4);
		       hMatchParent;
		       vFitContent;
		       padding: (BlInsets all: 4);
		       background: (Color gray alpha: 0.15);
		       yourself.
	bar addChild: (self toolButton: 'Configure' do: [
				 self keepTitle.
				 configured := configured == aWidget
					               ifTrue: [ nil ]
					               ifFalse: [ aWidget ].
				 self update ]).
	bar addChild:
		(self toolButton: 'Remove' do: [ self remove: aWidget ]).
	bar addEventHandlerOn: BlDragStartEvent do: [ :event |
			event consume.
			start := event position.
			startPosition := aCard position.
			target := startPosition ].
	bar addEventHandlerOn: BlDragEvent do: [ :event |
			target := startPosition + (event position - start).
			aCard position: target ].
	bar
		addEventHandlerOn: BlDragEndEvent
		do: [ :event | self drop: aWidget at: target ].
	^ bar
]

{ #category : 'building' }
HomeElement >> cardOf: aWidget [
	"The widget's title and rows, scrolling inside the card. While editing it has a bar to drag, its options unfold above the content, and a corner resizes it."

	| rows card column |
	rows := aWidget rowsOn: self.
	column := ToElement new
		          layout: (BlLinearLayout vertical cellSpacing: 6);
		          hMatchParent;
		          vFitContent;
		          padding: (BlInsets all: 12);
		          yourself.
	configured == aWidget ifTrue: [
			titleField := ToTextField new
				              hMatchParent;
				              text: aWidget title;
				              yourself.
			column addChild: titleField.
			(aWidget optionRowsOn: self) do: [ :each | column addChild: each ] ].
	column addChild: (ChessCoachWidgets heading: aWidget title help: nil).
	rows do: [ :each | column addChild: each ].
	card := ToElement new
		        layout: BlLinearLayout vertical;
		        border: (BlBorder paint: (Color gray alpha: 0.35) width: 1);
		        geometry: (BlRoundedRectangleGeometry cornerRadius: 6);
		        yourself.
	card userData at: #widget put: aWidget.
	editing ifTrue: [ card addChild: (self barOf: aWidget in: card) ].
	card addChild: (ChessCoachWidgets scrollable: column).
	editing ifTrue: [ card addChild: (self cornerOf: aWidget in: card) ].
	^ card
]

{ #category : 'accessing' }
HomeElement >> cards [

	^ zone children asArray
]

{ #category : 'actions' }
HomeElement >> confirm: aString then: aBlock [

	confirming := aString -> aBlock.
	self update
]

{ #category : 'building' }
HomeElement >> cornerOf: aWidget in: aCard [
	"Drag it to resize the card: the size follows the mouse from where the drag started, whether or not a layout has run"

	| corner start startExtent target |
	corner := ToElement new
		          id: #corner;
		          extent: 14 @ 14;
		          background: (Color gray alpha: 0.35);
		          constraintsDo: [ :c |
				          c ignoreByLayout.
				          c ignored horizontal alignRight.
				          c ignored vertical alignBottom ];
		          yourself.
	corner addEventHandlerOn: BlDragStartEvent do: [ :event |
			event consume.
			start := event position.
			startExtent := aCard extent.
			target := startExtent ].
	corner addEventHandlerOn: BlDragEvent do: [ :event |
			target := startExtent + (event position - start).
			aCard extent: target ].
	corner
		addEventHandlerOn: BlDragEndEvent
		do: [ :event | self resize: aWidget to: target ].
	^ corner
]

{ #category : 'actions' }
HomeElement >> drop: aWidget at: aPoint [
	"Snap to the nearest cell"

	| column |
	column := zone width - 16 / 12.
	self grid
		place: aWidget
		at: ((aPoint x / column) rounded @ (aPoint y / self rowHeight) rounded extent:
				 aWidget cell extent).
	self placeCards
]

{ #category : 'actions' }
HomeElement >> finishSaving: aBoolean [
	"Done saves; Cancel goes back to what the file has"

	self keepTitle.
	aBoolean
		ifTrue: [ session homeConfiguration save ]
		ifFalse: [ session homeConfiguration reload ].
	editing := false.
	configured := nil.
	self update
]

{ #category : 'building' }
HomeElement >> gameButton: anEntry [

	^ ToButton new
		  labelText: ('{1} – {2} · {3} · {4}' format: {
						   anEntry players first.
						   anEntry players second.
						   anEntry result.
						   anEntry date });
		  clickAction: [ gameBlock value: anEntry ];
		  yourself
]

{ #category : 'accessing' }
HomeElement >> grid [

	^ session homeConfiguration grid
]

{ #category : 'initialization' }
HomeElement >> initialize [

	super initialize.
	gameBlock := [ :entry |  ].
	editing := false.
	self layout: BlFrameLayout new.
	self matchParent.
	zone := ToElement new
		        layout: BlBasicLayout new;
		        hMatchParent;
		        vExact: 0;
		        yourself.
	toolbar := ToElement new
		           layout: BlFlowLayout horizontal alignCenterRight;
		           hMatchParent;
		           vFitContent;
		           padding: (BlInsets
				            top: 0
				            left: 0
				            bottom: 8
				            right: 24);
		           yourself.
	self addChild: (ChessCoachWidgets page: {
				 (ChessCoachWidgets
					  pageTitle: 'Home'
					  subtitle: 'Pour a mate. Here is what is going on.').
				 toolbar.
				 (ChessCoachWidgets scrollable: zone) }).
	zone
		addEventHandlerOn: BlElementExtentChangedEvent
		do: [ :event | self placeCards ].
	self
		addEventHandlerOn: BlElementExtentChangedEvent
		do: [ :event | self placeCards ].
	self
		addEventHandlerOn: BlElementAddedToSceneGraphEvent
		do: [ :event | session ifNotNil: [ self update ] ]
]

{ #category : 'layout' }
HomeElement >> isStacked [

	^ zone width < 700
]

{ #category : 'actions' }
HomeElement >> keepTitle [
	"The title being edited; an empty one goes back to the default"

	(configured notNil and: [ titleField notNil ]) ifTrue: [
			configured
				option: 'title'
				put: (titleField text asString ifEmpty: [ nil ]) ].
	titleField := nil
]

{ #category : 'layout' }
HomeElement >> placeCards [
	"Cards at their cells, with columns that scale; stacked in reading order in a narrow window, without changing what is saved. Right padding leaves room for the scrollbar."

	| column row bottom |
	session ifNil: [ ^ self ].
	column := zone width - 16 / 12.
	row := self rowHeight.
	bottom := 0.
	zone children do: [ :card |
			| cell rectangle |
			cell := (card userData at: #widget) cell.
			rectangle := self isStacked
				             ifTrue: [
				             0 @ bottom extent:
					             zone width - 16 @ (cell height * row - 8) ]
				             ifFalse: [
						             cell left * column @ (cell top * row) extent:
							             cell width * column - 8 @ (cell height * row - 8) ].
			card position: rectangle origin.
			card extent: rectangle extent.
			bottom := bottom max: rectangle bottom + 8 ].
	zone height = bottom ifFalse: [ zone vExact: bottom ]
]

{ #category : 'actions' }
HomeElement >> remove: aWidget [

	| removal |
	removal := [
		           self grid widgets remove: aWidget.
		           self grid compact ].
	aWidget options
		ifEmpty: [
				removal value.
				self update ]
		ifNotEmpty: [
		self confirm: 'Remove ' , aWidget title , '?' then: removal ]
]

{ #category : 'actions' }
HomeElement >> resize: aWidget to: aPoint [
	"Snap to cells, not below the type's minimum"

	| column minimum |
	column := zone width - 16 / 12.
	minimum := aWidget class minimumExtent.
	self grid place: aWidget at: (aWidget cell origin extent:
			 ((aPoint x / column) rounded max: minimum x)
			 @ ((aPoint y / self rowHeight) rounded max: minimum y)).
	self placeCards
]

{ #category : 'layout' }
HomeElement >> rowHeight [
	"Fixed, because text doesn't scale with the window; columns do"

	^ 40
]

{ #category : 'accessing' }
HomeElement >> session [

	^ session
]

{ #category : 'accessing' }
HomeElement >> session: aChessCoachSession [

	session := aChessCoachSession.
	self update
]

{ #category : 'accessing' }
HomeElement >> titleField [

	^ titleField
]

{ #category : 'private' }
HomeElement >> toolButton: aString do: aBlock [

	^ ToButton new
		  labelText: aString;
		  margin: (BlInsets all: 3);
		  clickAction: aBlock;
		  yourself
]

{ #category : 'updating' }
HomeElement >> update [
	"The toolbar and one card per widget"

	self updateToolbar.
	zone removeChildren.
	self grid widgets do: [ :each | zone addChild: (self cardOf: each) ].
	self placeCards
]

{ #category : 'updating' }
HomeElement >> updateToolbar [

	toolbar removeChildren.
	confirming ifNotNil: [
			toolbar addChild: (ToLabel text: confirming key).
			toolbar addChild: (self toolButton: 'Yes' do: [
						 | action |
						 action := confirming value.
						 confirming := nil.
						 action value.
						 self update ]).
			toolbar addChild: (self toolButton: 'No' do: [
						 confirming := nil.
						 self update ]).
			^ self ].
	editing ifFalse: [
			toolbar addChild: (self toolButton: 'Customize' do: [
						 editing := true.
						 self update ]).
			^ self ].
	HomeWidget subclasses do: [ :class |
			toolbar addChild: (self
					 toolButton: '+ ' , (class new defaultTitle truncateTo: 14)
					 do: [ self addWidgetOf: class ]) ].
	toolbar addChild: (self toolButton: 'Reset' do: [
				 self
					 confirm: 'Reset to the default Home?'
					 then: [ session homeConfiguration resetToDefault ] ]).
	toolbar addChild:
		(self toolButton: 'Cancel' do: [ self finishSaving: false ]).
	toolbar addChild:
		(self toolButton: 'Done' do: [ self finishSaving: true ])
]

{ #category : 'accessing' }
HomeElement >> whenGameChosenDo: aBlock [
	"aBlock receives the index entry of a game to open"

	gameBlock := aBlock
]
