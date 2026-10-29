"
I am one entry of the notification center: an available update (#update), newly downloaded games (#newGames) or a failing background check (#error).
My key identifies what I am about (e.g. 'update-v0.4.0', 'error-Lichess'): while I am not dismissed, a new notification with my key replaces me. I am kept in notifications.json.
"
Class {
	#name : 'ChessCoachNotification',
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
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'instance creation' }
ChessCoachNotification class >> fromDictionary: aDictionary [
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
ChessCoachNotification class >> key: aString kind: aSymbol title: titleString text: textString [

	^ self new
		  setKey: aString
		  kind: aSymbol
		  title: titleString
		  text: textString
		  time: DateAndTime now
]

{ #category : 'converting' }
ChessCoachNotification >> asDictionary [

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
ChessCoachNotification >> beDismissed [

	dismissed := true
]

{ #category : 'actions' }
ChessCoachNotification >> beRead [

	read := true
]

{ #category : 'testing' }
ChessCoachNotification >> isDismissed [

	^ dismissed
]

{ #category : 'testing' }
ChessCoachNotification >> isRead [

	^ read
]

{ #category : 'testing' }
ChessCoachNotification >> isUpdate [

	^ kind = #update
]

{ #category : 'accessing' }
ChessCoachNotification >> key [

	^ key
]

{ #category : 'accessing' }
ChessCoachNotification >> kind [

	^ kind
]

{ #category : 'initialization' }
ChessCoachNotification >> setKey: aString kind: aSymbol title: titleString text: textString time: aDateAndTime [

	key := aString.
	kind := aSymbol.
	title := titleString.
	text := textString.
	time := aDateAndTime.
	read := false.
	dismissed := false
]

{ #category : 'initialization' }
ChessCoachNotification >> setRead: readBoolean dismissed: dismissedBoolean [

	read := readBoolean.
	dismissed := dismissedBoolean
]

{ #category : 'accessing' }
ChessCoachNotification >> text [

	^ text
]

{ #category : 'accessing' }
ChessCoachNotification >> time [

	^ time
]

{ #category : 'accessing' }
ChessCoachNotification >> title [

	^ title
]
