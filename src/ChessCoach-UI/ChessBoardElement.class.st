"
Custom Bloc element that renders an 8x8 chess board with pieces. Handles mouse clicks for piece selection and move input, and highlights legal moves.
"
Class {
	#name : 'ChessBoardElement',
	#superclass : 'BlElement',
	#instVars : [
		'squares',
		'pieceElements',
		'pieceSet',
		'chessPosition',
		'orientation',
		'arrows',
		'arrowLayer',
		'pressedSquare',
		'selectedSquare',
		'moveBlock'
	],
	#category : 'ChessCoach-UI-Board',
	#package : 'ChessCoach-UI',
	#tag : 'Board'
}

{ #category : 'accessing' }
ChessBoardElement >> arrows [

	^ arrows
]

{ #category : 'accessing' }
ChessBoardElement >> arrows: someChessArrows [

	arrows := someChessArrows asArray.
	self redrawArrows
]

{ #category : 'initialization' }
ChessBoardElement >> buildArrowLayer [
	"Arrows are drawn above the squares and pieces and never take mouse events. A resize redraws them after the layout pass, since changing elements during it breaks the layout."

	arrowLayer := BlElement new
		              constraintsDo: [ :c | c ignoreByLayout ];
		              preventMeAndChildrenMouseEvents;
		              yourself.
	self addChild: arrowLayer.
	self addEventHandlerOn: BlElementExtentChangedEvent do: [ :event |
		self enqueueTask: (BlTaskAction new action: [ self redrawArrows ]) ]
]

{ #category : 'initialization' }
ChessBoardElement >> buildBoard [

	| light dark |
	light := Color fromHexString: '#f0d9b5'.
	dark := Color fromHexString: '#b58863'.
	self layout:
		(BlSquaredLayout on: (BlGridLayout horizontal columnCount: 8))
			beTight.
	0 to: 7 do: [ :displayRank |
			0 to: 7 do: [ :file |
					| square isLight rank |
					rank := 7 - displayRank.
					isLight := (file + rank) even.
					square := BlElement new
						          layout: BlFrameLayout new;
						          background: (isLight
								           ifTrue: [ light ]
								           ifFalse: [ dark ]);
						          constraintsDo: [ :c |
								          c horizontal matchParent.
								          c vertical matchParent ];
						          yourself.
					square
						addEventHandlerOn: BlMouseDownEvent
						do: [ :event | self pressedOn: (self squareNameOf: square) ].
					square
						addEventHandlerOn: BlMouseUpEvent
						do: [ :event | self releasedOn: (self squareNameOf: square) ].
					self addChild: square.
					squares add: square ] ]
]

{ #category : 'drawing' }
ChessBoardElement >> centerOf: aSquare [

	| index size |
	index := self squareIndexOf: aSquare.
	size := self width / 8.
	^ index - 1 \\ 8 + 0.5 * size @ (index - 1 // 8 + 0.5 * size)
]

{ #category : 'accessing' }
ChessBoardElement >> chessPosition [

	^ chessPosition
]

{ #category : 'accessing' }
ChessBoardElement >> chessPosition: aChessPosition [
	"Not named position: because BlElement>>position is the element's location in its parent"

	chessPosition := aChessPosition.
	self redrawPieces
]

{ #category : 'initialization' }
ChessBoardElement >> initialize [

	super initialize.
	squares := OrderedCollection new.
	pieceElements := Dictionary new.
	chessPosition := ChessPosition new.
	pieceSet := MeridianPieceSet new.
	orientation := #white.
	arrows := #(  ).
	moveBlock := [ :uci |  ].
	self buildBoard.
	self buildArrowLayer
]

{ #category : 'input' }
ChessBoardElement >> mark: fromSquare to: toSquare [

	| piece promotion |
	piece := chessPosition pieceAt: fromSquare.
	promotion := (piece notNil and: [
		              piece asUppercase = 'P' and: [
			              '18' includes: toSquare second ] ])
		             ifTrue: [ 'q' ]
		             ifFalse: [ '' ].
	moveBlock value: fromSquare , toSquare , promotion
]

{ #category : 'accessing' }
ChessBoardElement >> orientation [

	^ orientation
]

{ #category : 'accessing' }
ChessBoardElement >> orientation: aColor [
	"Show the board from aColor's side (#white or #black)"

	orientation := aColor.
	self redrawPieces.
	self redrawArrows
]

{ #category : 'private' }
ChessBoardElement >> pieceElementFor: aForm [
	"Answer an element that fills its square and redraws aForm at the square's size whenever it is resized"

	| elem |
	elem := BlElement new.
	elem constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical matchParent ].
	elem addEventHandlerOn: BlElementExtentChangedEvent do: [ :evt |
			(elem width > 0 and: [ elem height > 0 ]) ifTrue: [
				elem background: (aForm scaledToSize: elem extent) ] ].
	^ elem
]

{ #category : 'accessing' }
ChessBoardElement >> pieceElements [

	^ pieceElements
]

{ #category : 'accessing' }
ChessBoardElement >> pieceSet [

	^ pieceSet
]

{ #category : 'accessing' }
ChessBoardElement >> pieceSet: aPieceSet [

	pieceSet := aPieceSet.
	self redrawPieces.
	^ self
]

{ #category : 'private' }
ChessBoardElement >> pieceTypeFor: sym [

	sym = 'p' ifTrue: [ ^ #pawn ].
	sym = 'r' ifTrue: [ ^ #rook ].
	sym = 'n' ifTrue: [ ^ #knight ].
	sym = 'b' ifTrue: [ ^ #bishop ].
	sym = 'q' ifTrue: [ ^ #queen ].
	sym = 'k' ifTrue: [ ^ #king ].
	^ #pawn
]

{ #category : 'input' }
ChessBoardElement >> pressedOn: aSquare [

	pressedSquare := aSquare
]

{ #category : 'drawing' }
ChessBoardElement >> redrawArrows [

	| size |
	arrowLayer removeChildren.
	arrowLayer extent: self extent.
	size := self width / 8.
	size > 0 ifFalse: [ ^ self ].
	arrows do: [ :arrow |
			| element |
			element := BlElement new
				           extent: self extent;
				           geometry: (BlPolygonGeometry vertices: (arrow
								             verticesFrom: (self centerOf: arrow from)
								             to: (self centerOf: arrow to)
								             squareSize: size));
				           background: arrow color;
				           yourself.
			arrow style = #subject ifTrue: [
					element border: (BlBorder builder
							 paint: (arrow color alpha: 0.9);
							 width: 2;
							 dashArray: #( 6 4 );
							 build) ].
			arrowLayer addChild: element ]
]

{ #category : 'initialization' }
ChessBoardElement >> redrawPieces [

	pieceElements valuesDo: [ :e | e removeFromParent ].
	pieceElements := Dictionary new.
	chessPosition pieces keysAndValuesDo: [ :square :piece |
			| element |
			element := self pieceElementFor:
				           (Form fromBinaryStream: (ReadStream on: (pieceSet
							              byteArrayForPiece:
							              (self pieceTypeFor: piece asLowercase)
							              color: (piece first isUppercase
									               ifTrue: [ #white ]
									               ifFalse: [ #black ])))).
			(squares at: (self squareIndexOf: square)) addChild: element.
			pieceElements at: square put: element ]
]

{ #category : 'input' }
ChessBoardElement >> releasedOn: aSquare [
	"A drag ends on another square; a click either selects the origin or completes a click-click move"

	| pressed |
	pressed := pressedSquare.
	pressedSquare := nil.
	pressed ifNil: [ ^ self ].
	pressed ~= aSquare ifTrue: [
			selectedSquare := nil.
			^ self mark: pressed to: aSquare ].
	(selectedSquare isNil or: [ selectedSquare = aSquare ]) ifTrue: [
			selectedSquare := selectedSquare isNil
				                  ifTrue: [ aSquare ]
				                  ifFalse: [ nil ].
			^ self ].
	pressed := selectedSquare.
	selectedSquare := nil.
	self mark: pressed to: aSquare
]

{ #category : 'accessing' }
ChessBoardElement >> selectedSquare [
	"The origin chosen by a first click, waiting for the target click; nil when none"

	^ selectedSquare
]

{ #category : 'accessing' }
ChessBoardElement >> squareElementAt: aSquare [
	"The element showing aSquare (e.g. 'e4')"

	^ squares at: (self squareIndexOf: aSquare)
]

{ #category : 'private' }
ChessBoardElement >> squareIndexOf: aSquare [
	"squares are laid out top-left to bottom-right as seen from orientation's side"

	| file rank |
	file := aSquare first asInteger - 96.
	rank := aSquare second digitValue.
	^ orientation = #white
		  ifTrue: [ 8 - rank * 8 + file ]
		  ifFalse: [ rank - 1 * 8 + (9 - file) ]
]

{ #category : 'private' }
ChessBoardElement >> squareNameAt: anIndex [
	"The square (e.g. 'e4') shown at anIndex, the inverse of squareIndexOf:"

	| row column file rank |
	row := anIndex - 1 // 8.
	column := anIndex - 1 \\ 8.
	orientation = #white
		ifTrue: [
				file := column + 1.
				rank := 8 - row ]
		ifFalse: [
				file := 8 - column.
				rank := row + 1 ].
	^ (Character value: 96 + file) asString , rank printString
]

{ #category : 'private' }
ChessBoardElement >> squareNameOf: aSquareElement [

	^ self squareNameAt: (squares indexOf: aSquareElement)
]

{ #category : 'input' }
ChessBoardElement >> whenMoveMarkedDo: aBlock [
	"aBlock receives the UCI of each move I mark, by dragging or by clicking the origin then the target square. Pawns reaching the last rank promote to a queen."

	moveBlock := aBlock
]
