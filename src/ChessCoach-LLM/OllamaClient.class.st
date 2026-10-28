"
Talks to a local Ollama server (/api/chat, non-streaming) and asks for JSON output constrained by a JSON schema. Tests substitute OllamaClientStub, which overrides #post:.
"
Class {
	#name : 'OllamaClient',
	#superclass : 'Object',
	#instVars : [
		'baseUrl',
		'model'
	],
	#category : 'ChessCoach-LLM',
	#package : 'ChessCoach-LLM'
}

{ #category : 'accessing' }
OllamaClient >> baseUrl [

	^ baseUrl
]

{ #category : 'accessing' }
OllamaClient >> baseUrl: aString [

	baseUrl := aString
]

{ #category : 'chatting' }
OllamaClient >> chatSystem: aSystemPrompt user: aUserPrompt schema: aJSONSchema [
	"Answer the model's reply parsed as JSON, constrained to aJSONSchema."

	| response |
	response := self post: (Dictionary new
			             at: 'model' put: model;
			             at: 'stream' put: false;
			             at: 'format' put: aJSONSchema;
			             at: 'options' put: (Dictionary new
					              at: 'temperature' put: 0;
					              yourself);
			             at: 'messages' put: {
				             (Dictionary new
					              at: 'role' put: 'system';
					              at: 'content' put: aSystemPrompt;
					              yourself).
				             (Dictionary new
					              at: 'role' put: 'user';
					              at: 'content' put: aUserPrompt;
					              yourself) };
			             yourself).
	^ STONJSON fromString: ((response at: 'message') at: 'content')
]

{ #category : 'private' }
OllamaClient >> get: aPath [

	^ STONJSON fromString: (ZnClient new
			   url: baseUrl , aPath;
			   timeout: 10;
			   enforceHttpSuccess: true;
			   get)
]

{ #category : 'initialization' }
OllamaClient >> initialize [

	super initialize.
	baseUrl := 'http://localhost:11434'.
	model := 'qwen2.5:7b-instruct'
]

{ #category : 'models' }
OllamaClient >> installedModels [
	"Names of the models pulled into this Ollama, e.g. qwen2.5:7b-instruct"

	^ ((self get: '/api/tags') at: 'models') collect: [ :each |
		  each at: 'name' ]
]

{ #category : 'accessing' }
OllamaClient >> model [

	^ model
]

{ #category : 'accessing' }
OllamaClient >> model: aString [

	model := aString
]

{ #category : 'private' }
OllamaClient >> post: aDictionary [
	"POST aDictionary to /api/chat and answer the parsed JSON response."

	^ STONJSON fromString: (ZnClient new
			   url: baseUrl , '/api/chat';
			   timeout: 300;
			   enforceHttpSuccess: true;
			   entity: (ZnEntity json: (STONJSON toString: aDictionary));
			   post)
]
