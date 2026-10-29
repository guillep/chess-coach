"
I run the app's periodic background checks (new games, updates) in one process at background priority. Each task runs when I start and then every interval. I live with the app window: it starts me when it opens and stops me when it closes.
A task's errors go to errorBlock, so one failing check never stops the others.
"
Class {
	#name : 'ChessCoachScheduler',
	#superclass : 'Object',
	#instVars : [
		'tasks',
		'process',
		'errorBlock'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'accessing' }
ChessCoachScheduler >> every: aDuration do: aBlock [
	"Run aBlock when I start, then every aDuration. A task is { interval. block. next run time }"

	tasks add: {
			aDuration.
			aBlock.
			nil }
]

{ #category : 'initialization' }
ChessCoachScheduler >> initialize [

	super initialize.
	tasks := OrderedCollection new.
	errorBlock := [ :error |  ]
]

{ #category : 'testing' }
ChessCoachScheduler >> isRunning [

	^ process notNil and: [ process isTerminated not ]
]

{ #category : 'accessing' }
ChessCoachScheduler >> onErrorDo: aBlock [

	errorBlock := aBlock
]

{ #category : 'running' }
ChessCoachScheduler >> runDueTasksAt: aDateAndTime [
	"Run every task never run or due at aDateAndTime, and plan its next run"

	tasks do: [ :task |
			((task at: 3) isNil or: [ (task at: 3) <= aDateAndTime ]) ifTrue: [
					task at: 3 put: aDateAndTime + (task at: 1).
					[ (task at: 2) value ]
						on: Error
						do: [ :error | errorBlock value: error ] ] ]
]

{ #category : 'running' }
ChessCoachScheduler >> start [
	"Check for due tasks every few seconds in a background process"

	self isRunning ifTrue: [ ^ self ].
	process := [
		           [
			           self runDueTasksAt: DateAndTime now.
			           (Delay forSeconds: 5) wait ] repeat ]
		           forkAt: Processor userBackgroundPriority
		           named: 'Chess Coach scheduler'
]

{ #category : 'running' }
ChessCoachScheduler >> stop [

	process ifNotNil: [ process terminate ].
	process := nil
]
