"
I update a packaged app the way Sparkle does: the .app is never modified, a new version replaces it whole. I read the running bundle's version from its Info.plist, find newer release tags (vX.Y.Z) of the app's GitHub repository, download the release's <App>-macOS.zip next to the bundle, and start a script that waits for the app to quit, swaps the bundles and opens the new one. Outside a bundle (a development image) I offer nothing. I am made with the GitHub repository (owner/name). Tests subclass me and override my private I/O methods.
"
Class {
	#name : 'MMUpdater',
	#superclass : 'Object',
	#instVars : [
		'gitHubRepository',
		'bundle'
	],
	#category : 'Mamotreto-Core',
	#package : 'Mamotreto-Core'
}

{ #category : 'instance creation' }
MMUpdater class >> gitHubRepository: anOwnerAndName [
	"The updater of the running app, released on the GitHub repository anOwnerAndName (owner/name)"

	^ self new setGitHubRepository: anOwnerAndName
]

{ #category : 'accessing' }
MMUpdater >> assetName [
	"The release asset with the zipped bundle: Chessmate.app comes in Chessmate-macOS.zip"

	^ self bundle basenameWithoutExtension , '-macOS.zip'
]

{ #category : 'checking' }
MMUpdater >> availableUpdate [
	"The newest release tag newer than the running version, or nil. A development image, outside a bundle, or an app without releases is offered nothing."

	| current newest |
	gitHubRepository ifNil: [ ^ nil ].
	current := self currentTag ifNil: [ ^ nil ].
	(self isRelease: current) ifFalse: [ ^ nil ].
	newest := current.
	(self releaseTags select: [ :each | self isRelease: each ]) do: [
		:each |
		(self is: each newerThan: newest) ifTrue: [ newest := each ] ].
	^ newest = current
		  ifTrue: [ nil ]
		  ifFalse: [ newest ]
]

{ #category : 'accessing' }
MMUpdater >> bundle [
	"The running .app, or nil when the image is not inside one: its image is in Contents/Resources"

	^ bundle ifNil: [
			  | candidate |
			  candidate := Smalltalk imageFile asFileReference parent parent
				               parent.
			  candidate extension = 'app' ifTrue: [ bundle := candidate ].
			  bundle ]
]

{ #category : 'checking' }
MMUpdater >> currentTag [
	"The running version as a release tag (v1.2.3), or nil in a development image"

	^ self currentVersion ifNotNil: [ :version | 'v' , version ]
]

{ #category : 'private - io' }
MMUpdater >> currentVersion [
	"The running bundle's version, or nil outside a bundle"

	^ self bundle ifNotNil: [ :app |
		  self versionIn: (app / 'Contents' / 'Info.plist') contents ]
]

{ #category : 'private - io' }
MMUpdater >> download: aTagName [
	"The release's zip, in an emptied staging directory"

	| zip |
	self stagingDirectory
		ensureDeleteAll;
		ensureCreateDirectory.
	zip := self stagingDirectory / self assetName.
	ZnClient new
		url: (self downloadUrlFor: aTagName);
		enforceHttpSuccess: true;
		downloadTo: zip.
	^ zip
]

{ #category : 'accessing' }
MMUpdater >> downloadUrlFor: aTagName [

	^ 'https://github.com/{1}/releases/download/{2}/{3}' format: {
			  gitHubRepository.
			  aTagName.
			  self assetName }
]

{ #category : 'private - io' }
MMUpdater >> install: aNewBundle [
	"Start the swap script in the background; it waits for the app to quit"

	| script |
	script := self stagingDirectory / 'swap.sh'.
	script ensureDelete.
	script writeStreamDo: [ :stream | stream nextPutAll: self swapScript ].
	self run:
		'nohup /bin/sh ' , (self shellQuoted: script fullName) , ' '
		, (self shellQuoted: self bundle fullName) , ' '
		, (self shellQuoted: aNewBundle fullName) , ' >/dev/null 2>&1 &'
]

{ #category : 'private' }
MMUpdater >> is: aTagName newerThan: anotherTagName [

	| numbers others |
	numbers := self numbersOf: aTagName.
	others := self numbersOf: anotherTagName.
	1 to: 3 do: [ :index |
			(numbers at: index) = (others at: index) ifFalse: [
				^ (numbers at: index) > (others at: index) ] ].
	^ false
]

{ #category : 'testing' }
MMUpdater >> isRelease: aTagName [
	"Whether the tag looks like v1.2.3"

	^ aTagName matchesRegex: 'v\d+\.\d+\.\d+'
]

{ #category : 'private' }
MMUpdater >> numbersOf: aTagName [
	"v1.2.3 as #( 1 2 3 )"

	^ ((aTagName allButFirst substrings: '.') collect: [ :each |
		   each asInteger ]) asArray
]

{ #category : 'private - io' }
MMUpdater >> quit [
	"The bundle is read-only: nothing to save"

	Smalltalk snapshot: false andQuit: true
]

{ #category : 'private - io' }
MMUpdater >> releaseTags [
	"The tags of the repository's published releases, without drafts and pre-releases"

	| releases |
	releases := STONJSON fromString: (ZnClient new
			             url:
				             'https://api.github.com/repos/' , gitHubRepository
				             , '/releases';
			             headerAt: 'Accept' put: 'application/vnd.github+json';
			             get).
	^ (releases reject: [ :each |
		   (each at: 'draft') or: [ each at: 'prerelease' ] ]) collect: [
		  :each | each at: 'tag_name' ]
]

{ #category : 'private - io' }
MMUpdater >> run: aCommand [
	"Run a shell command and wait for it; a failure is an error"

	| status |
	status := LibC runCommand: aCommand.
	status = 0 ifFalse: [
		self error:
			'Command failed (' , status printString , '): ' , aCommand ]
]

{ #category : 'initialization' }
MMUpdater >> setGitHubRepository: anOwnerAndName [

	gitHubRepository := anOwnerAndName
]

{ #category : 'private' }
MMUpdater >> shellQuoted: aString [
	"aString as one single-quoted shell word"

	^ '''' , (aString copyReplaceAll: '''' with: '''\''''') , ''''
]

{ #category : 'accessing' }
MMUpdater >> stagingDirectory [
	"Next to the bundle, so the swap is a rename on the same volume"

	^ self bundle parent / ('.' , self bundle basename , '-update')
]

{ #category : 'private' }
MMUpdater >> swapScript [
	"Started before the app quits: replace the bundle $1 with $2 once the app is gone, put the old one back if that fails, remove the staging directory and open the app. Unix line endings: method source has CRs, which sh can't read."

	^ '#!/bin/sh
while pgrep -f "$1/Contents/MacOS/" >/dev/null; do sleep 0.2; done
mv "$1" "$1.old" || exit 1
if mv "$2" "$1"; then rm -rf "$1.old"; else mv "$1.old" "$1"; fi
rm -rf "$(dirname "$2")"
open "$1"
' withUnixLineEndings
]

{ #category : 'private - io' }
MMUpdater >> unpack: aZip [
	"The new bundle, unzipped with ditto, which keeps execute permissions and symlinks"

	| newBundle |
	self run: 'ditto -x -k ' , (self shellQuoted: aZip fullName) , ' '
		, (self shellQuoted: self stagingDirectory fullName).
	newBundle := self stagingDirectory / self bundle basename.
	newBundle exists ifFalse: [
		self error: self assetName , ' has no ' , self bundle basename ].
	^ newBundle
]

{ #category : 'updating' }
MMUpdater >> updateTo: aTagName ifFailed: aBlock [
	"Download and unpack the release, start the swap and quit: the new version opens by itself. If anything fails before quitting, evaluate aBlock with the error and keep running. Off the UI thread; the window must be closed first."

	[ self install: (self unpack: (self download: aTagName)) ]
		on: Error
		do: [ :error | ^ aBlock value: error ].
	self quit
]

{ #category : 'private' }
MMUpdater >> versionIn: anInfoPlist [
	"The CFBundleShortVersionString of an Info.plist's contents, or nil"

	| match |
	match := '<key>CFBundleShortVersionString</key>\s*<string>([^<]*)</string>'
		         asRegex.
	^ (match search: anInfoPlist)
		  ifTrue: [ (match subexpression: 2) trimBoth ]
		  ifFalse: [ nil ]
]
