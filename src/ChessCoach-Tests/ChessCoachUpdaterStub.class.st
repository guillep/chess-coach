"
I replace the updater's git and image steps with data, and log them.
"
Class {
	#name : 'ChessCoachUpdaterStub',
	#superclass : 'ChessCoachUpdater',
	#instVars : [
		'current',
		'tags',
		'log',
		'failure'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'private - io' }
ChessCoachUpdaterStub >> checkOut: aTagName [

	failure ifNotNil: [ self error: failure ].
	log add: aTagName
]

{ #category : 'accessing' }
ChessCoachUpdaterStub >> current: aTag tags: someTags failure: anErrorMessageOrNil [

	current := aTag.
	tags := someTags.
	failure := anErrorMessageOrNil.
	log := OrderedCollection new
]

{ #category : 'private - io' }
ChessCoachUpdaterStub >> currentTag [

	^ current
]

{ #category : 'accessing' }
ChessCoachUpdaterStub >> log [

	^ log
]

{ #category : 'private - io' }
ChessCoachUpdaterStub >> releaseTags [

	^ tags
]

{ #category : 'private - io' }
ChessCoachUpdaterStub >> saveImage [

	log add: #saved
]
