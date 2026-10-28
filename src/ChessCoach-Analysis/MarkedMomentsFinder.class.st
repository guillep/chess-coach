"
I turn the moments the user marked (dictionaries with 'ply' and 'note') into ChessMoments of kind #marked.
"
Class {
	#name : 'MarkedMomentsFinder',
	#superclass : 'Object',
	#instVars : [
		'game',
		'marks'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
MarkedMomentsFinder class >> game: aGame marks: aCollection [

	^ self new
		  setGame: aGame marks: aCollection;
		  yourself
]

{ #category : 'finding' }
MarkedMomentsFinder >> moments [

	^ marks collect: [ :mark |
			  | ply |
			  ply := mark at: 'ply'.
			  ChessMoment
				  ply: ply
				  color: (game positionAfterPly: ply - 1) turn
				  kind: #marked
				  source: #marks
				  note: (mark at: 'note' ifAbsent: [ nil ]) ]
]

{ #category : 'initialization' }
MarkedMomentsFinder >> setGame: aGame marks: aCollection [

	game := aGame.
	marks := aCollection
]
