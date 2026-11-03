Class {
	#name : 'MMSettingsTest',
	#superclass : 'TestCase',
	#instVars : [
		'file',
		'reasons'
	],
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'private' }
MMSettingsTest >> fileContaining: aString [

	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream nextPutAll: aString ]
]

{ #category : 'running' }
MMSettingsTest >> setUp [

	super setUp.
	file := FileSystem memory root / 'data' / 'settings.json'.
	reasons := OrderedCollection new
]

{ #category : 'private' }
MMSettingsTest >> settings [

	^ MMSettings
		  onFile: file
		  reportingTo: [ :reason | reasons add: reason ]
]

{ #category : 'tests' }
MMSettingsTest >> testAChangeIsSavedWithTheVersionAndReported [

	| settings changed saved |
	settings := self settings.
	changed := OrderedCollection new.
	settings whenChangedDo: [ :key | changed add: key ].
	settings at: 'appTheme' put: 'Dark'.
	settings at: 'appTheme' put: 'Dark'.
	self assert: changed asArray equals: #( 'appTheme' ).
	self assert: self settings appTheme equals: 'Dark'.
	saved := STONJSON fromString: file contents.
	self
		assert: (saved at: 'formatVersion')
		equals: MMSettings formatVersion.
	self deny: (file parent / 'settings.json.tmp') exists.
	self
		should: [ settings at: 'nonsense' put: 1 ]
		raise: AssertionFailure
]

{ #category : 'tests' }
MMSettingsTest >> testACorruptFileGivesDefaultsAndIsKeptAsBad [

	| settings |
	self fileContaining: '{"appTheme":'.
	settings := self settings.
	self assert: settings appTheme equals: 'Light'.
	self deny: file exists.
	self assert: settings badFile contents equals: '{"appTheme":'.
	self assert: reasons size equals: 1.
	self assert: (reasons first includesSubstring: 'settings.json.bad')
]

{ #category : 'tests' }
MMSettingsTest >> testAMissingFieldGetsItsDefault [

	self fileContaining: '{"formatVersion":0,"appTheme":"Dark","gone":1}'.
	self assert: self settings appTheme equals: 'Dark'.
	self assert: (self settings at: 'setupDone') equals: false.
	self assert: reasons isEmpty
]

{ #category : 'tests' }
MMSettingsTest >> testANewerFileGivesDefaultsAndIsKeptAsBad [

	| settings |
	self fileContaining: '{"formatVersion":99,"appTheme":"Dark"}'.
	settings := self settings.
	self assert: settings appTheme equals: 'Light'.
	self assert: settings badFile exists.
	self assert: (reasons first includesSubstring: 'newer version')
]

{ #category : 'tests' }
MMSettingsTest >> testDefaultsWithoutAFile [

	self assert: self settings appTheme equals: 'Light'.
	self deny: file exists.
	self assert: reasons isEmpty
]
