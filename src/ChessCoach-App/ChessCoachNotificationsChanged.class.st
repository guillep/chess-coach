"
Announced by the session when a notification is posted, read or dismissed.
"
Class {
	#name : 'ChessCoachNotificationsChanged',
	#superclass : 'Announcement',
	#instVars : [
		'notifications'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'accessing' }
ChessCoachNotificationsChanged >> notifications [

	^ notifications
]

{ #category : 'accessing' }
ChessCoachNotificationsChanged >> notifications: aChessCoachNotifications [

	notifications := aChessCoachNotifications
]
