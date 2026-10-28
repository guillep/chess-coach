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
		'chessPosition'
	],
	#category : 'ChessCoach-UI-Board',
	#package : 'ChessCoach-UI',
	#tag : 'Board'
}

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
					self addChild: square.
					squares add: square ] ]
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
	self buildBoard
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

{ #category : 'private' }
ChessBoardElement >> squareIndexOf: aSquare [
	"squares are laid out rank 8 to rank 1, file a to file h"

	^ 8 - aSquare second digitValue * 8 + (aSquare first asInteger - 96)
]
