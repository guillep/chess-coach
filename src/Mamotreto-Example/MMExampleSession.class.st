"
The session of the example app. Its one service is a scheduled greeting: every hour it posts a notification, as an app's own check would.
"
Class {
	#name : 'MMExampleSession',
	#superclass : 'MMSession',
	#category : 'Mamotreto-Example',
	#package : 'Mamotreto-Example'
}

{ #category : 'app' }
MMExampleSession class >> baselineName [

	^ 'ChessCoach'
]

{ #category : 'app' }
MMExampleSession class >> repositoryName [
	"The example lives in the repository of the shell"

	^ 'chess-coach'
]

{ #category : 'greeting' }
MMExampleSession >> greet [
	"Post the greeting, replacing the previous one"

	self notifications post: (MMNotification
			 key: 'greeting'
			 kind: #greeting
			 title: 'Hello'
			 text: 'The example check ran at ' , Time now print24)
]

{ #category : 'running' }
MMExampleSession >> scheduleChecksIn: aScheduler [
	"The greeting every hour, as well as updates"

	aScheduler every: 1 hour do: [ self greet ].
	super scheduleChecksIn: aScheduler
]
