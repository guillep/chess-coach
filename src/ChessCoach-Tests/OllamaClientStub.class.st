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
