"
I test what MMPackager gives PharoApplicationGenerator and the image, with the example app; building a bundle is left to the build script.
"
Class {
	#name : 'MMPackagerTest',
	#superclass : 'TestCase',
	#instVars : [
		'packager',
		'previousApp'
	],
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'running' }
MMPackagerTest >> setUp [

	super setUp.
	previousApp := MMLaunchCommand app.
	packager := MMPackager new
		            app: MMExampleApp;
		            version: '1.2.3';
		            bundleIdentifier: 'org.example.app';
		            outputDirectory: FileSystem memory root / 'build';
		            yourself
]

{ #category : 'running' }
MMPackagerTest >> tearDown [

	MMLaunchCommand app: previousApp.
	super tearDown
]

{ #category : 'tests' }
MMPackagerTest >> testIcoWrapsOnePngOf256Pixels [

	| ico |
	ico := packager icoBytesFor: #[ 1 2 3 ].
	self assert: (ico first: 6) equals: #[ 0 0 1 0 1 0 ].
	self assert: (ico copyFrom: 7 to: 8) equals: #[ 0 0 ].
	self assert: (ico copyFrom: 15 to: 18) equals: #[ 3 0 0 0 ].
	self assert: (ico copyFrom: 19 to: 22) equals: #[ 22 0 0 0 ].
	self assert: (ico last: 3) equals: #[ 1 2 3 ]
]

{ #category : 'tests' }
MMPackagerTest >> testPreparedImageOpensTheApp [

	packager prepareImage.
	self assert: MMLaunchCommand app equals: MMExampleApp.
	self assert: MMLaunchCommand commandName equals: 'mamotreto'
]

{ #category : 'tests' }
MMPackagerTest >> testPropertiesNameTheAppItsVersionAndTheLaunchCommand [

	| properties |
	properties := packager macOSProperties.
	self assert: (properties at: #AppName) equals: MMExampleApp new name.
	self assert: (properties at: #ShortVersion) equals: '1.2.3'.
	self
		assert: (properties at: #BundleIdentifier)
		equals: 'org.example.app'.
	self assert: (properties at: #CommandLineHandler) equals: 'mamotreto'.
	self assert: (properties at: #IconSetFile) extension equals: 'icns'
]

{ #category : 'tests' }
MMPackagerTest >> testWindowsMakesAZipWithAnIco [

	| properties |
	properties := packager windowsProperties.
	self assert: (properties at: #GeneratedArtifact) equals: #zip.
	self
		assert: (properties at: #ZipName)
		equals: MMExampleApp new name , '-Windows.zip'.
	self assert: (properties at: #IconFile) extension equals: 'ico'
]
