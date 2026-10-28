Class {
	#name : 'AnalysisQueueTest',
	#superclass : 'TestCase',
	#instVars : [
		'session',
		'queue',
		'engine',
		'announcements'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'running' }
AnalysisQueueTest >> setUp [

	super setUp.
	session := (LichessAPIClientStub withGames: 3) newSessionOn:
		           FileSystem memory root.
	session login.
	session loadMoreGames.
	engine := StockfishEngineStub new.
	session analyser: (GameAnalyser engine: engine).
	queue := AnalysisQueue
		         session: session
		         analyser: (GameAnalyser engine: engine).
	announcements := OrderedCollection new.
	session announcer
		when: AnalysisQueueChanged
		do: [ :each | announcements add: each gameId ]
		for: self
]

{ #category : 'tests' }
AnalysisQueueTest >> testAlreadyAnalysedGamesAreReady [

	session analysisFor: session games first.
	queue enqueueUnanalysed.
	self assert: (queue stateOf: session games first) equals: #ready.
	self assert: queue pendingGameIds size equals: 2
]

{ #category : 'tests' }
AnalysisQueueTest >> testAnalysesNewestFirstAndReportsProgress [

	| games |
	games := session games.
	queue enqueueUnanalysed.
	self
		assert: queue pendingGameIds asArray
		equals: (games collect: [ :each | each gameId ]) asArray.
	self assert: (queue stateOf: games first) equals: #queued.
	self assert: queue runNext.
	self assert: (queue stateOf: games first) equals: #ready.
	self assert: (session isAnalysed: games first).
	self assert: (announcements includes: games first gameId).
	self assert: queue progress isNil.
	queue
		runNext;
		runNext.
	self deny: queue runNext.
	queue enqueueUnanalysed.
	self assert: queue pendingGameIds isEmpty
]

{ #category : 'tests' }
AnalysisQueueTest >> testPrioritiseMovesAGameToTheFront [

	| oldest |
	oldest := session games last.
	queue enqueueUnanalysed.
	queue prioritise: oldest.
	self assert: queue pendingGameIds first equals: oldest gameId.
	queue runNext.
	self assert: (queue stateOf: oldest) equals: #ready.
	queue prioritise: oldest.
	self assert: queue pendingGameIds size equals: 2
]
