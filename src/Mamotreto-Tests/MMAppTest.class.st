"
I test what MMApp declares for every app, with the example app: where its files go.
"
Class {
	#name : 'MMAppTest',
	#superclass : 'TestCase',
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'running' }
MMAppTest >> tearDown [

	MMExampleApp resetDataLocation.
	super tearDown
]

{ #category : 'tests' }
MMAppTest >> testDataDirectoryDefaultsToAHiddenFolderInHome [

	self
		assert: MMExampleApp new dataDirectory
		equals: FileLocator home / ('.' , MMExampleApp new name asLowercase)
]

{ #category : 'tests' }
MMAppTest >> testDataLocationBelongsToOneApp [

	MMExampleApp dataIn: #documents named: 'Example'.

	self assert: MMApp dataLocation isNil
]

{ #category : 'tests' }
MMAppTest >> testDataLocationSetAtBuildTimeIsResolvedWhenUsed [

	MMExampleApp dataIn: #documents named: 'Example'.

	self
		assert: MMExampleApp new dataDirectory
		equals: FileLocator documents / 'Example'.
	self assert: MMExampleApp new dataDirectory origin equals: #documents
]
