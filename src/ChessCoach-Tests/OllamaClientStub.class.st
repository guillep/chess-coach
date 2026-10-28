"
Records chat requests and answers a canned message content instead of calling Ollama.
"
Class {
	#name : 'OllamaClientStub',
	#superclass : 'OllamaClient',
	#instVars : [
		'requests',
		'replyContent'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'private' }
OllamaClientStub >> get: aPath [

	self assert: aPath = '/api/tags'.
	replyContent ifNil: [
		^ ConnectionTimedOut signal: 'Ollama stub is offline' ].
	^ Dictionary new
		  at: 'models' put: {
				  (Dictionary new
					   at: 'name' put: 'qwen2.5:7b-instruct';
					   yourself).
				  (Dictionary new
					   at: 'name' put: 'llama3.1:8b';
					   yourself) };
		  yourself
]

{ #category : 'initialization' }
OllamaClientStub >> initialize [

	super initialize.
	requests := OrderedCollection new
]

{ #category : 'private' }
OllamaClientStub >> post: aDictionary [
	"Answer the canned reply; without one, behave like Ollama not running"

	replyContent ifNil: [
		^ ConnectionTimedOut signal: 'Ollama stub is offline' ].
	requests add: aDictionary.
	^ Dictionary new
		  at: 'message' put: (Dictionary new
				   at: 'content' put: replyContent;
				   yourself);
		  yourself
]

{ #category : 'accessing' }
OllamaClientStub >> replyContent: aJSONString [

	replyContent := aJSONString
]

{ #category : 'accessing' }
OllamaClientStub >> requests [

	^ requests
]
