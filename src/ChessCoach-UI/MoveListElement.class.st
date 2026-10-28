Class {
	#name : 'MoveListElement',
	#superclass : 'BlElement',
	#instVars : [
		'game',
		'announcer',
		'selectedMoveIndex',
		'layoutMode',
		'moveElements',
		'compactContainer',
		'rigidContainer',
		'toggleButton',
		'rigidMoveElements'
	],
	#category : 'ChessCoach-UI-Board',
	#package : 'ChessCoach-UI',
	#tag : 'Board'
}

{ #category : 'examples' }
MoveListElement class >> example [
	| game list space |
	game := PGNParser new parse: '1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 *'.
	list := MoveListElement new.
	list game: game.
	space := BlSpace new.
	space root addChild: list.
	space show.
	^ list
]

{ #category : 'layout' }
MoveListElement >> applyLayout [

	layoutMode = #rigid
		ifTrue: [
				compactContainer visibility: BlVisibility gone.
				rigidContainer visibility: BlVisibility visible ]
		ifFalse: [
				compactContainer visibility: BlVisibility visible.
				rigidContainer visibility: BlVisibility gone ].
	^ self
]

{ #category : 'initialization' }
MoveListElement >> buildUI [

	| header |
	self removeChildren.
	header := BlElement new.
	header layout: BlLinearLayout horizontal.
	header constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ].
	toggleButton := BlTextElement new text: 'Rigid' asRopedText.
	toggleButton constraintsDo: [ :c |
			c horizontal fitContent.
			c vertical fitContent ].
	toggleButton margin: (BlInsets all: 4).
	toggleButton padding: (BlInsets all: 4).
	toggleButton
		addEventHandlerOn: BlClickEvent
		do: [ :event | self toggleLayout ].
	header addChild: toggleButton.
	self addChild: header.
	compactContainer := BlElement new.
	compactContainer layout: BlFlowLayout horizontal.
	compactContainer constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ].
	rigidContainer := BlElement new.
	rigidContainer layout: (BlGridLayout horizontal columnCount: 2).
	rigidContainer constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ].
	self addChild: compactContainer.
	self addChild: rigidContainer.
	self applyLayout
]

{ #category : 'accessing' }
MoveListElement >> game: aGame [
	"Show aGame with no move selected (ply 0)"

	game := aGame.
	selectedMoveIndex := 0.
	self rebuildMoves
]

{ #category : 'selection' }
MoveListElement >> highlightSelected [

	moveElements keysAndValuesDo: [ :idx :el |
			idx = selectedMoveIndex
				ifTrue: [ el background: (Color yellow alpha: 0.3) ]
				ifFalse: [ el background: Color transparent ] ].
	rigidMoveElements keysAndValuesDo: [ :idx :el |
			idx = selectedMoveIndex
				ifTrue: [ el background: (Color yellow alpha: 0.3) ]
				ifFalse: [ el background: Color transparent ] ].
	^ self
]

{ #category : 'initialization' }
MoveListElement >> initialize [

	super initialize.
	game := nil.
	announcer := Announcer new.
	selectedMoveIndex := 0.
	layoutMode := #compact.
	moveElements := Dictionary new.
	rigidMoveElements := Dictionary new.
	self layout: BlLinearLayout vertical.
	self constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ].
	self buildUI.
	self initializeShortcuts
]

{ #category : 'initialization' }
MoveListElement >> initializeShortcuts [
	"Arrow keys step through the moves. Clicking anywhere in the list (including on a move) gives it the keyboard focus"

	self addShortcut: (BlShortcutWithAction new
			 combination: BlKeyCombination arrowRight;
			 action: [ self selectNextMove ]).
	self addShortcut: (BlShortcutWithAction new
			 combination: BlKeyCombination arrowLeft;
			 action: [ self selectPreviousMove ]).
	self
		addEventHandlerOn: BlClickEvent
		do: [ :event | self requestFocus ]
]

{ #category : 'accessing' }
MoveListElement >> layoutMode [

	^ layoutMode
]

{ #category : 'building' }
MoveListElement >> newMoveElementFor: aMove at: anIndex [

	^ BlTextElement new
		  text: aMove san asRopedText;
		  margin: (BlInsets all: 4);
		  padding: (BlInsets all: 2);
		  addEventHandlerOn: BlClickEvent
		  do: [ :event | self selectMoveAt: anIndex ];
		  yourself
]

{ #category : 'building' }
MoveListElement >> rebuildMoves [

	compactContainer removeChildren.
	rigidContainer removeChildren.
	moveElements := Dictionary new.
	rigidMoveElements := Dictionary new.
	game moves doWithIndex: [ :move :index |
			| compact rigid |
			compact := self newMoveElementFor: move at: index.
			compact constraintsDo: [ :c |
					c horizontal fitContent.
					c vertical fitContent ].
			compactContainer addChild: compact.
			moveElements at: index put: compact.
			rigid := self newMoveElementFor: move at: index.
			rigid constraintsDo: [ :c |
					c horizontal matchParent.
					c vertical fitContent ].
			rigidContainer addChild: rigid.
			rigidMoveElements at: index put: rigid ].
	self applyLayout.
	self highlightSelected
]

{ #category : 'selection' }
MoveListElement >> selectMoveAt: anIndex [
	"Select the move at anIndex (a ply); 0 means no move, i.e. the initial position"

	selectedMoveIndex := anIndex.
	self highlightSelected.
	announcer announce: (MoveSelectedAnnouncement new
			 moveIndex: anIndex;
			 game: game;
			 yourself)
]

{ #category : 'selection' }
MoveListElement >> selectNextMove [

	self selectMoveAt: (selectedMoveIndex + 1 min: game moves size)
]

{ #category : 'selection' }
MoveListElement >> selectPreviousMove [

	self selectMoveAt: (selectedMoveIndex - 1 max: 0)
]

{ #category : 'accessing' }
MoveListElement >> selectedMoveIndex [

	^ selectedMoveIndex
]

{ #category : 'actions' }
MoveListElement >> toggleLayout [

	layoutMode := layoutMode = #compact
		              ifTrue: [ #rigid ]
		              ifFalse: [ #compact ].
	toggleButton ifNotNil: [
			toggleButton text: (layoutMode = #rigid
					 ifTrue: [ 'Compact' ]
					 ifFalse: [ 'Rigid' ]) asRopedText ].
	self applyLayout.
	self highlightSelected.
	^ self
]

{ #category : 'selection' }
MoveListElement >> whenMoveSelectedDo: aBlock [
	"aBlock receives the selected ply: N is the position after the Nth half-move"

	announcer
		when: MoveSelectedAnnouncement
		send: #value:
		to: [ :announcement | aBlock value: announcement moveIndex ]
]
