"
Answers NDJSON as bytes, the way Zinc does for application/x-ndjson.
"
Class {
	#name : 'LichessAPIClientBytesStub',
	#superclass : 'LichessAPIClient',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'private' }
LichessAPIClientBytesStub >> get: aZnUrl accept: aMimeTypeString [

	^ '{"id":"a1","name":"Gö"}
{"id":"a2"}
' utf8Encoded
]
