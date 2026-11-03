Class {
	#name : 'MMSchedulerTest',
	#superclass : 'TestCase',
	#instVars : [
		'scheduler',
		'runs'
	],
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'running' }
MMSchedulerTest >> setUp [

	super setUp.
	runs := 0.
	scheduler := MMScheduler new.
	scheduler every: 30 minutes do: [ runs := runs + 1 ]
]

{ #category : 'running' }
MMSchedulerTest >> tearDown [

	scheduler stop.
	super tearDown
]

{ #category : 'tests' }
MMSchedulerTest >> testAFailingTaskDoesNotStopTheOthers [

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
MMSchedulerTest >> testATaskRunsAtOnceThenEveryInterval [

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
MMSchedulerTest >> testATaskStartingLaterWaitsUntilThen [

	| start count |
	start := DateAndTime now.
	count := 0.
	scheduler
		every: 2 hours
		from: start + 1 hour
		do: [ count := count + 1 ].
	scheduler runDueTasksAt: start.
	self assert: count equals: 0.
	scheduler runDueTasksAt: start + 1 hour.
	self assert: count equals: 1.
	scheduler runDueTasksAt: start + 2 hours.
	self assert: count equals: 1.
	scheduler runDueTasksAt: start + 3 hours.
	self assert: count equals: 2
]

{ #category : 'tests' }
MMSchedulerTest >> testStartRunsTheTasksInTheBackgroundUntilStopped [

	scheduler start.
	self assert: scheduler isRunning.
	[ runs = 0 ] whileTrue: [ (Delay forMilliseconds: 20) wait ].
	self assert: runs equals: 1.
	scheduler stop.
	self deny: scheduler isRunning
]
