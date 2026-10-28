"
Classifies a free-text answer about a chess moment into MistakeTaxonomy tags (MistakeLabel with confidence) using a local LLM.
"
Class {
	#name : 'AnswerClassifier',
	#superclass : 'Object',
	#instVars : [
		'client',
		'taxonomy'
	],
	#category : 'ChessCoach-LLM',
	#package : 'ChessCoach-LLM'
}

{ #category : 'instance creation' }
AnswerClassifier class >> client: anOllamaClient taxonomy: aMistakeTaxonomy [

	^ self new setClient: anOllamaClient taxonomy: aMistakeTaxonomy
]

{ #category : 'classifying' }
AnswerClassifier >> classify: anAnswer question: aQuestion context: aContext [
	"Answer MistakeLabels for anAnswer, given the coach's question and a short description of the moment."

	| reply |
	reply := client
		         chatSystem: self systemPrompt
		         user: ('Moment: {1}
Coach question: {2}
Player answer: {3}' format: {
					          aContext.
					          aQuestion.
					          anAnswer })
		         schema: self schema.
	^ ((reply at: 'tags') collect: [ :each |
			   MistakeLabel
				   tagId: (each at: 'tag')
				   confidence: (each at: 'confidence') ]) asArray
]

{ #category : 'accessing' }
AnswerClassifier >> client [

	^ client
]

{ #category : 'private' }
AnswerClassifier >> schema [
	"JSON schema restricting the reply to known taxonomy tags."

	| tag |
	tag := Dictionary new
		       at: 'type' put: 'object';
		       at: 'properties' put: (Dictionary new
				        at: 'tag' put: (Dictionary new
						         at: 'type' put: 'string';
						         at: 'enum' put: taxonomy tagIds;
						         yourself);
				        at: 'confidence' put: (Dictionary new
					         at: 'type' put: 'number';
					         yourself);
				        yourself);
		       at: 'required' put: #( 'tag' 'confidence' );
		       yourself.
	^ Dictionary new
		  at: 'type' put: 'object';
		  at: 'properties' put: (Dictionary new
				   at: 'tags' put: (Dictionary new
						    at: 'type' put: 'array';
						    at: 'items' put: tag;
						    yourself);
				   yourself);
		  at: 'required' put: #( 'tags' );
		  yourself
]

{ #category : 'initialization' }
AnswerClassifier >> setClient: anOllamaClient taxonomy: aMistakeTaxonomy [

	client := anOllamaClient.
	taxonomy := aMistakeTaxonomy
]

{ #category : 'private' }
AnswerClassifier >> systemPrompt [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll:
					  'You classify a chess player''s explanation of a move into a mistake taxonomy. Pick only the tags the explanation supports (usually 1 to 3, none if it shows no mistake), each with a confidence between 0 and 1. Tags:';
				  cr.
			  taxonomy tags do: [ :each |
					  stream
						  nextPutAll: '- ';
						  nextPutAll: each id;
						  nextPutAll: ' (';
						  nextPutAll: each category;
						  nextPutAll: '): ';
						  nextPutAll: each description;
						  cr ] ]
]
