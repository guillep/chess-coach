Class {
	#name : 'ChessPieceSet',
	#superclass : 'Object',
	#category : 'ChessCoach-PieceSets',
	#package : 'ChessCoach-PieceSets'
}

{ #category : 'accessing' }
ChessPieceSet >> byteArrayForPiece: aPiece color: aColor [

	self subclassResponsibility
]

{ #category : 'accessing' }
ChessPieceSet >> default [

	^ MadwareChessPieceSet new
]
