"
I hold the state the shell shares with an app, in one data directory: the settings, the notification center, the scheduled checks, updates and the error log. The window only listens to my announcer: MMSettingsChanged and MMNotificationsChanged.
An app subclasses me: it says its repository and baseline, its settings class, adds its own checks to the scheduler and reacts to its settings.
"
Class {
	#name : 'MMSession',
	#superclass : 'Object',
	#instVars : [
		'dataDirectory',
		'announcer',
		'settings',
		'notifications',
		'scheduler',
		'updater',
		'availableUpdate'
	],
	#category : 'Mamotreto-Core',
	#package : 'Mamotreto-Core'
}

{ #category : 'app' }
MMSession class >> baselineName [
	"The app's baseline, without BaselineOf"

	^ self subclassResponsibility
]

{ #category : 'instance creation' }
MMSession class >> onDirectory: aFileReference [
	"A session keeping its data in aFileReference; tests pass a memory file system"

	^ self new setDataDirectory: aFileReference
]

{ #category : 'app' }
MMSession class >> repositoryName [
	"The name of the app's registered Iceberg repository"

	^ self subclassResponsibility
]

{ #category : 'accessing' }
MMSession >> announcer [

	^ announcer
]

{ #category : 'updates' }
MMSession >> appVersion [
	"The version of the app's repository in the style of git describe: nearest tag, commits since it and the commit. Without a tag, only the commit."

	| repository head distance |
	repository := IceRepository registry
		              detect: [ :each | each name = self repositoryName ]
		              ifNone: [ ^ 'Repository version not found' ].
	head := repository head commit.
	distance := 0.
	head commitsDo: [ :commit |
			commit tags ifNotEmpty: [ :tags |
					^ '{1}-{2}-g{3}' format: {
							  tags first name.
							  distance.
							  head shortId } ].
			distance := distance + 1 ].
	^ head shortId
]

{ #category : 'updates' }
MMSession >> availableUpdate [
	"The release tag to update to, or nil"

	^ availableUpdate
]

{ #category : 'app' }
MMSession >> baselineName [

	^ self class baselineName
]

{ #category : 'updates' }
MMSession >> checkForUpdate [
	"Look for a newer release and notify it; the notification also tells the window to show its Update button"

	availableUpdate := self updater availableUpdate.
	availableUpdate ifNil: [ ^ self ].
	self notifications post: (MMNotification
			 key: 'update-' , availableUpdate
			 kind: #update
			 title: 'Update available'
			 text: availableUpdate , ' can be installed')
]

{ #category : 'accessing' }
MMSession >> dataDirectory [

	^ dataDirectory
]

{ #category : 'errors' }
MMSession >> errorLog [
	"Errors the app showed instead of opening a debugger, newest last"

	^ dataDirectory / 'errors.log'
]

{ #category : 'settings' }
MMSession >> isFirstRun [
	"The setup wizard has never been finished"

	^ (self settings at: 'setupDone') not
]

{ #category : 'errors' }
MMSession >> logError: anError [
	"Append anError with its stack to errors.log, for bug reports"

	(MMErrorLog onFile: self errorLog) log: anError
]

{ #category : 'notifications' }
MMSession >> notifications [
	"The notification center, in notifications.json"

	^ notifications ifNil: [
			  notifications := MMNotifications onFile:
				                   dataDirectory / 'notifications.json'.
			  notifications whenChangedDo: [
					  announcer announce: (MMNotificationsChanged new
							   notifications: notifications;
							   yourself) ].
			  notifications ]
]

{ #category : 'app' }
MMSession >> repositoryName [

	^ self class repositoryName
]

{ #category : 'running' }
MMSession >> scheduleChecksIn: aScheduler [
	"Updates now and every 6 hours; subclasses add the app's checks"

	aScheduler every: 6 hours do: [ self checkForUpdate ]
]

{ #category : 'running' }
MMSession >> scheduler [

	^ scheduler
]

{ #category : 'initialization' }
MMSession >> setDataDirectory: aFileReference [

	dataDirectory := aFileReference.
	announcer := Announcer new
]

{ #category : 'settings' }
MMSession >> settingChanged: aKey [
	"Announce a changed setting; subclasses apply theirs first"

	announcer announce: (MMSettingsChanged new
			 key: aKey;
			 yourself)
]

{ #category : 'settings' }
MMSession >> settings [
	"The preferences, in settings.json. A file that can't be read is reported under the bell."

	^ settings ifNil: [
			  settings := self settingsClass
				              onFile: dataDirectory / 'settings.json'
				              reportingTo: [ :reason |
				              self notifications post:
					              (MMNotification problem: reason) ].
			  settings whenChangedDo: [ :key | self settingChanged: key ].
			  settings ]
]

{ #category : 'settings' }
MMSession >> settingsClass [
	"Apps with their own settings answer a subclass of MMSettings"

	^ MMSettings
]

{ #category : 'running' }
MMSession >> shutDown [
	"Stop the scheduled checks; subclasses stop their own work too"

	scheduler ifNotNil: [ scheduler stop ]
]

{ #category : 'running' }
MMSession >> startScheduledChecks [
	"Run the scheduled checks now and periodically, until shutDown. Unexpected errors go to errors.log"

	scheduler ifNotNil: [ scheduler stop ].
	scheduler := MMScheduler new.
	scheduler onErrorDo: [ :error | self logError: error ].
	self scheduleChecksIn: scheduler.
	scheduler start
]

{ #category : 'running' }
MMSession >> unfinishedTaskCount [
	"Background jobs running or waiting that change something, which closing the window would stop half done; jobs that only read don't count. Subclasses with a queue answer theirs."

	^ 0
]

{ #category : 'updates' }
MMSession >> updater [

	^ updater ifNil: [
			  updater := MMUpdater
				             repositoryNamed: self repositoryName
				             baseline: self baselineName ]
]

{ #category : 'updates' }
MMSession >> updater: anUpdater [

	updater := anUpdater
]
