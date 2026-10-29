"
I show every piece of a piece set on two rows of six squares (white pieces, then black), in a board colour theme. Settings uses me to preview the piece set and the colours.
"
Class {
	#name : 'PieceSetPreviewElement',
	#superclass : 'BlElement',
	#instVars : [
		'pieceSet',
		'theme',
		'squares'
	],
	#category : 'ChessCoach-UI-Board',
	#package : 'ChessCoach-UI',
	#tag : 'Board'
}

{ #category : 'initialization' }
PieceSetPreviewElement >> initialize [

	super initialize.
	pieceSet := MeridianPieceSet new.
	squares := (1 to: 12) collect: [ :index |
			           BlElement new
				           layout: BlFrameLayout new;
				           extent: 48 @ 48;
				           yourself ].
	self layout: (BlGridLayout horizontal columnCount: 6).
	self constraintsDo: [ :c |
			c horizontal fitContent.
			c vertical fitContent ].
	self addChildren: squares.
	self theme: 'Brown'.
	self redrawPieces
]

{ #category : 'accessing' }
PieceSetPreviewElement >> pieceSet [

	^ pieceSet
]

{ #category : 'accessing' }
PieceSetPreviewElement >> pieceSet: aPieceSet [

	pieceSet := aPieceSet.
	self redrawPieces
]

{ #category : 'drawing' }
PieceSetPreviewElement >> redrawPieces [
	"King, queen, rook, bishop, knight and pawn: white on the first row, black on the second"

	| kinds |
	kinds := #( #king #queen #rook #bishop #knight #pawn ).
	squares doWithIndex: [ :square :index |
			| form |
			form := Form fromBinaryStream: (ReadStream on: (pieceSet
						          byteArrayForPiece: (kinds at: index - 1 \\ 6 + 1)
						          color: (index <= 6
								           ifTrue: [ #white ]
								           ifFalse: [ #black ]))).
			square
				removeChildren;
				addChild: (BlElement new
						 extent: 48 @ 48;
						 background: (form scaledToSize: 48 @ 48);
						 yourself) ]
]

{ #category : 'accessing' }
PieceSetPreviewElement >> theme [

	^ theme
]

{ #category : 'accessing' }
PieceSetPreviewElement >> theme: aThemeName [
	"The colours of one of the board themes (see ChessBoardElement class>>themes), alternating like a board"

	| themes colors |
	themes := ChessBoardElement themes.
	theme := (themes includesKey: aThemeName)
		         ifTrue: [ aThemeName ]
		         ifFalse: [ 'Brown' ].
	colors := (themes at: theme) collect: [ :hex |
		          Color fromHexString: hex ].
	squares doWithIndex: [ :square :index |
			| row column |
			row := index - 1 // 6.
			column := index - 1 \\ 6.
			square background: ((row + column) even
					 ifTrue: [ colors first ]
					 ifFalse: [ colors second ]) ]
]
