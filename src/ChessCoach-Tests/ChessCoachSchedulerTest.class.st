Class {
	#name : 'ChessCoachSchedulerTest',
	#superclass : 'TestCase',
	#instVars : [
		'scheduler',
		'runs'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'running' }
ChessCoachSchedulerTest >> setUp [

	super setUp.
	runs := 0.
	scheduler := ChessCoachScheduler new.
	scheduler every: 30 minutes do: [ runs := runs + 1 ]
]

{ #category : 'running' }
ChessCoachSchedulerTest >> tearDown [

	scheduler stop.
	super tearDown
]

{ #category : 'tests' }
ChessCoachSchedulerTest >> testAFailingTaskDoesNotStopTheOthers [

	| errors |
	errors := OrderedCollection new.
	scheduler onErrorDo: [ :error | errors add: error ].
	scheduler every: 1 hour do: [ 1 / 0 ].
	scheduler every: 1 hour do: [ runs := runs + 10 ].
	scheduler runDueTasksAt: DateAndTime now.
	self assert: runs equals: 11.
	self assert: errors size equals: 1
]

{ #category : 'tests' }
ChessCoachSchedulerTest >> testATaskRunsAtOnceThenEveryInterval [

	| start |
	start := DateAndTime now.
	scheduler runDueTasksAt: start.
	self assert: runs equals: 1.
	scheduler runDueTasksAt: start + 29 minutes.
	self assert: runs equals: 1.
	scheduler runDueTasksAt: start + 30 minutes.
	self assert: runs equals: 2
]

{ #category : 'tests' }
ChessCoachSchedulerTest >> testStartRunsTheTasksInTheBackgroundUntilStopped [

	scheduler start.
	self assert: scheduler isRunning.
	[ runs = 0 ] whileTrue: [ (Delay forMilliseconds: 20) wait ].
	self assert: runs equals: 1.
	scheduler stop.
	self deny: scheduler isRunning
]
