"
I am an app's preferences. Each value has a declared default (class side defaults; an app's subclass adds its own), so a file without a newer value gets its default. Each change is saved at once and reported to changedBlock with its key.
"
Class {
	#name : 'MMSettings',
	#superclass : 'MMFileService',
	#instVars : [
		'values'
	],
	#category : 'Mamotreto-Core',
	#package : 'Mamotreto-Core'
}

{ #category : 'defaults' }
MMSettings class >> defaults [
	"The shell's settings; subclasses add the app's"

	^ Dictionary new
		  at: 'appTheme' put: 'Light';
		  at: 'setupDone' put: false;
		  yourself
]

{ #category : 'accessing' }
MMSettings >> appTheme [
	"'Light' or 'Dark': the look of the whole app"

	^ self at: 'appTheme'
]

{ #category : 'accessing' }
MMSettings >> at: aKey [

	^ values at: aKey
]

{ #category : 'accessing' }
MMSettings >> at: aKey put: aValue [
	"Change one setting, save the file and report it"

	self assert: (values includesKey: aKey).
	(values at: aKey) = aValue ifTrue: [ ^ aValue ].
	values at: aKey put: aValue.
	self write: values.
	changedBlock value: aKey.
	^ aValue
]

{ #category : 'initialization' }
MMSettings >> load [
	"Older files lack the newer settings, which keep their defaults"

	changedBlock := [ :key |  ].
	values := self class defaults.
	(self readIfAbsent: [ Dictionary new ]) keysAndValuesDo: [ :key :value |
		(values includesKey: key) ifTrue: [ values at: key put: value ] ]
]
