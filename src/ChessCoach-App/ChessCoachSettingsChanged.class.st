"
A setting changed (key as in settings.json); the session has already applied it.
"
Class {
	#name : 'ChessCoachSettingsChanged',
	#superclass : 'Announcement',
	#instVars : [
		'key'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'accessing' }
ChessCoachSettingsChanged >> key [

	^ key
]

{ #category : 'accessing' }
ChessCoachSettingsChanged >> key: aString [

	key := aString
]
