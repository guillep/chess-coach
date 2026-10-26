"
Represents a Socratic review session for a game. Maintains a sequence of ReviewPosition objects and tracks progress through the review.
"
Class {
	#name : 'GameReview',
	#superclass : 'Object',
	#instVars : [
		'game',
		'positions',
		'currentStep'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'accessing' }
GameReview >> currentPosition [

	(currentStep < 1 or: [ currentStep > positions size ]) ifTrue: [
		^ nil ].
	^ positions at: currentStep
]

{ #category : 'accessing' }
GameReview >> currentStep [

	^ currentStep
]

{ #category : 'accessing' }
GameReview >> game [

	^ game
]

{ #category : 'initialization' }
GameReview >> game: aGame positions: aPositionList [

	game := aGame.
	positions := aPositionList asOrderedCollection.
	currentStep := 0
]

{ #category : 'navigation' }
GameReview >> nextPosition [

	currentStep < positions size ifTrue: [
		currentStep := currentStep + 1 ].
	^ self currentPosition
]

{ #category : 'accessing' }
GameReview >> positions [

	^ positions
]

{ #category : 'navigation' }
GameReview >> previousPosition [

	currentStep > 1 ifTrue: [ currentStep := currentStep - 1 ].
	^ self currentPosition
]
