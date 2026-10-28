"
Answers canned JSON per URL instead of calling Chess.com.
"
Class {
	#name : 'ChessComAPIClientStub',
	#superclass : 'ChessComAPIClient',
	#instVars : [
		'responses',
		'requests'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'accessing' }
ChessComAPIClientStub >> at: aUrl answer: aDictionary [

	responses at: aUrl put: aDictionary
]

{ #category : 'private' }
ChessComAPIClientStub >> getJSON: aUrl [
	"Unknown URLs answer 404, like Chess.com does for unknown players"

	requests add: aUrl.
	^ responses at: aUrl ifAbsent: [
			  (ZnHttpUnsuccessful response:
				   (ZnResponse statusLine: (ZnStatusLine code: 404))) signal ]
]

{ #category : 'initialization' }
ChessComAPIClientStub >> initialize [

	super initialize.
	responses := Dictionary new.
	requests := OrderedCollection new
]

{ #category : 'accessing' }
ChessComAPIClientStub >> requests [

	^ requests
]
