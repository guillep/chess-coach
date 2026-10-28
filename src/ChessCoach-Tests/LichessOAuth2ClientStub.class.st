"
I log in immediately with a fixed token, without a browser or network.
"
Class {
	#name : 'LichessOAuth2ClientStub',
	#superclass : 'LichessOAuth2Client',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'oauth2' }
LichessOAuth2ClientStub >> authenticate [

	accessToken := 'test-token'.
	self saveTokenToFile.
	^ accessToken
]
