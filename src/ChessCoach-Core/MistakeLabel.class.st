"
A taxonomy tag attached to a mistake, with the classifier's confidence (0-1) and whether I confirmed it.
"
Class {
	#name : 'MistakeLabel',
	#superclass : 'Object',
	#instVars : [
		'tagId',
		'confidence',
		'confirmed'
	],
	#category : 'ChessCoach-Core-Mistakes',
	#package : 'ChessCoach-Core',
	#tag : 'Mistakes'
}

{ #category : 'instance creation' }
MistakeLabel class >> fromDictionary: aDictionary [

	^ self new
		  setTagId: (aDictionary at: 'tag')
		  confidence: (aDictionary at: 'confidence')
		  confirmed: (aDictionary at: 'confirmed')
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
		  yourself
]

{ #category : 'accessing' }
MistakeLabel >> confidence [

	^ confidence
]

{ #category : 'actions' }
MistakeLabel >> confirm [

	confirmed := true
]

{ #category : 'testing' }
MistakeLabel >> isConfirmed [

	^ confirmed
]

{ #category : 'initialization' }
MistakeLabel >> setTagId: anId confidence: aNumber confirmed: aBoolean [

	tagId := anId.
	confidence := aNumber.
	confirmed := aBoolean
]

{ #category : 'accessing' }
MistakeLabel >> tagId [

	^ tagId
]
