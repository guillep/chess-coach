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

{ #category : 'constants' }
MistakeLabel class >> minimumConfidence [
	"Below it, a proposed tag is only a 'maybe': it counts once I confirm it"

	^ 0.7
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
MistakeLabel >> isCounted [
	"Counts as my mistake: confirmed, or proposed with enough confidence and not rejected"

	confirmed ifTrue: [ ^ true ].
	^ rejected not and: [ confidence >= self class minimumConfidence ]
]

{ #category : 'testing' }
MistakeLabel >> isRejected [

	^ rejected
]

{ #category : 'testing' }
MistakeLabel >> isTentative [
	"Proposed with too little confidence to count unless I confirm it"

	^ confirmed not and: [
		  rejected not and: [ confidence < self class minimumConfidence ] ]
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
