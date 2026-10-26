Class {
	#name : 'PGNGame',
	#superclass : 'Object',
	#instVars : [
		'metadata',
		'moves'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'accessing' }
PGNGame >> initialBoard [

	^ ChessBoard new
]

{ #category : 'initialization' }
PGNGame >> initialize [

	super initialize.
	metadata := Dictionary new.
	moves := OrderedCollection new.
	^ self
]

{ #category : 'accessing' }
PGNGame >> metadata [

	^ metadata
]

{ #category : 'initialization' }
PGNGame >> metadata: aDictionary moves: aCollection [

	metadata := aDictionary.
	moves := aCollection.
	^ self
]

{ #category : 'accessing' }
PGNGame >> moves [

	^ moves
]
