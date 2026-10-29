Class {
	#name : 'ChessCoachNotificationsTest',
	#superclass : 'TestCase',
	#instVars : [
		'file',
		'notifications'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'private' }
ChessCoachNotificationsTest >> notificationKey: aString kind: aSymbol text: textString [

	^ ChessCoachNotification
		  key: aString
		  kind: aSymbol
		  title: aString
		  text: textString
]

{ #category : 'running' }
ChessCoachNotificationsTest >> setUp [

	super setUp.
	file := FileSystem memory root / 'notifications.json'.
	notifications := ChessCoachNotifications onFile: file
]

{ #category : 'tests' }
ChessCoachNotificationsTest >> testADismissedUpdateIsNotNotifiedAgain [

	notifications post:
		(self notificationKey: 'update-v0.4.0' kind: #update text: '').
	notifications dismiss: notifications visible first.
	notifications post:
		(self notificationKey: 'update-v0.4.0' kind: #update text: '').
	self assert: notifications visible isEmpty.
	notifications post:
		(self notificationKey: 'update-v0.5.0' kind: #update text: '').
	self assert: notifications visible size equals: 1
]

{ #category : 'tests' }
ChessCoachNotificationsTest >> testANewerNotificationComesFirst [

	notifications post:
		(self notificationKey: 'a' kind: #newGames text: '1').
	notifications post:
		(self notificationKey: 'b' kind: #newGames text: '2').
	self
		assert: (notifications visible collect: [ :each | each key ])
		equals: #( 'b' 'a' ).
	self assert: notifications unreadCount equals: 2
]

{ #category : 'tests' }
ChessCoachNotificationsTest >> testAnErrorComesBackAfterBeingDismissed [

	notifications post:
		(self notificationKey: 'error-Lichess' kind: #error text: 'first').
	notifications dismiss: notifications visible first.
	self assert: notifications visible isEmpty.
	notifications post:
		(self notificationKey: 'error-Lichess' kind: #error text: 'again').
	self assert: notifications visible first text equals: 'again'
]

{ #category : 'tests' }
ChessCoachNotificationsTest >> testAnErrorReplacesTheUndismissedOneWithItsKey [

	notifications post:
		(self notificationKey: 'error-Lichess' kind: #error text: 'first').
	notifications post:
		(self notificationKey: 'error-Lichess' kind: #error text: 'second').
	self assert: notifications visible size equals: 1.
	self assert: notifications visible first text equals: 'second'
]

{ #category : 'tests' }
ChessCoachNotificationsTest >> testChangesAreReported [

	| reported |
	reported := 0.
	notifications whenChangedDo: [ reported := reported + 1 ].
	notifications post:
		(self notificationKey: 'a' kind: #newGames text: '').
	notifications markAllRead.
	self assert: reported equals: 2
]

{ #category : 'tests' }
ChessCoachNotificationsTest >> testNotificationsAreKeptInTheFile [

	| reread |
	notifications post:
		(self notificationKey: 'update-v0.4.0' kind: #update text: 'notes').
	notifications post:
		(self notificationKey: 'games' kind: #newGames text: '3 new games').
	notifications markAllRead.
	notifications dismiss: notifications visible last.
	reread := ChessCoachNotifications onFile: file.
	self assert: reread visible size equals: 1.
	self assert: reread visible first kind equals: #newGames.
	self assert: reread visible first isRead.
	self assert: reread unreadCount equals: 0.
	reread post:
		(self notificationKey: 'update-v0.4.0' kind: #update text: 'notes').
	self assert: reread visible size equals: 1
]
