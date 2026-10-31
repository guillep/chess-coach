"
Chosen numbers about the games.
"
Class {
	#name : 'HomeNumbersWidget',
	#superclass : 'HomeWidget',
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'types' }
HomeNumbersWidget class >> typeName [

	^ 'numbers'
]

{ #category : 'accessing' }
HomeNumbersWidget >> defaultTitle [

	^ 'Your numbers'
]

{ #category : 'accessing' }
HomeNumbersWidget >> shownNumbers [

	^ self
		  option: 'numbers'
		  ifAbsent: [ #( 'games' 'reviewed' 'mistake' ) ]
]
