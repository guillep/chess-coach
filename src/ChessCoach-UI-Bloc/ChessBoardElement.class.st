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
		'pieceElements',
		'pieceSet',
		'currentState'
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
	self layout: (BlGridLayout horizontal columnCount: 8).
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
								          c horizontal exact: 50.
								          c vertical exact: 50 ];
						          yourself.
					square layout: BlFrameLayout new.
					self addChild: square.
					squares add: square ] ].
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
	currentState := Dictionary new.
	pieceSet := MeridianPieceSet new.
	self layout: (BlGridLayout horizontal columnCount: 8).
	self constraintsDo: [ :c |
			c horizontal exact: 400.
			c vertical exact: 400 ].
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
	currentState ifNil: [ ^ self ].
	0 to: 7 do: [ :rank |
			0 to: 7 do: [ :file |
					| key pieceSymbol sym color ptype bytes elem idx sq image |
					key := (Character value: 97 + file) asString
					       , (rank + 1) asString.
					pieceSymbol := currentState at: key ifAbsent: [ nil ].
					(pieceSymbol isKindOf: String) ifTrue: [
							sym := pieceSymbol asString.
							sym ifNotEmpty: [
									color := sym first isUppercase
										         ifTrue: [ #white ]
										         ifFalse: [ #black ].
									sym := sym asLowercase first asString.
									(self supported: sym) ifTrue: [
											ptype := self pieceTypeFor: sym.
											pieceSet ifNotNil: [
													bytes := pieceSet byteArrayForPiece: ptype color: color.
													bytes ifNotNil: [
															[
																image := (Form fromBinaryStream: (ReadStream on: bytes)) scaledToSize: 48@48.
																elem := BlElement new.
																elem background: (BlFormSetBackground image: image).
																elem extent: 200@200.
																idx := rank * 8 + file + 1.
																sq := squares at: idx ifAbsent: [ nil ].
																sq notNil ifTrue: [
																		elem constraintsDo: [ :c |
																				c horizontal exact: 48.
																				c vertical exact: 48 ].
																		elem constraintsDo: [ :c |
																				c frame horizontal alignCenterAt: 0.5.
																				c frame vertical alignCenterAt: 0.5 ].
																		sq addChild: elem ].
																pieceElements at: key put: elem ]
																on: Error
																do: [ ] ] ] ] ] ] ] ].
	^ self
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

	currentState := aDictionary copy.
	self redrawPieces.
	^ self
]

{ #category : 'accessing' }
ChessBoardElement >> state: aDictionary [

	^ self setState: aDictionary
]

{ #category : 'private' }
ChessBoardElement >> supported: sym [

	sym = 'p' ifTrue: [ ^ true ].
	sym = 'r' ifTrue: [ ^ true ].
	sym = 'n' ifTrue: [ ^ true ].
	sym = 'b' ifTrue: [ ^ true ].
	sym = 'q' ifTrue: [ ^ true ].
	sym = 'k' ifTrue: [ ^ true ].
	^ false
]
