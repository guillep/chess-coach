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
		'rigidMoveElements',
		'markedPlies',
		'markBlock'
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
	"Two layouts: rigid, a numbered grid (number, White's move, Black's move), and compact, a flow of moves. A toggle button switches to compact when checked."

	| header |
	self removeChildren.
	header := BlElement new.
	header layout: BlLinearLayout horizontal.
	header constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ].
	toggleButton := ToToggleButton new
		                labelText: 'Compact';
		                margin: (BlInsets all: 4);
		                yourself.
	toggleButton checked: layoutMode = #compact.
	toggleButton newCheckAction: [ self toggleLayout ].
	header addChild: toggleButton.
	self addChild: header.
	compactContainer := BlElement new.
	compactContainer layout: BlFlowLayout horizontal.
	compactContainer constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ].
	rigidContainer := BlElement new.
	rigidContainer layout: (BlGridLayout horizontal columnCount: 3).
	rigidContainer constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ].
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
	layoutMode := #rigid.
	moveElements := Dictionary new.
	rigidMoveElements := Dictionary new.
	markedPlies := Set new.
	markBlock := [ :ply |  ].
	self layout: BlLinearLayout vertical.
	self constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ].
	self buildUI.
	self initializeShortcuts
]

{ #category : 'initialization' }
MoveListElement >> initializeShortcuts [
	"Arrow keys step through the moves; Enter or Space asks to mark the selected one. Clicking anywhere in the list (including on a move) gives it the keyboard focus"

	self addShortcut: (BlShortcutWithAction new
			 combination: BlKeyCombination arrowRight;
			 action: [ self selectNextMove ]).
	self addShortcut: (BlShortcutWithAction new
			 combination: BlKeyCombination arrowLeft;
			 action: [ self selectPreviousMove ]).
	{
		BlKeyCombination return.
		BlKeyCombination space } do: [ :each |
			self addShortcut: (BlShortcutWithAction new
					 combination: each;
					 action: [
						 selectedMoveIndex > 0 ifTrue: [
								 markBlock value: selectedMoveIndex ] ]) ].
	self
		addEventHandlerOn: BlClickEvent
		do: [ :event | self requestFocus ]
]

{ #category : 'accessing' }
MoveListElement >> layoutMode [

	^ layoutMode
]

{ #category : 'accessing' }
MoveListElement >> markedPlies: someIntegers [
	"Show a * before the marked moves"

	markedPlies := someIntegers asSet.
	game ifNotNil: [ self rebuildMoves ]
]

{ #category : 'accessing' }
MoveListElement >> moveTexts [
	"The texts of the moves, in order (for tests)"

	^ (1 to: rigidMoveElements size) collect: [ :each |
		  (rigidMoveElements at: each) text asString ]
]

{ #category : 'building' }
MoveListElement >> newMoveElementFor: aMove at: anIndex [
	"A label, so that its text follows the app theme"

	^ ToLabel new
		  text: ((markedPlies includes: anIndex)
				   ifTrue: [ '*' , aMove san ]
				   ifFalse: [ aMove san ]);
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
			compact fitContent.
			compactContainer addChild: compact.
			moveElements at: index put: compact.
			index odd ifTrue: [
					rigidContainer addChild: (ToLabel new
							 text: (index + 1 // 2) printString , '.';
							 margin: (BlInsets all: 4);
							 padding: (BlInsets all: 2);
							 yourself) ].
			rigid := self newMoveElementFor: move at: index.
			rigid
				hMatchParent;
				vFitContent.
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

{ #category : 'selection' }
MoveListElement >> selectedPly [

	^ selectedMoveIndex
]

{ #category : 'actions' }
MoveListElement >> toggleLayout [

	layoutMode := layoutMode = #compact
		              ifTrue: [ #rigid ]
		              ifFalse: [ #compact ].
	self applyLayout.
	self highlightSelected
]

{ #category : 'accessing' }
MoveListElement >> whenMarkRequestedDo: aBlock [
	"aBlock receives the selected ply when Enter or Space is pressed"

	markBlock := aBlock
]

{ #category : 'selection' }
MoveListElement >> whenMoveSelectedDo: aBlock [
	"aBlock receives the selected ply: N is the position after the Nth half-move"

	announcer
		when: MoveSelectedAnnouncement
		send: #value:
		to: [ :announcement | aBlock value: announcement moveIndex ]
]
