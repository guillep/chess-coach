"
I am the abstract base of tests that need an open Bloc space. I give each test an open `space` on the headless host and close every space the test leaves open.

## Design Rationale

- Bloc 3 runs spaces on a real, supervised pulse loop. A space a test forgets keeps pulsing forever, and whatever it holds (a `BlDevScripter` event list, for example) keeps growing.
- `runCase` closes every space the test opened on my `host`, not only `space`: scripters open their own spaces.
- I reimplement the pattern of Bloc's `BlSpaceTestCase` so the tests do not depend on Bloc's test packages.
- Closing errors are not caught: a space that cannot close is a failure to see.

## Invariants and Assumptions

- The spaces a test opens live on my `host`, `BlHeadlessHost default`.
- After a run, the host holds the same spaces as before it.
"
Class {
	#name : 'MMSpaceTestCase',
	#superclass : 'TestCase',
	#instVars : [
		'space'
	],
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'testing' }
MMSpaceTestCase class >> isAbstract [

	^ self == MMSpaceTestCase
]

{ #category : 'accessing' }
MMSpaceTestCase >> host [

	^ BlHeadlessHost default
]

{ #category : 'running' }
MMSpaceTestCase >> runCase [

	| initialSpaces |
	initialSpaces := self host spaces copy.
	^ [ super runCase ] ensure: [
			  self host spaces copy reject: [ :each | initialSpaces includes: each ] thenDo: [ :each |
					  each close.
					  each settle ] ]
]

{ #category : 'running' }
MMSpaceTestCase >> setUp [

	super setUp.
	space := BlSpace new.
	space host: self host.
	space open.
	space settle
]

{ #category : 'accessing' }
MMSpaceTestCase >> space [

	^ space
]

{ #category : 'running' }
MMSpaceTestCase >> tearDown [

	space ifNotNil: [
			space close.
			space settle.
			space := nil ].
	super tearDown
]
