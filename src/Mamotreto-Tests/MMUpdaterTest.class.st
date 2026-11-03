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
MMUpdaterTest >> testAFailedUpdateReportsAndDoesNotSave [

	| updater result |
	updater := MMUpdaterStub new
		           current: 'v1.1.1' tags: #(  ) failure: 'no network';
		           yourself.
	updater updateTo: 'v1.2.0' thenDo: [ :error | result := error ].
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
MMUpdaterTest >> testUpdateChecksOutThenSaves [

	| updater result |
	updater := MMUpdaterStub new
		           current: 'v1.1.1' tags: #(  ) failure: nil;
		           yourself.
	result := #unset.
	updater updateTo: 'v1.2.0' thenDo: [ :error | result := error ].
	self assert: result isNil.
	self
		assert: updater log asArray
		equals: { 'v1.2.0'. #baseline. #saved }
]
