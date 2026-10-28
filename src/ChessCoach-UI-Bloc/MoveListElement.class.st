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
	#category : 'ChessCoach-UI-Bloc',
	#package : 'ChessCoach-UI-Bloc'
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

{ #category : 'building' }
MoveListElement >> buildRigid [

	| moves |
	game ifNil: [ ^ self ].
	moves := game moves ifNil: [ #(  ) ].
	0 to: moves size - 1 by: 2 do: [ :i |
			| m1 m2 |
			m1 := moves at: i + 1 ifAbsent: [ nil ].
			m2 := moves at: i + 2 ifAbsent: [ nil ].
			m1 ifNotNil: [
					| e1 idx1 |
					idx1 := i + 1.
					e1 := BlTextElement new text: (m1 san ifNil: [ '' ]) asRopedText.
					e1 constraintsDo: [ :c |
							c horizontal matchParent.
							c vertical fitContent ].
					e1 margin: (BlInsets all: 4).
					e1 padding: (BlInsets all: 2).
					[ e1 when: BlClickEvent do: [ :ev | self selectMoveAt: idx1 ] ]
						on: Error
						do: [
								e1
									addEventHandlerOn: BlClickEvent
									do: [ :ev | self selectMoveAt: idx1 ] ].
					rigidContainer ifNotNil: [ rigidContainer addChild: e1 ].
					rigidMoveElements at: idx1 put: e1 ].
			m2 ifNotNil: [
					| e2 idx2 |
					idx2 := i + 2.
					e2 := BlTextElement new text: (m2 san ifNil: [ '' ]) asRopedText.
					e2 constraintsDo: [ :c |
							c horizontal matchParent.
							c vertical fitContent ].
					e2 margin: (BlInsets all: 4).
					e2 padding: (BlInsets all: 2).
					[ e2 when: BlClickEvent do: [ :ev | self selectMoveAt: idx2 ] ]
						on: Error
						do: [
								e2
									addEventHandlerOn: BlClickEvent
									do: [ :ev | self selectMoveAt: idx2 ] ].
					rigidContainer ifNotNil: [ rigidContainer addChild: e2 ].
					rigidMoveElements at: idx2 put: e2 ] ].
	^ self
]

{ #category : 'initialization' }
MoveListElement >> buildUI [

	| h |
	self removeChildren.
	h := BlElement new.
	h layout: BlLinearLayout horizontal.
	h constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ].
	toggleButton := BlTextElement new text: 'Rigid' asRopedText.
	toggleButton constraintsDo: [ :c |
			c horizontal fitContent.
			c vertical fitContent ].
	toggleButton margin: (BlInsets all: 4).
	toggleButton padding: (BlInsets all: 4).
	[ toggleButton when: BlClickEvent do: [ :e | self toggleLayout ] ]
		on: Error
		do: [
				toggleButton
					addEventHandlerOn: BlClickEvent
					do: [ :e | self toggleLayout ] ].
	h addChild: toggleButton.
	self addChild: h.
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
	self applyLayout.
	^ self
]

{ #category : 'accessing' }
MoveListElement >> game: aGame [

	game := aGame.
	self rebuildMoves.
	^ self
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
	selectedMoveIndex := nil.
	layoutMode := #compact.
	moveElements := Dictionary new.
	rigidMoveElements := Dictionary new.
	self layout: BlLinearLayout vertical.
	self constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ].
	self buildUI.
	^ self
]

{ #category : 'accessing' }
MoveListElement >> layoutMode [

	^ layoutMode
]

{ #category : 'building' }
MoveListElement >> rebuildMoves [

	compactContainer ifNotNil: [ compactContainer removeChildren ].
	rigidContainer ifNotNil: [ rigidContainer removeChildren ].
	moveElements := Dictionary new.
	rigidMoveElements := Dictionary new.
	game ifNil: [ ^ self ].
	(game moves ifNil: [ #(  ) ]) doWithIndex: [ :move :idx |
			| elem |
			elem := BlTextElement new.
			elem text: (move san ifNil: [ '' ]) asRopedText.
			elem constraintsDo: [ :c |
					c horizontal fitContent.
					c vertical fitContent ].
			elem margin: (BlInsets all: 4).
			elem padding: (BlInsets all: 2).
			[ elem when: BlClickEvent do: [ :e | self selectMoveAt: idx ] ]
				on: Error
				do: [
						elem
							addEventHandlerOn: BlClickEvent
							do: [ :e | self selectMoveAt: idx ] ].
			compactContainer ifNotNil: [ compactContainer addChild: elem ].
			moveElements at: idx put: elem ].
	self buildRigid.
	self applyLayout.
	self highlightSelected.
	^ self
]

{ #category : 'selection' }
MoveListElement >> selectMoveAt: anIndex [

	selectedMoveIndex := anIndex.
	self highlightSelected.
	announcer announce: (MoveSelectedAnnouncement new
			 moveIndex: anIndex;
			 game: game;
			 yourself).
	^ self
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
