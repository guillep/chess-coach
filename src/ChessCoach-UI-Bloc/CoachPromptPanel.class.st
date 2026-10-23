"
Displays Socratic coach prompts and user input fields. Shows unaided recall prompt, move revelation, and reflection questions.
"
Class {
	#name : 'CoachPromptPanel',
	#superclass : 'Object',
	#instVars : [
		'review',
		'currentPosition'
	],
	#category : 'ChessCoach-UI-Bloc',
	#package : 'ChessCoach-UI-Bloc'
}

{ #category : 'accessing' }
CoachPromptPanel >> currentPosition [

	^ currentPosition
]

{ #category : 'displaying' }
CoachPromptPanel >> displayPosition: aReviewPosition [

	currentPosition := aReviewPosition
	"TODO: Update UI with coach prompt"
]

{ #category : 'initialization' }
CoachPromptPanel >> initializeWithReview: aGameReview [

	review := aGameReview.
	currentPosition := nil
]

{ #category : 'accessing' }
CoachPromptPanel >> review [

	^ review
]
