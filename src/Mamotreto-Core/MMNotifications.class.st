"
I am the notification center: the MMNotifications shown under the bell, newest first. Each change is saved at once and reported to changedBlock.
Posting replaces the undismissed notification with the same key. A dismissed update stays dismissed: its version is not notified again. Dismissed notifications of other kinds are dropped.
When my own file can't be read, I start empty and post why.
"
Class {
	#name : 'MMNotifications',
	#superclass : 'MMFileService',
	#instVars : [
		'items'
	],
	#category : 'Mamotreto-Core',
	#package : 'Mamotreto-Core'
}

{ #category : 'constants' }
MMNotifications class >> limit [
	"Notifications kept under the bell; older ones are dropped"

	^ 50
]

{ #category : 'actions' }
MMNotifications >> dismiss: aNotification [

	aNotification beDismissed.
	self saveAndReport
]

{ #category : 'actions' }
MMNotifications >> dismissAll [

	self visible do: [ :each | each beDismissed ].
	self saveAndReport
]

{ #category : 'initialization' }
MMNotifications >> load [
	"Version 0 of the file is a bare list of notifications. A file I can't read is reported in me."

	| contents |
	changedBlock := [ ].
	items := #(  ).
	reportBlock := [ :reason |
	               self post: (MMNotification problem: reason) ].
	contents := self readIfAbsent: [ #(  ) ].
	contents isDictionary ifTrue: [ contents := contents at: 'items' ].
	items := items
	         ,
		         (contents collect: [ :each |
			          MMNotification fromDictionary: each ]) asArray
]

{ #category : 'actions' }
MMNotifications >> markAllRead [

	self visible do: [ :each | each beRead ].
	self saveAndReport
]

{ #category : 'actions' }
MMNotifications >> post: aNotification [
	"Show aNotification first, replacing the undismissed one with its key, and keep only the newest ones. A dismissed update with its key is not shown again.
	items is replaced, never changed, so the UI can read it while a background check posts"

	| kept |
	(aNotification isUpdate and: [
			 items anySatisfy: [ :each |
				 each key = aNotification key and: [ each isDismissed ] ] ])
		ifTrue: [ ^ self ].
	kept := 0.
	items := { aNotification } , (items reject: [ :each |
		          each key = aNotification key and: [ each isDismissed not ] ]).
	items := items select: [ :each |
			         each isDismissed or: [
					         kept := kept + 1.
					         kept <= self class limit ] ].
	self saveAndReport
]

{ #category : 'private' }
MMNotifications >> saveAndReport [
	"Drop dismissed notifications except updates (they remember a version not to notify again), save and report"

	items := items reject: [ :each |
		         each isDismissed and: [ each isUpdate not ] ].
	self write: (Dictionary new
			 at: 'items' put: (items collect: [ :each | each asDictionary ]);
			 yourself).
	changedBlock value
]

{ #category : 'accessing' }
MMNotifications >> unreadCount [

	^ self visible count: [ :each | each isRead not ]
]

{ #category : 'accessing' }
MMNotifications >> visible [
	"The notifications under the bell, newest first"

	^ items reject: [ :each | each isDismissed ]
]
