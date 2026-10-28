Class {
	#name : 'ChessPieceSet',
	#superclass : 'Object',
	#category : 'ChessCoach-UI-PieceSets',
	#package : 'ChessCoach-UI',
	#tag : 'PieceSets'
}

{ #category : 'accessing' }
ChessPieceSet >> byteArrayForPiece: aPiece color: aColor [

	self subclassResponsibility
]

{ #category : 'accessing' }
ChessPieceSet >> default [

	^ LiviusPieceSet new
]
