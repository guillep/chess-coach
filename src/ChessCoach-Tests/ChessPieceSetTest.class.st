Class {
	#name : 'ChessPieceSetTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
ChessPieceSetTest >> testEveryPieceHasItsOwnImage [

	ChessPieceSet allSubclasses do: [ :setClass |
			| set images |
			set := setClass new.
			images := Dictionary new.
			#( #white #black ) do: [ :color |
					#( #king #queen #rook #bishop #knight #pawn ) do: [ :piece |
							| bytes |
							bytes := set byteArrayForPiece: piece color: color.
							images
								at: bytes
								ifPresent: [ :other |
										self fail:
											setClass name , ': ' , color , ' ' , piece
											, ' has the same image as ' , other ]
								ifAbsent: [ images at: bytes put: color , ' ' , piece ] ] ] ]
]
