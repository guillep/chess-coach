Class {
	#name : 'ChessPieceSet',
	#superclass : 'Object',
	#category : 'ChessCoach-UI-PieceSets',
	#package : 'ChessCoach-UI',
	#tag : 'PieceSets'
}

{ #category : 'accessing' }
ChessPieceSet class >> byName [
	"The piece sets offered in the settings, by the name stored there"

	^ OrderedDictionary new
		  at: 'Meridian' put: MeridianPieceSet;
		  at: 'Meridian shaded' put: MeridianShadedPieceSet;
		  at: 'Livius' put: LiviusPieceSet;
		  at: 'Madware' put: MadwareChessPieceSet;
		  yourself
]

{ #category : 'accessing' }
ChessPieceSet class >> named: aName [

	^ (self byName at: aName) new
]

{ #category : 'accessing' }
ChessPieceSet >> byteArrayForPiece: aPiece color: aColor [

	self subclassResponsibility
]

{ #category : 'accessing' }
ChessPieceSet >> default [

	^ LiviusPieceSet new
]
