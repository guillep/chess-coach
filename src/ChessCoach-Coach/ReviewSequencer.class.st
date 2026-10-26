"
Identifies positions to review in a game based on heuristics (future: engine analysis gaps, theory deviations). Creates GameReview with selected positions.
"
Class {
	#name : 'ReviewSequencer',
	#superclass : 'Object',
	#instVars : [
		'game'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'creating' }
ReviewSequencer >> createReview [
	"Create a review with all positions (MVP: review every position)"

	| reviewPositions |
	reviewPositions := OrderedCollection new.
	game moves withIndexDo: [ :move :idx |
			| reviewPos |
			reviewPos := ReviewPosition new.
			reviewPos moveNumber: idx board: nil movePlayedSAN: move san.
			reviewPositions add: reviewPos ].
	^ GameReview new game: game positions: reviewPositions
]

{ #category : 'accessing' }
ReviewSequencer >> game [

	^ game
]

{ #category : 'initialization' }
ReviewSequencer >> game: aGame [

	game := aGame
]
