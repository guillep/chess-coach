"
I update the app from the release tags (vX.Y.Z) of the chess-coach repository: I find a newer tag, check it out, save the image and open a new window. Tests subclass me and override my private I/O methods.
"
Class {
	#name : 'ChessCoachUpdater',
	#superclass : 'Object',
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'checking' }
ChessCoachUpdater >> availableUpdate [
	"The newest release tag newer than the checked-out code, or nil. Without a current tag nothing is offered: it is a development checkout."

	| current newest |
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

{ #category : 'private - io' }
ChessCoachUpdater >> checkOut: aRevision [
	"Load a tag, branch or commit hash. Uncommitted changes in the image would be lost, so they stop the update."

	self repository isModified ifTrue: [
		self error: 'The image has uncommitted changes' ].
	self repository fetch.
	(self repository commitishNamed: aRevision) checkout
]

{ #category : 'private - io' }
ChessCoachUpdater >> currentTag [
	"The nearest tag in the history of the checked-out commit, or nil"

	self repository ifNil: [ ^ nil ].
	self repository head commit commitsDo: [ :commit |
		commit tags ifNotEmpty: [ :tags | ^ tags first name ] ].
	^ nil
]

{ #category : 'private' }
ChessCoachUpdater >> is: aTagName newerThan: anotherTagName [

	| numbers others |
	numbers := self numbersOf: aTagName.
	others := self numbersOf: anotherTagName.
	1 to: 3 do: [ :index |
			(numbers at: index) = (others at: index) ifFalse: [
				^ (numbers at: index) > (others at: index) ] ].
	^ false
]

{ #category : 'testing' }
ChessCoachUpdater >> isRelease: aTagName [
	"Whether the tag looks like v1.2.3"

	^ aTagName matchesRegex: 'v\d+\.\d+\.\d+'
]

{ #category : 'private - io' }
ChessCoachUpdater >> loadBaseline [
	"Load the checked-out baseline, for new packages and dependencies"

	Metacello new
		baseline: 'ChessCoach';
		repository: 'tonel://' , (self repository location / 'src') fullName;
		onConflictUseIncoming;
		onUpgrade: [ :upgrade | upgrade useIncoming ];
		load
]

{ #category : 'private' }
ChessCoachUpdater >> numbersOf: aTagName [
	"v1.2.3 as #( 1 2 3 )"

	^ ((aTagName allButFirst substrings: '.') collect: [ :each |
		   each asInteger ]) asArray
]

{ #category : 'private - io' }
ChessCoachUpdater >> releaseTags [
	"The names of the repository's tags, after fetching them"

	self repository ifNil: [ ^ #(  ) ].
	self repository fetch.
	^ self repository tags collect: [ :each | each name ]
]

{ #category : 'private - io' }
ChessCoachUpdater >> repository [
	"The app's repository, or nil when it isn't registered"

	^ IceRepository registry
		  detect: [ :each | each name = 'chess-coach' ]
		  ifNone: [ nil ]
]

{ #category : 'private - io' }
ChessCoachUpdater >> saveImage [

	Smalltalk snapshot: true andQuit: false
]

{ #category : 'updating' }
ChessCoachUpdater >> updateTo: aTagName thenDo: aBlock [
	"Load the tag and its baseline and, only if that worked, save the image. Then evaluate aBlock with nil, or with the error if it failed. Off the UI thread; the window must be closed first."

	[
		self checkOut: aTagName.
		self loadBaseline.
		self saveImage.
		aBlock value: nil ]
		on: Error
		do: [ :error | aBlock value: error ]
]
