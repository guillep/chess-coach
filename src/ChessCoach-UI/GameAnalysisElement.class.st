Class {
	#name : 'GameAnalysisElement',
	#superclass : 'BlElement',
	#instVars : [
		'game',
		'boardElement',
		'moveList'
	],
	#category : 'ChessCoach-UI-Board',
	#package : 'ChessCoach-UI',
	#tag : 'Board'
}

{ #category : 'examples' }
GameAnalysisElement class >> example [
	"Morphy's Opera Game, Paris 1858"

	| analysis space |
	analysis := self fromPGN: '[Event "Paris Opera"]
[White "Paul Morphy"]
[Black "Duke Karl / Count Isouard"]
[Result "1-0"]

1. e4 e5 2. Nf3 d6 3. d4 Bg4 4. dxe5 Bxf3 5. Qxf3 dxe5 6. Bc4 Nf6 7. Qb3 Qe7
8. Nc3 c6 9. Bg5 b5 10. Nxb5 cxb5 11. Bxb5+ Nbd7 12. O-O-O Rd8 13. Rxd7 Rxd7
14. Rd1 Qe6 15. Bxd7+ Nxd7 16. Qb8+ Nxb8 17. Rd8# 1-0'.
	space := BlSpace new.
	space extent: 900 @ 640.
	space root addChild: analysis.
	space show.
	^ analysis
]

{ #category : 'instance creation' }
GameAnalysisElement class >> fromPGN: aString [

	^ self new game: (PGNParser new parse: aString)
]

{ #category : 'accessing' }
GameAnalysisElement >> boardElement [

	^ boardElement
]

{ #category : 'accessing' }
GameAnalysisElement >> chessPosition [
	"The position currently shown on the board"

	^ boardElement chessPosition
]

{ #category : 'accessing' }
GameAnalysisElement >> game [

	^ game
]

{ #category : 'accessing' }
GameAnalysisElement >> game: aGame [
	"Show aGame from its initial position (ply 0)"

	game := aGame.
	moveList game: aGame.
	self showPly: 0
]

{ #category : 'initialization' }
GameAnalysisElement >> initialize [

	super initialize.
	self layout: BlLinearLayout horizontal.
	self constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ].
	boardElement := ChessBoardElement new.
	boardElement constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ].
	moveList := MoveListElement new.
	moveList constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ].
	moveList whenMoveSelectedDo: [ :ply | self showPly: ply ].
	self addChild: boardElement.
	self addChild: (ToElement new
			 layout: BlFrameLayout new;
			 width: 200;
			 vMatchParent;
			 addChild: (ChessCoachWidgets scrollable: moveList);
			 yourself).
	"Bloc defers the request until the element is added to a space, so arrow keys work as soon as the view opens"
	moveList requestFocus
]

{ #category : 'accessing' }
GameAnalysisElement >> moveList [

	^ moveList
]

{ #category : 'selection' }
GameAnalysisElement >> selectPly: aNumber [
	"Select the Nth half-move in the move list, as a click would"

	moveList selectMoveAt: aNumber
]

{ #category : 'private' }
GameAnalysisElement >> showPly: aNumber [

	boardElement chessPosition: (game positionAfterPly: aNumber)
]
