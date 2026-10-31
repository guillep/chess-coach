"
Games to review, those in progress first.
"
Class {
	#name : 'HomeSuggestionsWidget',
	#superclass : 'HomeWidget',
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'types' }
HomeSuggestionsWidget class >> typeName [

	^ 'suggestions'
]

{ #category : 'accessing' }
HomeSuggestionsWidget >> defaultCount [

	^ 1
]

{ #category : 'accessing' }
HomeSuggestionsWidget >> defaultTitle [

	^ 'Do you want to review this game?'
]
