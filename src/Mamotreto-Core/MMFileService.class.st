"
I am a service of the shell kept in one JSON file of the app's data directory, with a format version in 'formatVersion' (a file without one is version 0). Subclasses say what they keep.
A corrupt file or one from a newer version is kept as <name>.bad, reportBlock is told why and the service starts from its defaults. Writes go through a temporary file, so a failure can't leave half a file. Each change is reported to changedBlock.
"
Class {
	#name : 'MMFileService',
	#superclass : 'Object',
	#instVars : [
		'file',
		'changedBlock',
		'reportBlock'
	],
	#category : 'Mamotreto-Core',
	#package : 'Mamotreto-Core'
}

{ #category : 'constants' }
MMFileService class >> formatVersion [
	"The version of my file. A new field bumps it."

	^ 1
]

{ #category : 'instance creation' }
MMFileService class >> onFile: aFileReference [

	^ self onFile: aFileReference reportingTo: [ :reason |  ]
]

{ #category : 'instance creation' }
MMFileService class >> onFile: aFileReference reportingTo: aBlock [
	"aBlock receives why the file could not be used, when it was set aside"

	^ self new setFile: aFileReference reportingTo: aBlock
]

{ #category : 'accessing' }
MMFileService >> badFile [
	"Where an unreadable file is kept"

	^ file parent / (file basename , '.bad')
]

{ #category : 'initialization' }
MMFileService >> load [
	"Read what my file keeps; subclasses start from their defaults and add what readIfAbsent: answers"

	
]

{ #category : 'file' }
MMFileService >> readIfAbsent: aBlock [
	"The saved JSON, or aBlock's value when there is no file or it was set aside"

	| contents |
	file exists ifFalse: [ ^ aBlock value ].
	contents := [ STONJSON fromString: file contents ]
		            on: Error
		            do: [ :error |
				            self setAside: 'It could not be read'.
				            ^ aBlock value ].
	(self versionOf: contents) > self class formatVersion ifTrue: [
			self setAside: 'It comes from a newer version'.
			^ aBlock value ].
	^ contents
]

{ #category : 'file' }
MMFileService >> setAside: aString [
	"Keep the file as .bad, to not lose it, and say why. A copy is renamed: renameTo: changes its receiver."

	| bad |
	bad := self badFile.
	bad ensureDelete.
	file copy renameTo: bad basename.
	reportBlock value:
		aString , '; ' , file basename , ' was kept as ' , bad basename
]

{ #category : 'initialization' }
MMFileService >> setFile: aFileReference reportingTo: aBlock [

	file := aFileReference.
	reportBlock := aBlock.
	self load
]

{ #category : 'file' }
MMFileService >> versionOf: someContents [
	"0 for a file without a version, or for one that isn't an object"

	| found |
	someContents isDictionary ifFalse: [ ^ 0 ].
	found := someContents at: 'formatVersion' ifAbsent: [ 0 ].
	^ found isInteger
		  ifTrue: [ found ]
		  ifFalse: [ SmallInteger maxVal ]
]

{ #category : 'accessing' }
MMFileService >> whenChangedDo: aBlock [

	changedBlock := aBlock
]

{ #category : 'file' }
MMFileService >> write: aDictionary [
	"Save aDictionary with my version, through a temporary file"

	| temporary |
	file parent ensureCreateDirectory.
	temporary := file parent / (file basename , '.tmp').
	temporary
		ensureDelete;
		writeStreamDo: [ :stream |
				stream nextPutAll: (STONJSON toStringPretty: (aDictionary copy
									  at: 'formatVersion' put: self class formatVersion;
									  yourself)) ].
	file ensureDelete.
	temporary renameTo: file basename
]
