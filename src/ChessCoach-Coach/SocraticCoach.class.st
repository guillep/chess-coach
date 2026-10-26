"
Provides Socratic coaching prompts and explanations. Guides the user through unaided recall, move revelation, and reflective thinking about positions.
"
Class {
	#name : 'SocraticCoach',
	#superclass : 'Object',
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'prompting' }
SocraticCoach >> promptForCurrentThinking: aReviewPosition [

	^ 'Now that you see the board, what do you think about this move?'
]

{ #category : 'prompting' }
SocraticCoach >> promptForRecall: aReviewPosition [

	^ 'What was your thinking on move '
	  , aReviewPosition moveNumber asString , '?'
]

{ #category : 'revealing' }
SocraticCoach >> revealMove: aReviewPosition [

	^ 'You played: ' , aReviewPosition movePlayedSAN
]
