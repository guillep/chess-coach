Class {
	#name : 'ChessIllegalMove',
	#superclass : 'Error',
	#instVars : [
		'san',
		'position'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'signalling' }
ChessIllegalMove class >> signalSAN: aString position: aChessPosition [

	^ self new
		  san: aString position: aChessPosition;
		  signal
]

{ #category : 'accessing' }
ChessIllegalMove >> messageText [

	^ 'Cannot play ' , san printString , ' in ' , position fen
]

{ #category : 'accessing' }
ChessIllegalMove >> position [

	^ position
]

{ #category : 'accessing' }
ChessIllegalMove >> san [

	^ san
]

{ #category : 'initialization' }
ChessIllegalMove >> san: aString position: aChessPosition [

	san := aString.
	position := aChessPosition
]
