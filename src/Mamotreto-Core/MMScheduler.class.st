"
I am the app's only background process. When I wake up I run the periodic checks that are due (new games, updates), each when I start and then every interval, then the work given to whenWokenDo:, such as a task manager's queued jobs. Then I sleep until the next check is due or someone signals my wakeup semaphore.
I live with the app window: its session starts me when it opens and stops me when it closes. Nothing else in the app forks.
A task's errors go to errorBlock, so one failing check never stops the others.
"
Class {
	#name : 'MMScheduler',
	#superclass : 'Object',
	#instVars : [
		'tasks',
		'process',
		'errorBlock',
		'wakeup',
		'workBlock'
	],
	#category : 'Mamotreto-Core',
	#package : 'Mamotreto-Core'
}

{ #category : 'accessing' }
MMScheduler >> every: aDuration do: aBlock [
	"Run aBlock when I start, then every aDuration. A task is { interval. block. next run time }"

	tasks add: {
			aDuration.
			aBlock.
			nil }
]

{ #category : 'initialization' }
MMScheduler >> initialize [

	super initialize.
	tasks := OrderedCollection new.
	errorBlock := [ :error |  ].
	wakeup := Semaphore new.
	workBlock := [ ]
]

{ #category : 'accessing' }
MMScheduler >> intervals [

	^ tasks collect: [ :task | task first ]
]

{ #category : 'testing' }
MMScheduler >> isRunning [

	^ process notNil and: [ process isTerminated not ]
]

{ #category : 'running' }
MMScheduler >> millisecondsUntilNextTaskAt: aDateAndTime [
	"How long to sleep: until the next task is due, at least a second and at most a minute, so that a changed clock is noticed"

	| next |
	next := tasks
		        inject: aDateAndTime + 1 minute
		        into: [ :soonest :task |
			        (task at: 3)
				        ifNil: [ soonest ]
				        ifNotNil: [ :due | soonest min: due ] ].
	^ ((next - aDateAndTime) asMilliSeconds max: 1000) min: 60000
]

{ #category : 'accessing' }
MMScheduler >> onErrorDo: aBlock [

	errorBlock := aBlock
]

{ #category : 'running' }
MMScheduler >> runDueTasksAt: aDateAndTime [
	"Run every task never run or due at aDateAndTime, and plan its next run"

	tasks do: [ :task |
			((task at: 3) isNil or: [ (task at: 3) <= aDateAndTime ]) ifTrue: [
					task at: 3 put: aDateAndTime + (task at: 1).
					[ (task at: 2) value ]
						on: Error
						do: [ :error | errorBlock value: error ] ] ]
]

{ #category : 'running' }
MMScheduler >> start [
	"Run in the app's only background process: the due tasks, then the work given to whenWokenDo:, then sleep until the next task is due or wakeup is signalled"

	self isRunning ifTrue: [ ^ self ].
	process := [
		           [
			           self runDueTasksAt: DateAndTime now.
			           workBlock value.
			           wakeup waitTimeoutMilliseconds:
				           (self millisecondsUntilNextTaskAt: DateAndTime now) ]
			           repeat ]
		           forkAt: Processor userBackgroundPriority
		           named: 'Mamotreto worker'
]

{ #category : 'running' }
MMScheduler >> stop [

	process ifNotNil: [ process terminate ].
	process := nil
]

{ #category : 'accessing' }
MMScheduler >> wakeup [
	"Signalled when there is work to run now"

	^ wakeup
]

{ #category : 'accessing' }
MMScheduler >> whenWokenDo: aBlock [
	"After the due tasks, my process runs aBlock, such as a task manager's queued jobs. Signal wakeup to have it run at once."

	workBlock := aBlock
]
