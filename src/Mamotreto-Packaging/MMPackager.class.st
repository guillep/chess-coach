"
I package a Mamotreto app with PharoApplicationGenerator. A build script loads the app, gives me the app class, its version (1.2.3), a bundle identifier and a square PNG icon, then calls #prepareImage, saves the image and calls #generateMacOS or #generateWindows; PharoApplicationGenerator's scripts in my output directory build the .app or the Windows zip. I make the icons from the PNG: an .icns with sips and iconutil on macOS, an .ico in Smalltalk for Windows.
"
Class {
	#name : 'MMPackager',
	#superclass : 'Object',
	#instVars : [
		'app',
		'version',
		'bundleIdentifier',
		'iconPng',
		'outputDirectory'
	],
	#category : 'Mamotreto-Packaging',
	#package : 'Mamotreto-Packaging'
}

{ #category : 'accessing' }
MMPackager >> app: anAppClass [

	app := anAppClass
]

{ #category : 'accessing' }
MMPackager >> appName [

	^ app new name
]

{ #category : 'accessing' }
MMPackager >> bundleIdentifier: aString [
	"Reverse DNS, org.example.app"

	bundleIdentifier := aString
]

{ #category : 'properties' }
MMPackager >> commonProperties [
	"What PharoApplicationGenerator needs on every platform"

	^ Dictionary new
		  at: #AppName put: self appName;
		  at: #DisplayName put: self appName;
		  at: #InfoString put: self appName;
		  at: #BundleIdentifier put: bundleIdentifier;
		  at: #ShortVersion put: version;
		  at: #Version put: version;
		  at: #CommandLineHandler put: MMLaunchCommand commandName;
		  yourself
]

{ #category : 'packaging' }
MMPackager >> generateMacOS [
	"Write the icon and PharoApplicationGenerator's macOS project; its build.sh then makes the .app"

	outputDirectory ensureCreateDirectory.
	self writeIcns.
	AppGeneratorOSXGenerator new
		properties: self macOSProperties;
		outputDirectory: outputDirectory;
		generate
]

{ #category : 'packaging' }
MMPackager >> generateWindows [
	"Write the icon and PharoApplicationGenerator's Windows project; CMake and its buildZip.ps1 then make the zip"

	outputDirectory ensureCreateDirectory.
	self writeIco.
	AppGeneratorWindowsGenerator new
		properties: self windowsProperties;
		outputDirectory: outputDirectory;
		generate
]

{ #category : 'icons' }
MMPackager >> icnsFile [

	^ outputDirectory parent / (self appName , '.icns')
]

{ #category : 'icons' }
MMPackager >> icoBytesFor: aPngByteArray [
	"An .ico holding one 256 px PNG image, which Windows reads since Vista: a 6-byte header, one 16-byte entry (0 means 256), then the PNG"

	^ ByteArray streamContents: [ :stream |
			  #( 0 0 1 0 1 0 ) do: [ :each | stream nextPut: each ].
			  #( 0 0 0 0 1 0 32 0 ) do: [ :each | stream nextPut: each ].
			  stream nextPutAll:
				  (aPngByteArray size asByteArrayOfSize: 4) reversed.
			  stream nextPutAll: (22 asByteArrayOfSize: 4) reversed.
			  stream nextPutAll: aPngByteArray ]
]

{ #category : 'icons' }
MMPackager >> icoFile [

	^ outputDirectory parent / (self appName , '.ico')
]

{ #category : 'accessing' }
MMPackager >> iconPng: aFileReference [
	"A square PNG, ideally 1024 px"

	iconPng := aFileReference asFileReference
]

{ #category : 'properties' }
MMPackager >> macOSProperties [

	^ self commonProperties
		  at: #IconSetFile put: self icnsFile;
		  yourself
]

{ #category : 'accessing' }
MMPackager >> outputDirectory: aFileReference [
	"Where PharoApplicationGenerator writes its build scripts and the app"

	outputDirectory := aFileReference asFileReference
]

{ #category : 'packaging' }
MMPackager >> prepareImage [
	"Make the image open the app when the launcher starts it; the build saves the image afterwards"

	MMLaunchCommand app: app
]

{ #category : 'icons' }
MMPackager >> resize: aSize to: aPngFile [

	self run: ('sips -z {1} {1} {2} --out {3} >/dev/null' format: {
				 aSize.
				 (self shellQuoted: iconPng fullName).
				 (self shellQuoted: aPngFile fullName) })
]

{ #category : 'private' }
MMPackager >> run: aCommand [
	"Run a shell command and wait for it; a failure is an error"

	| status |
	status := LibC runCommand: aCommand.
	status = 0 ifFalse: [
		self error:
			'Command failed (' , status printString , '): ' , aCommand ]
]

{ #category : 'private' }
MMPackager >> shellQuoted: aString [
	"aString as one single-quoted shell word"

	^ '''' , (aString copyReplaceAll: '''' with: '''\''''') , ''''
]

{ #category : 'accessing' }
MMPackager >> version: aString [
	"Three numbers, 1.2.3: the bundle's version, which the updater compares with release tags v1.2.3"

	version := aString
]

{ #category : 'properties' }
MMPackager >> windowsProperties [
	"A zip rather than an installer: PharoApplicationGenerator's installer needs Advanced Installer"

	^ self commonProperties
		  at: #IconFile put: self icoFile;
		  at: #GeneratedArtifact put: #zip;
		  at: #ZipName put: self appName , '-Windows.zip';
		  at: #CompanyName put: self appName;
		  at: #LegalCopyright put: self appName;
		  yourself
]

{ #category : 'icons' }
MMPackager >> writeIcns [
	"The macOS icon set, made with sips and iconutil from the PNG"

	| set |
	set := outputDirectory parent / (self appName , '.iconset').
	set
		ensureDeleteAll;
		ensureCreateDirectory.
	#( 16 32 128 256 512 ) do: [ :size |
			self resize: size to: set / ('icon_{1}x{1}.png' format: { size }).
			self
				resize: size * 2
				to: set / ('icon_{1}x{1}@2x.png' format: { size }) ].
	self run:
		'iconutil -c icns ' , (self shellQuoted: set fullName) , ' -o '
		, (self shellQuoted: self icnsFile fullName)
]

{ #category : 'icons' }
MMPackager >> writeIco [
	"The icon at 256 px, scaled in Smalltalk so it works on Windows too"

	| form png |
	form := (ImageReadWriter formFromFileNamed: iconPng fullName)
		        scaledToSize: 256 @ 256.
	png := ByteArray streamContents: [ :stream |
		       PNGReadWriter putForm: form onStream: stream ].
	self icoFile ensureDelete.
	self icoFile binaryWriteStreamDo: [ :stream |
		stream nextPutAll: (self icoBytesFor: png) ]
]
