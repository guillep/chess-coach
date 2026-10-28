"
One entry of the mistake taxonomy: a stable id (used in JSON and by the classifier), its category (perception, calculation, evaluation, decision, knowledge) and a description for the user and the LLM prompt.
"
Class {
	#name : 'MistakeTag',
	#superclass : 'Object',
	#instVars : [
		'id',
		'category',
		'description'
	],
	#category : 'ChessCoach-Core-Mistakes',
	#package : 'ChessCoach-Core',
	#tag : 'Mistakes'
}

{ #category : 'instance creation' }
MistakeTag class >> id: anId category: aCategory description: aString [

	^ self new setId: anId category: aCategory description: aString
]

{ #category : 'accessing' }
MistakeTag >> category [

	^ category
]

{ #category : 'accessing' }
MistakeTag >> description [

	^ description
]

{ #category : 'accessing' }
MistakeTag >> id [

	^ id
]

{ #category : 'printing' }
MistakeTag >> printOn: aStream [

	aStream nextPutAll: id
]

{ #category : 'initialization' }
MistakeTag >> setId: anId category: aCategory description: aString [

	id := anId.
	category := aCategory.
	description := aString
]
