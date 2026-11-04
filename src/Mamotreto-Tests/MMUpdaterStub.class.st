"
I am an MMUpdater without network, files or processes: I answer a given running tag and release tags, log the steps of an update instead of doing them, and can fail the download.
"
Class {
	#name : 'MMUpdaterStub',
	#superclass : 'MMUpdater',
	#instVars : [
		'current',
		'tags',
		'failure',
		'log'
	],
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'accessing' }
MMUpdaterStub >> current: aTag tags: someTags failure: anErrorMessageOrNil [

	self setGitHubRepository: 'owner/app'.
	current := aTag.
	tags := someTags.
	failure := anErrorMessageOrNil.
	log := OrderedCollection new
]

{ #category : 'private - io' }
MMUpdaterStub >> currentVersion [

	^ current ifNotNil: [ current allButFirst ]
]

{ #category : 'private - io' }
MMUpdaterStub >> download: aTagName [

	failure ifNotNil: [ self error: failure ].
	log add: aTagName.
	^ #zip
]

{ #category : 'private - io' }
MMUpdaterStub >> install: aNewBundle [

	log add: aNewBundle
]

{ #category : 'accessing' }
MMUpdaterStub >> log [

	^ log
]

{ #category : 'private - io' }
MMUpdaterStub >> quit [

	log add: #quit
]

{ #category : 'private - io' }
MMUpdaterStub >> releaseTags [

	^ tags
]

{ #category : 'private - io' }
MMUpdaterStub >> unpack: aZip [

	log add: aZip.
	^ #bundle
]
