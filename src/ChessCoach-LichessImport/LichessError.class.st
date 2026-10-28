"
I am signalled when a request to Lichess fails. When the failure is an HTTP error I hold the response.
"
Class {
	#name : 'LichessError',
	#superclass : 'Error',
	#instVars : [
		'response'
	],
	#category : 'ChessCoach-LichessImport',
	#package : 'ChessCoach-LichessImport'
}

{ #category : 'signalling' }
LichessError class >> signalForResponse: aZnResponse [

	^ self new
		  response: aZnResponse;
		  signal:
			  'Lichess request failed: ' , aZnResponse status printString , ' '
			  , aZnResponse statusLine reason
]

{ #category : 'accessing' }
LichessError >> response [

	^ response
]

{ #category : 'accessing' }
LichessError >> response: aZnResponse [

	response := aZnResponse
]
