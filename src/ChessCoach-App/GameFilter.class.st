"
Which games to show: optional criteria that combine. Keys are result (won, lost, draw), color (white, black), speed, source, days and review (reviewed, unreviewed). It is plain data, saved in home.json.
"
Class {
	#name : 'GameFilter',
	#superclass : 'Object',
	#instVars : [
		'criteria'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'instance creation' }
GameFilter class >> fromDictionary: aDictionary [

	| filter |
	filter := self new.
	aDictionary keysAndValuesDo: [ :key :value |
		filter at: key put: value ].
	^ filter
]

{ #category : 'accessing' }
GameFilter >> at: aKey [

	^ criteria at: aKey ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GameFilter >> at: aKey put: aValueOrNil [
	"Set a criterion; nil removes it"

	aValueOrNil
		ifNil: [ criteria removeKey: aKey ifAbsent: [ ] ]
		ifNotNil: [ criteria at: aKey put: aValueOrNil ]
]

{ #category : 'accessing' }
GameFilter >> criteria [
	"A copy of my criteria, key to value, to save"

	^ criteria copy
]

{ #category : 'initialization' }
GameFilter >> initialize [

	super initialize.
	criteria := Dictionary new
]
