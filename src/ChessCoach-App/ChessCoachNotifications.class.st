"
I am the notification center: the ChessCoachNotifications shown under the bell, newest first, kept in notifications.json next to the games. Each change is saved at once and reported to changedBlock.
Posting replaces the undismissed notification with the same key. A dismissed update stays dismissed: its version is not notified again. Dismissed notifications of other kinds are dropped.
"
Class {
	#name : 'ChessCoachNotifications',
	#superclass : 'Object',
	#instVars : [
		'file',
		'items',
		'changedBlock'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'instance creation' }
ChessCoachNotifications class >> onFile: aFileReference [

	^ self new setFile: aFileReference
]

{ #category : 'actions' }
ChessCoachNotifications >> dismiss: aNotification [

	aNotification beDismissed.
	self saveAndReport
]

{ #category : 'actions' }
ChessCoachNotifications >> markAllRead [

	self visible do: [ :each | each beRead ].
	self saveAndReport
]

{ #category : 'actions' }
ChessCoachNotifications >> post: aNotification [
	"Show aNotification first, replacing the undismissed one with its key. A dismissed update with its key is not shown again.
	items is replaced, never changed, so the UI can read it while a background check posts"

	(aNotification isUpdate and: [
			 items anySatisfy: [ :each |
				 each key = aNotification key and: [ each isDismissed ] ] ])
		ifTrue: [ ^ self ].
	items := { aNotification } , (items reject: [ :each |
		          each key = aNotification key and: [ each isDismissed not ] ]).
	self saveAndReport
]

{ #category : 'private' }
ChessCoachNotifications >> saveAndReport [
	"Drop dismissed notifications except updates (they remember a version not to notify again), save and report"

	items := items reject: [ :each |
		         each isDismissed and: [ each isUpdate not ] ].
	file parent ensureCreateDirectory.
	file
		ensureDelete;
		writeStreamDo: [ :stream |
				stream nextPutAll: (STONJSON toStringPretty:
								 (items collect: [ :each | each asDictionary ])) ].
	changedBlock value
]

{ #category : 'initialization' }
ChessCoachNotifications >> setFile: aFileReference [

	file := aFileReference.
	changedBlock := [ ].
	items := file exists
		         ifTrue: [
				         ((STONJSON fromString: file contents) collect: [ :each |
					          ChessCoachNotification fromDictionary: each ]) asArray ]
		         ifFalse: [ #(  ) ]
]

{ #category : 'accessing' }
ChessCoachNotifications >> unreadCount [

	^ self visible count: [ :each | each isRead not ]
]

{ #category : 'accessing' }
ChessCoachNotifications >> visible [
	"The notifications under the bell, newest first"

	^ items reject: [ :each | each isDismissed ]
]

{ #category : 'accessing' }
ChessCoachNotifications >> whenChangedDo: aBlock [

	changedBlock := aBlock
]
