"
Announced by the session when a notification is posted, read or dismissed.
"
Class {
	#name : 'MMNotificationsChanged',
	#superclass : 'Announcement',
	#instVars : [
		'notifications'
	],
	#category : 'Mamotreto-Core',
	#package : 'Mamotreto-Core'
}

{ #category : 'accessing' }
MMNotificationsChanged >> notifications [

	^ notifications
]

{ #category : 'accessing' }
MMNotificationsChanged >> notifications: someNotifications [

	notifications := someNotifications
]
