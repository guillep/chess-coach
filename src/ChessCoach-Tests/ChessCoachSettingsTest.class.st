Class {
	#name : 'ChessCoachSettingsTest',
	#superclass : 'TestCase',
	#instVars : [
		'root',
		'session'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'running' }
ChessCoachSettingsTest >> setUp [

	super setUp.
	root := FileSystem memory root.
	session := (LichessAPIClientStub withGames: 3) newSessionOn: root
]

{ #category : 'tests' }
ChessCoachSettingsTest >> testAnOlderFileGetsTheThresholdDefaults [

	| file settings |
	file := FileSystem memory root / 'old.json'.
	file writeStreamDo: [ :stream |
		stream nextPutAll: '{"formatVersion":1,"depth":20}' ].
	settings := ChessCoachSettings onFile: file.
	self assert: (settings at: 'depth') equals: 20.
	self assert: (settings at: 'momentBlunderDrop') equals: 30.
	self assert: (settings at: 'formatVersion') equals: 2
]

{ #category : 'tests' }
ChessCoachSettingsTest >> testAnalysisSettingsKeepStoredAnalyses [

	| engine queue entry |
	session login.
	session loadMoreGames.
	engine := StockfishEngineStub new.
	session analyser: (GameAnalyser engine: engine).
	queue := AnalysisQueue
		         session: session
		         analyser: (GameAnalyser engine: StockfishEngineStub new).
	session analysisQueue: queue.
	entry := session games first.
	session analysisFor: entry.
	queue enqueueUnanalysed.
	self assert: (queue stateOf: entry) equals: #ready.
	session settings at: 'depth' put: 12.
	self assert: session analyser depth equals: 12.
	self assert: queue analyser depth equals: 12.
	self assert: (session isAnalysed: entry).
	self assert: (queue stateOf: entry) equals: #ready.
	session settings at: 'multiPV' put: 2.
	self assert: queue analyser multiPV equals: 2.
	session settings at: 'stockfishPath' put: '/usr/local/bin/stockfish'.
	self
		assert: engine path
		equals: '/usr/local/bin/stockfish' asFileReference
]

{ #category : 'tests' }
ChessCoachSettingsTest >> testChessComUsernameIsSavedOnlyWhenItExists [

	| api |
	api := ChessComAPIClientStub new.
	api
		at: 'https://api.chess.com/pub/player/bob'
		answer: (Dictionary new
				 at: 'username' put: 'bob';
				 yourself).
	session chessComAPIClient: api.
	self deny: (session validateChessComUsername: 'nobody-here').
	self assert: session chessComUsername isNil.
	self assert: (session validateChessComUsername: ' Bob ').
	self assert: session chessComUsername equals: 'Bob'
]

{ #category : 'tests' }
ChessCoachSettingsTest >> testCoachSettings [

	session settings at: 'ollamaModel' put: 'llama3.1:8b'.
	session settings at: 'ollamaUrl' put: 'http://other:11434'.
	self assert: session classifier client model equals: 'llama3.1:8b'.
	self
		assert: session classifier client baseUrl
		equals: 'http://other:11434'
]

{ #category : 'tests' }
ChessCoachSettingsTest >> testDefaultsAndSavingAtOnce [

	| settings changed |
	settings := ChessCoachSettings onFile: root / 'settings.json'.
	self assert: settings depth equals: 18.
	self assert: settings multiPV equals: 3.
	self assert: settings gamesPerLoad equals: 20.
	self assert: settings ollamaModel equals: 'qwen2.5:7b-instruct'.
	self
		assert: settings stockfishPath
		equals: '/opt/homebrew/bin/stockfish' asFileReference.
	changed := OrderedCollection new.
	settings whenChangedDo: [ :key | changed add: key ].
	settings at: 'depth' put: 14.
	settings at: 'depth' put: 14.
	self assert: changed asArray equals: #( 'depth' ).
	self
		assert: (ChessCoachSettings onFile: root / 'settings.json') depth
		equals: 14.
	self
		should: [ settings at: 'nonsense' put: 1 ]
		raise: AssertionFailure
]
