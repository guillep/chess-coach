"
I replace the updater's git and image steps with data, and log them.
"
Class {
	#name : 'MMUpdaterStub',
	#superclass : 'MMUpdater',
	#instVars : [
		'current',
		'tags',
		'log',
		'failure'
	],
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'private - io' }
MMUpdaterStub >> checkOut: aTagName [

	failure ifNotNil: [ self error: failure ].
	log add: aTagName
]

{ #category : 'accessing' }
MMUpdaterStub >> current: aTag tags: someTags failure: anErrorMessageOrNil [

	current := aTag.
	tags := someTags.
	failure := anErrorMessageOrNil.
	log := OrderedCollection new
]

{ #category : 'private - io' }
MMUpdaterStub >> currentTag [

	^ current
]

{ #category : 'private - io' }
MMUpdaterStub >> loadBaseline [

	log add: #baseline
]

{ #category : 'accessing' }
MMUpdaterStub >> log [

	^ log
]

{ #category : 'private - io' }
MMUpdaterStub >> releaseTags [

	^ tags
]

{ #category : 'private - io' }
MMUpdaterStub >> saveImage [

	log add: #saved
]
