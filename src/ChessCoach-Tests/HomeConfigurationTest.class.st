Class {
	#name : 'HomeConfigurationTest',
	#superclass : 'TestCase',
	#instVars : [
		'file',
		'reports'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
HomeConfigurationTest >> configuration [

	^ HomeConfiguration
		  onFile: file
		  report: [ :text | reports add: text ]
]

{ #category : 'running' }
HomeConfigurationTest >> setUp [

	super setUp.
	file := FileSystem memory root / 'home.json'.
	reports := OrderedCollection new
]

{ #category : 'tests' }
HomeConfigurationTest >> testCorruptFileIsKept [

	file writeStreamDo: [ :stream | stream nextPutAll: '{oops' ].
	self assert: self configuration grid widgets size equals: 4.
	self assert: (file parent / 'home.json.bad') exists.
	self assert: reports size equals: 1
]

{ #category : 'tests' }
HomeConfigurationTest >> testMissingFieldsGetDefaults [

	file writeStreamDo: [ :stream |
		stream nextPutAll: '{"version":1,"widgets":[{"type":"numbers"}]}' ].
	self
		assert: self configuration grid widgets first cell extent
		equals: 6 @ 4
]

{ #category : 'tests' }
HomeConfigurationTest >> testMissingFileGivesTheDefaultHome [

	self assert: self configuration grid widgets size equals: 4.
	self deny: file exists
]

{ #category : 'tests' }
HomeConfigurationTest >> testNewerVersionIsKept [

	file writeStreamDo: [ :stream |
		stream nextPutAll: '{"version":99,"widgets":[]}' ].
	self assert: self configuration grid widgets size equals: 4.
	self assert: (file parent / 'home.json.bad') exists
]

{ #category : 'tests' }
HomeConfigurationTest >> testSavedWidgetsComeBack [

	| saved |
	saved := self configuration.
	saved grid widgets first filterAt: 'result' put: 'lost'.
	saved save.
	self
		assert: (self configuration grid widgets first filter at: 'result')
		equals: 'lost'
]

{ #category : 'tests' }
HomeConfigurationTest >> testUnknownTypeIsSkippedAndReported [

	file writeStreamDo: [ :stream |
			stream nextPutAll:
				'{"version":1,"widgets":[{"type":"chart"},{"type":"numbers"}]}' ].
	self assert: self configuration grid widgets size equals: 1.
	self assert: reports size equals: 1
]
