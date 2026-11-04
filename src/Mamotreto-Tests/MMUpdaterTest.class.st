"
I test finding and installing updates without git or saving the image.
"
Class {
	#name : 'MMUpdaterTest',
	#superclass : 'TestCase',
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'tests' }
MMUpdaterTest >> testADevelopmentImageOrAnUnreleasedAppIsOfferedNothing [

	self assert: (MMUpdater gitHubRepository: 'owner/app') bundle isNil.
	self assert:
		(MMUpdater gitHubRepository: 'owner/app') availableUpdate isNil.
	self assert: (MMUpdaterStub new
			 current: 'v1.0.0' tags: #( 'v2.0.0' ) failure: nil;
			 setGitHubRepository: nil;
			 availableUpdate) isNil
]

{ #category : 'tests' }
MMUpdaterTest >> testAFailedUpdateReportsAndKeepsRunning [

	| updater result |
	updater := MMUpdaterStub new
		           current: 'v1.1.1' tags: #(  ) failure: 'no network';
		           yourself.
	updater updateTo: 'v1.2.0' ifFailed: [ :error | result := error ].
	self assert: result messageText equals: 'no network'.
	self assert: updater log isEmpty
]

{ #category : 'tests' }
MMUpdaterTest >> testAvailableUpdateIsTheNewestNewerRelease [

	self
		assert: (MMUpdaterStub new
				 current: 'v1.1.1'
				 tags: #( 'v1.0.0' 'v1.1.1' 'v1.2.0' 'v1.10.0' 'wip' )
				 failure: nil;
				 availableUpdate)
		equals: 'v1.10.0'.
	self assert: (MMUpdaterStub new
			 current: 'v1.1.1' tags: #( 'v1.0.0' 'v1.1.1' ) failure: nil;
			 availableUpdate) isNil.
	self assert: (MMUpdaterStub new
			 current: nil tags: #( 'v9.0.0' ) failure: nil;
			 availableUpdate) isNil
]

{ #category : 'tests' }
MMUpdaterTest >> testShellQuotingKeepsPathsAsOneWord [

	| updater |
	updater := MMUpdater gitHubRepository: 'owner/app'.
	self
		assert: (updater shellQuoted: '/Applications/My App.app')
		equals: '''/Applications/My App.app'''.
	self assert: (updater shellQuoted: 'it''s') equals: '''it''\''''s'''
]

{ #category : 'tests' }
MMUpdaterTest >> testSwapScriptWaitsReplacesAndReopens [

	| source script |
	source := (MMUpdater gitHubRepository: 'owner/app') swapScript.
	self deny: (source includes: Character cr).
	script := source lines.
	self assert: (script second includesSubstring: 'pgrep').
	self assert: (script includes: 'mv "$1" "$1.old" || exit 1').
	self assert: (script last includesSubstring: 'open "$1"')
]

{ #category : 'tests' }
MMUpdaterTest >> testUpdateInstallsTheReleaseThenQuits [

	| updater result |
	updater := MMUpdaterStub new
		           current: 'v1.1.1' tags: #(  ) failure: nil;
		           yourself.
	result := #unset.
	updater updateTo: 'v1.2.0' ifFailed: [ :error | result := error ].
	self assert: result equals: #unset.
	self
		assert: updater log asArray
		equals: { 'v1.2.0'. #zip. #bundle. #quit }
]

{ #category : 'tests' }
MMUpdaterTest >> testVersionIsReadFromTheInfoPlist [

	| updater |
	updater := MMUpdater gitHubRepository: 'owner/app'.
	self
		assert: (updater versionIn: '<dict>
	<key>CFBundleName</key>
	<string>App</string>
	<key>CFBundleShortVersionString</key>
	<string>1.4.2</string>
</dict>')
		equals: '1.4.2'.
	self assert: (updater versionIn: '<dict></dict>') isNil
]
