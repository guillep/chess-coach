"
I am errors.log in an app's data directory: the errors the app showed instead of opening a debugger, newest last, each with its stack, for bug reports.
"
Class {
	#name : 'MMErrorLog',
	#superclass : 'Object',
	#instVars : [
		'file'
	],
	#category : 'Mamotreto-Core',
	#package : 'Mamotreto-Core'
}

{ #category : 'instance creation' }
MMErrorLog class >> onFile: aFileReference [

	^ self new setFile: aFileReference
]

{ #category : 'logging' }
MMErrorLog >> log: anError [
	"Append anError with its stack"

	| stack |
	stack := String streamContents: [ :stream |
			         anError signalerContext ifNotNil: [ :context |
					         context stack do: [ :each |
							         stream
								         print: each;
								         cr ] ] ].
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream |
			stream
				setToEnd;
				nextPutAll: '--- ';
				nextPutAll: DateAndTime now printString;
				nextPutAll: ' ';
				nextPutAll: anError class name;
				nextPutAll: ': ';
				nextPutAll: (anError messageText ifNil: [ '' ]) asString;
				lf;
				nextPutAll: stack;
				lf ]
]

{ #category : 'initialization' }
MMErrorLog >> setFile: aFileReference [

	file := aFileReference
]
