"
A setting changed (key as in settings.json); the session has already applied it.
"
Class {
	#name : 'MMSettingsChanged',
	#superclass : 'Announcement',
	#instVars : [
		'key'
	],
	#category : 'Mamotreto-Core',
	#package : 'Mamotreto-Core'
}

{ #category : 'accessing' }
MMSettingsChanged >> key [

	^ key
]

{ #category : 'accessing' }
MMSettingsChanged >> key: aString [

	key := aString
]
