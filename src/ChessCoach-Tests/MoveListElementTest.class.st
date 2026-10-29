Class {
	#name : 'MoveListElementTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
MoveListElementTest >> testArrowKeysNavigate [

	| list scripter |
	list := MoveListElement new.
	list game: (PGNParser new parse: '1. e4 e5 2. Nf3').
	scripter := BlDevScripter new.
	scripter element: list.
	scripter requestFocus.
	scripter keyClick: KeyboardKey right.
	scripter keyClick: KeyboardKey right.
	scripter keyClick: KeyboardKey left.
	scripter syncPlay.
	self assert: list selectedMoveIndex equals: 1
]

{ #category : 'tests' }
MoveListElementTest >> testClickingAMoveEnablesArrowKeys [
	"The numbered grid shows the number first, then White's move"

	| list scripter |
	list := MoveListElement new.
	list game: (PGNParser new parse: '1. e4 e5 2. Nf3').
	scripter := BlDevScripter new.
	scripter element: list.
	scripter testClick onChildFromBlock: [ :element |
		(element childAt: 3) childAt: 2 ].
	scripter keyClick: KeyboardKey right.
	scripter syncPlay.
	self assert: list selectedMoveIndex equals: 2
]

{ #category : 'tests' }
MoveListElementTest >> testNewGameStartsAtPlyZero [

	| list |
	list := MoveListElement new.
	list game: (PGNParser new parse: '1. e4 e5').
	list selectMoveAt: 2.
	list game: (PGNParser new parse: '1. d4').
	self assert: list selectedMoveIndex equals: 0
]

{ #category : 'tests' }
MoveListElementTest >> testNextAndPreviousStayWithinTheGame [

	| list plies |
	list := MoveListElement new.
	list game: (PGNParser new parse: '1. e4 e5').
	plies := OrderedCollection new.
	list whenMoveSelectedDo: [ :ply | plies add: ply ].
	3 timesRepeat: [ list selectNextMove ].
	3 timesRepeat: [ list selectPreviousMove ].
	self assert: plies asArray equals: #( 1 2 2 1 0 0 ).
	self assert: list selectedMoveIndex equals: 0
]
