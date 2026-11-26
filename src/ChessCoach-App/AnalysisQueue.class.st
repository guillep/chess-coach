"
Analyses my games with Stockfish in the background, one at a time, newest first, with its own engine. The coach can move a game to the front and pauses the queue while it runs. Announces AnalysisQueueChanged on the session's announcer after each step. runNext analyses one game synchronously (tests); start/stop run it in a low-priority process.
"
Class {
	#name : 'AnalysisQueue',
	#superclass : 'Object',
	#instVars : [
		'session',
		'analyser',
		'pending',
		'current',
		'progress',
		'ready',
		'paused',
		'process',
		'mutex',
		'failed'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'instance creation' }
AnalysisQueue class >> session: aChessCoachSession analyser: aGameAnalyser [

	^ self new setSession: aChessCoachSession analyser: aGameAnalyser
]

{ #category : 'accessing' }
AnalysisQueue >> analyser [

	^ analyser
]

{ #category : 'private' }
AnalysisQueue >> announce: aGameIdOrNil [

	session announcer announce: (AnalysisQueueChanged new
			 gameId: aGameIdOrNil;
			 yourself)
]

{ #category : 'queueing' }
AnalysisQueue >> enqueue: aGameIndexEntry [
	"Queue one game at the front, unless it is analysed, being analysed or already queued. A game that failed is tried again."

	| id |
	id := aGameIndexEntry gameId.
	(mutex critical: [
		 (pending includes: id) or: [
			 current = id or: [ ready includes: id ] ] ]) ifTrue: [ ^ self ].
	mutex critical: [ failed remove: id ifAbsent: [ ] ].
	(session isAnalysed: aGameIndexEntry)
		ifTrue: [ mutex critical: [ ready add: id ] ]
		ifFalse: [ mutex critical: [ pending addFirst: id ] ].
	self announce: id
]

{ #category : 'queueing' }
AnalysisQueue >> enqueueUnanalysed [
	"Queue the stored games that have no analysis yet, newest first. Games that failed stay out, so that one bad game doesn't run again and again."

	session games do: [ :entry |
			| id |
			id := entry gameId.
			(mutex critical: [
				 (pending includes: id) or: [
					 current = id or: [ (ready includes: id) or: [ failed includes: id ] ] ] ]) ifFalse: [
					(session isAnalysed: entry)
						ifTrue: [ mutex critical: [ ready add: id ] ]
						ifFalse: [ mutex critical: [ pending add: id ] ] ] ].
	self announce: nil
]

{ #category : 'testing' }
AnalysisQueue >> isPaused [

	^ paused
]

{ #category : 'testing' }
AnalysisQueue >> isRunning [

	^ process notNil and: [ process isTerminated not ]
]

{ #category : 'running' }
AnalysisQueue >> pause [
	"Finish the current game, then wait (the coach needs the CPU)"

	paused := true
]

{ #category : 'accessing' }
AnalysisQueue >> pendingGameIds [

	^ mutex critical: [ pending copy ]
]

{ #category : 'queueing' }
AnalysisQueue >> prioritise: aGameIndexEntry [
	"Analyse this game next (the coach is waiting for it)"

	| id |
	id := aGameIndexEntry gameId.
	(self stateOf: aGameIndexEntry) = #queued ifFalse: [ ^ self ].
	mutex critical: [
			pending remove: id.
			pending addFirst: id ].
	self announce: id
]

{ #category : 'accessing' }
AnalysisQueue >> progress [
	"Positions analysed and total for the game being analysed, as done -> total"

	^ progress
]

{ #category : 'running' }
AnalysisQueue >> resume [

	paused := false
]

{ #category : 'running' }
AnalysisQueue >> runNext [
	"Analyse the first queued game; answer whether there was one. An error is logged and the game marked failed: it must not escape my process, where it would quit a packaged app."

	| entry succeeded |
	mutex critical: [
			pending ifNotEmpty: [
					current := pending removeFirst.
					progress := 0 -> 0 ] ].
	current ifNil: [ ^ false ].
	entry := session games detect: [ :each | each gameId = current ].
	self announce: current.
	succeeded := [
	             session analyse: entry with: analyser onProgress: [ :done :total |
			             progress := done -> total.
			             self announce: entry gameId ].
	             true ]
		             on: Error
		             do: [ :error |
			             session logError: error.
			             false ].
	mutex critical: [
			(succeeded
				 ifTrue: [ ready ]
				 ifFalse: [ failed ]) add: current.
			current := nil.
			progress := nil ].
	self announce: entry gameId.
	^ true
]

{ #category : 'initialization' }
AnalysisQueue >> setSession: aChessCoachSession analyser: aGameAnalyser [

	session := aChessCoachSession.
	analyser := aGameAnalyser.
	pending := OrderedCollection new.
	ready := Set new.
	failed := Set new.
	paused := false.
	mutex := Mutex new
]

{ #category : 'running' }
AnalysisQueue >> start [
	"Analyse queued games in a low-priority process until stopped; idle while paused or empty"

	self isRunning ifTrue: [ ^ self ].
	process := [
		           [ true ] whileTrue: [
				           (paused or: [ self runNext not ]) ifTrue: [
					           (Delay forMilliseconds: 500) wait ] ] ]
		           forkAt: Processor userBackgroundPriority
		           named: 'Chess coach analysis queue'
]

{ #category : 'accessing' }
AnalysisQueue >> stateOf: aGameIndexEntry [
	"#ready, #analysing, #queued, #failed or #unknown (not queued yet)"

	| id |
	id := aGameIndexEntry gameId.
	^ mutex critical: [
			  (ready includes: id)
				  ifTrue: [ #ready ]
				  ifFalse: [
						  current = id
							  ifTrue: [ #analysing ]
							  ifFalse: [
									  (pending includes: id)
										  ifTrue: [ #queued ]
										  ifFalse: [
											  (failed includes: id)
												  ifTrue: [ #failed ]
												  ifFalse: [ #unknown ] ] ] ] ]
]

{ #category : 'running' }
AnalysisQueue >> stop [
	"Stop the background process (a game being analysed goes back to the front of the queue) and quit its Stockfish"

	process ifNotNil: [
			process terminate.
			process := nil.
			mutex critical: [
					current ifNotNil: [
							pending addFirst: current.
							current := nil.
							progress := nil ] ] ].
	analyser engine stop
]
