"
Represents a single position being reviewed in a game. Tracks the board state, the move played, and the user's unaided recall and subsequent thinking.
"
Class {
	#name : 'ReviewPosition',
	#superclass : 'Object',
	#instVars : [
		'moveNumber',
		'board',
		'movePlayedSAN',
		'userRecall',
		'userThinking'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'accessing' }
ReviewPosition >> board [

	^ board
]

{ #category : 'accessing' }
ReviewPosition >> moveNumber [

	^ moveNumber
]

{ #category : 'initialization' }
ReviewPosition >> moveNumber: aNumber board: aBoard movePlayedSAN: aSAN [

	moveNumber := aNumber.
	board := aBoard.
	movePlayedSAN := aSAN.
	userRecall := nil.
	userThinking := nil
]

{ #category : 'accessing' }
ReviewPosition >> movePlayedSAN [

	^ movePlayedSAN
]

{ #category : 'accessing' }
ReviewPosition >> userRecall [

	^ userRecall
]

{ #category : 'setting' }
ReviewPosition >> userRecall: aString [

	userRecall := aString
]

{ #category : 'accessing' }
ReviewPosition >> userThinking [

	^ userThinking
]

{ #category : 'setting' }
ReviewPosition >> userThinking: aString [

	userThinking := aString
]
