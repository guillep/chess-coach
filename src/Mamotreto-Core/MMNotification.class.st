"
I am one entry of the notification center under the bell. My kind is the app's (Chessmate has #newGames), except the shell's own: an available update (#update), a failing background check (#error) and a saved file that could not be read (#problem).
My key identifies what I am about (e.g. 'update-v0.4.0', 'error-Lichess'): while I am not dismissed, a new notification with my key replaces me. I am kept in notifications.json.
"
Class {
	#name : 'MMNotification',
	#superclass : 'Object',
	#instVars : [
		'key',
		'kind',
		'title',
		'text',
		'time',
		'read',
		'dismissed'
	],
	#category : 'Mamotreto-Core',
	#package : 'Mamotreto-Core'
}

{ #category : 'instance creation' }
MMNotification class >> fromDictionary: aDictionary [
	"Read one notification as written by asDictionary"

	^ (self new
		   setKey: (aDictionary at: 'key')
		   kind: (aDictionary at: 'kind') asSymbol
		   title: (aDictionary at: 'title')
		   text: (aDictionary at: 'text')
		   time: (DateAndTime fromString: (aDictionary at: 'time')))
		  setRead: (aDictionary at: 'read')
		  dismissed: (aDictionary at: 'dismissed');
		  yourself
]

{ #category : 'instance creation' }
MMNotification class >> key: aString kind: aSymbol title: titleString text: textString [

	^ self new
		  setKey: aString
		  kind: aSymbol
		  title: titleString
		  text: textString
		  time: DateAndTime now
]

{ #category : 'instance creation' }
MMNotification class >> problem: aString [
	"A saved file that could not be read; aString says why and where it was kept"

	^ self
		  key: 'problem-' , aString
		  kind: #problem
		  title: 'A saved file could not be read'
		  text: aString
]

{ #category : 'converting' }
MMNotification >> asDictionary [

	^ Dictionary new
		  at: 'key' put: key;
		  at: 'kind' put: kind asString;
		  at: 'title' put: title;
		  at: 'text' put: text;
		  at: 'time' put: time printString;
		  at: 'read' put: read;
		  at: 'dismissed' put: dismissed;
		  yourself
]

{ #category : 'actions' }
MMNotification >> beDismissed [

	dismissed := true
]

{ #category : 'actions' }
MMNotification >> beRead [

	read := true
]

{ #category : 'testing' }
MMNotification >> isDismissed [

	^ dismissed
]

{ #category : 'testing' }
MMNotification >> isRead [

	^ read
]

{ #category : 'testing' }
MMNotification >> isUpdate [

	^ kind = #update
]

{ #category : 'accessing' }
MMNotification >> key [

	^ key
]

{ #category : 'accessing' }
MMNotification >> kind [

	^ kind
]

{ #category : 'initialization' }
MMNotification >> setKey: aString kind: aSymbol title: titleString text: textString time: aDateAndTime [

	key := aString.
	kind := aSymbol.
	title := titleString.
	text := textString.
	time := aDateAndTime.
	read := false.
	dismissed := false
]

{ #category : 'initialization' }
MMNotification >> setRead: readBoolean dismissed: dismissedBoolean [

	read := readBoolean.
	dismissed := dismissedBoolean
]

{ #category : 'accessing' }
MMNotification >> text [

	^ text
]

{ #category : 'accessing' }
MMNotification >> time [

	^ time
]

{ #category : 'accessing' }
MMNotification >> title [

	^ title
]
