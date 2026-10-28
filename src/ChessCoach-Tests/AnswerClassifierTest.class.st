Class {
	#name : 'AnswerClassifierTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
AnswerClassifierTest >> testClassify [

	| client labels request |
	client := OllamaClientStub new replyContent:
		          '{"tags":[{"tag":"missed-opponent-threat","confidence":0.9}]}'.
	labels := (AnswerClassifier
		           client: client
		           taxonomy: MistakeTaxonomy default)
		          classify: 'I did not see his knight could fork'
		          question: 'Why did you play Qd2?'
		          context: 'Played Qd2, best was Qe2'.
	self assert: labels size equals: 1.
	self assert: labels first tagId equals: 'missed-opponent-threat'.
	self assert: labels first confidence equals: 0.9.
	self deny: labels first isConfirmed.
	self assert: client requests size equals: 1.
	request := client requests first.
	self assert: (request at: 'stream') equals: false.
	self assert:
		((((request at: 'format') at: 'properties') at: 'tags') at: 'items')
			isDictionary.
	self assert:
		(((request at: 'messages') first at: 'content') includesSubstring:
			 'hope-chess').
	self assert:
		(((request at: 'messages') last at: 'content') includesSubstring:
			 'knight could fork')
]

{ #category : 'tests' }
AnswerClassifierTest >> testInstalledModels [

	self
		assert:
		(OllamaClientStub new replyContent: '{}') installedModels asArray
		equals: #( 'qwen2.5:7b-instruct' 'llama3.1:8b' )
]
