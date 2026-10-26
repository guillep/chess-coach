"
Custom Bloc element that renders an 8x8 chess board with pieces. Handles mouse clicks for piece selection and move input, and highlights legal moves.
"
Class {
	#name : 'ChessBoardElement',
	#superclass : 'BlElement',
	#instVars : [
		'board',
		'selectedSquare',
		'highlightedSquares',
		'squares',
		'pieceElements'
	],
	#category : 'ChessCoach-UI-Bloc',
	#package : 'ChessCoach-UI-Bloc'
}

{ #category : 'accessing' }
ChessBoardElement >> board [

	^ board
]

{ #category : 'accessing' }
ChessBoardElement >> board: aChessBoard [

	board := aChessBoard.
	^ self
]

{ #category : 'accessing' }
ChessBoardElement >> boardState: aDictionary [

	^ self setState: aDictionary
]

{ #category : 'initialization' }
ChessBoardElement >> buildBoard [

	| light dark |
	light := Color fromHexString: '#f0d9b5'.
	dark := Color fromHexString: '#b58863'.
	0 to: 7 do: [ :rank |
			0 to: 7 do: [ :file |
					| square isLight |
					isLight := (file + rank) even.
					square := BlElement new
						          background: (isLight
								           ifTrue: [ light ]
								           ifFalse: [ dark ]);
						          constraintsDo: [ :c |
								          c grid horizontal span: 1.
								          c grid vertical span: 1.
								          c horizontal matchParent.
								          c vertical matchParent ];
						          yourself.
					self addChild: square.
					squares add: square ] ].
	self layout: (BlGridLayout horizontal columnCount: 8).
	^ self
]

{ #category : 'rendering' }
ChessBoardElement >> displayBoard [
	"Render the chess board (8x8 grid with pieces). TODO: Implement rendering with Bloc"

	^ self
]

{ #category : 'accessing' }
ChessBoardElement >> game: aPGNGame [

	| b |
	b := aPGNGame initialBoard.
	self board: b.
	^ self
]

{ #category : 'action' }
ChessBoardElement >> highlightSquares: squareList [

	highlightedSquares := squareList
]

{ #category : 'initialization' }
ChessBoardElement >> initialize [

	super initialize.
	squares := OrderedCollection new.
	pieceElements := Dictionary new.
	self layout: BlGridLayout new.
	self constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ].
	self buildBoard.
	^ self
]

{ #category : 'initialization' }
ChessBoardElement >> initializeWithBoard: aChessBoard [

	board := aChessBoard.
	selectedSquare := nil.
	highlightedSquares := #(  )
]

{ #category : 'accessing' }
ChessBoardElement >> pieceAt: aSquare put: aPiece [

	| state |
	state := Dictionary new.
	pieceElements keysDo: [ :k | state at: k put: (pieceElements at: k) ].
	aPiece
		ifNil: [ state removeKey: aSquare ifAbsent: [ ] ]
		ifNotNil: [ state at: aSquare put: aPiece ].
	^ self setState: state
]

{ #category : 'accessing' }
ChessBoardElement >> pieceElements [

	^ pieceElements
]

{ #category : 'action' }
ChessBoardElement >> selectSquare: squareCoordinates [

	selectedSquare := squareCoordinates
]

{ #category : 'accessing' }
ChessBoardElement >> setBoard: aChessBoard [

	board := aChessBoard.
	^ self
]

{ #category : 'accessing' }
ChessBoardElement >> setState: aDictionary [

	| rankOffset |
	pieceElements valuesDo: [ :e | e removeFromParent ].
	pieceElements := Dictionary new.
	rankOffset := 0.
	0 to: 7 do: [ :rank |
			0 to: 7 do: [ :file |
					| key piece char elem idx |
					key := (Character value: 97 + file) asString
					       , (rank + 1) asString.
					piece := aDictionary at: key ifAbsent: [ nil ].
					piece ifNotNil: [
							char := piece asString.
							elem := BlTextElement new text: (char asRopedText fontSize: 32).
							idx := rank * 8 + file + 1.
							(squares at: idx ifAbsent: [ nil ]) ifNotNil: [ :sq |
									elem constraintsDo: [ :c |
											c frame horizontal alignCenterAt: 0.5.
											c frame vertical alignCenterAt: 0.5 ].
									sq addChild: elem ].
							pieceElements at: key put: elem ] ] ].
	^ self
]

{ #category : 'accessing' }
ChessBoardElement >> state: aDictionary [

	^ self setState: aDictionary
]
