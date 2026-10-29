"
A taxonomy tag attached to a mistake, with the classifier's confidence (0-1) and whether I confirmed it.
"
Class {
	#name : 'MistakeLabel',
	#superclass : 'Object',
	#instVars : [
		'tagId',
		'confidence',
		'confirmed',
		'rejected'
	],
	#category : 'ChessCoach-Core-Mistakes',
	#package : 'ChessCoach-Core',
	#tag : 'Mistakes'
}

{ #category : 'instance creation' }
MistakeLabel class >> fromDictionary: aDictionary [

	| label |
	label := self new
		         setTagId: (aDictionary at: 'tag')
		         confidence: (aDictionary at: 'confidence')
		         confirmed: (aDictionary at: 'confirmed').
	(aDictionary at: 'rejected' ifAbsent: [ false ]) ifTrue: [
		label reject ].
	^ label
]

{ #category : 'instance creation' }
MistakeLabel class >> tagId: anId confidence: aNumber [

	^ self new setTagId: anId confidence: aNumber confirmed: false
]

{ #category : 'converting' }
MistakeLabel >> asDictionary [

	^ Dictionary new
		  at: 'tag' put: tagId;
		  at: 'confidence' put: confidence;
		  at: 'confirmed' put: confirmed;
		  at: 'rejected' put: rejected;
		  yourself
]

{ #category : 'accessing' }
MistakeLabel >> confidence [

	^ confidence
]

{ #category : 'actions' }
MistakeLabel >> confirm [
	"I agree with the tag: it counts as a mistake"

	confirmed := true.
	rejected := false
]

{ #category : 'testing' }
MistakeLabel >> isConfirmed [

	^ confirmed
]

{ #category : 'testing' }
MistakeLabel >> isRejected [

	^ rejected
]

{ #category : 'actions' }
MistakeLabel >> reject [
	"I disagree with the proposed tag: it stays visible but doesn't count"

	confirmed := false.
	rejected := true
]

{ #category : 'initialization' }
MistakeLabel >> setTagId: anId confidence: aNumber confirmed: aBoolean [

	tagId := anId.
	confidence := aNumber.
	confirmed := aBoolean.
	rejected := false
]

{ #category : 'accessing' }
MistakeLabel >> tagId [

	^ tagId
]
