"
Move input, orientation and arrows of ChessBoardElement, driven through BlDevScripter.
"
Class {
	#name : 'ChessBoardInteractionTest',
	#superclass : 'TestCase',
	#instVars : [
		'board',
		'scripter',
		'marked'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
ChessBoardInteractionTest >> clickOn: aSquare [

	scripter testClick onChildFromBlock: [ :root |
		board squareElementAt: aSquare ].
	scripter syncContinue.
	scripter pulse
]

{ #category : 'running' }
ChessBoardInteractionTest >> setUp [

	super setUp.
	marked := OrderedCollection new.
	board := ChessBoardElement new.
	board chessPosition: ChessPosition initial.
	board whenMoveMarkedDo: [ :uci | marked add: uci ].
	scripter := BlDevScripter new.
	scripter element: board.
	scripter space extent: 400 @ 400.
	scripter pulse
]

{ #category : 'tests' }
ChessBoardInteractionTest >> testArrowsAreDrawnAboveTheBoardWithoutBlockingInput [

	| layerChildren |
	board arrows: {
			(ChessArrow uci: 'e2e4' style: #played).
			(ChessArrow uci: 'g1f3' style: #subject) }.
	scripter pulse.
	self
		assert: (board arrows collect: [ :each | each uci ]) asArray
		equals: #( 'e2e4' 'g1f3' ).
	layerChildren := board children last children.
	self assert: layerChildren size equals: 2.
	self
		assert: (layerChildren first geometry vertices at: 4)
		equals: (board centerOf: 'e4') asFloatPoint.
	self clickOn: 'e2'.
	self assert: board selectedSquare equals: 'e2'
]

{ #category : 'tests' }
ChessBoardInteractionTest >> testClickClickMarksAMove [

	self clickOn: 'g1'.
	self assert: board selectedSquare equals: 'g1'.
	self clickOn: 'f3'.
	self assert: marked asArray equals: #( 'g1f3' ).
	self assert: board selectedSquare isNil.
	self clickOn: 'e2'.
	self clickOn: 'e2'.
	self assert: board selectedSquare isNil.
	self assert: marked size equals: 1
]

{ #category : 'tests' }
ChessBoardInteractionTest >> testCoordinatesFollowTheOrientation [

	| fresh |
	fresh := ChessBoardElement new.
	self
		assert: fresh coordinateTexts asArray
		equals:
		#( '8' '7' '6' '5' '4' '3' '2' '1' 'a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' ).
	fresh orientation: #black.
	self
		assert: fresh coordinateTexts asArray
		equals:
		#( '1' '2' '3' '4' '5' '6' '7' '8' 'h' 'g' 'f' 'e' 'd' 'c' 'b' 'a' )
]

{ #category : 'tests' }
ChessBoardInteractionTest >> testDragMarksAMove [

	scripter mouseMoveOver onChildFromBlock: [ :root |
		board squareElementAt: 'e2' ].
	scripter mouseDown.
	scripter mouseMoveOver onChildFromBlock: [ :root |
		board squareElementAt: 'e4' ].
	scripter mouseUp.
	scripter syncContinue.
	self assert: marked asArray equals: #( 'e2e4' ).
	self assert: (board chessPosition pieceAt: 'e2') equals: 'P'
]

{ #category : 'tests' }
ChessBoardInteractionTest >> testOrientationAndPromotion [

	board orientation: #black.
	scripter pulse.
	self
		assert: (board squareElementAt: 'h1') bounds inSpace bounds origin
		equals: 0 @ 0.
	self assert: ((board squareElementAt: 'e2') children includes:
			 (board pieceElements at: 'e2')).
	board chessPosition:
		(ChessPosition fromFEN: '4k3/P7/8/8/8/8/8/4K3 w - - 0 1').
	self clickOn: 'a7'.
	self clickOn: 'a8'.
	self assert: marked asArray equals: #( 'a7a8q' )
]
