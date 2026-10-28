Class {
	#name : 'LichessAPIClientTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
LichessAPIClientTest >> testUserGamesUrlPagesWithUntil [

	| url |
	url := LichessAPIClient new
		       userGamesUrl: 'tester'
		       max: 20
		       until: 1234
		       since: nil.
	self assert: url path equals: 'api/games/user/tester'.
	self assert: (url queryAt: 'max') equals: '20'.
	self assert: (url queryAt: 'until') equals: '1234'.
	self assert: (url queryAt: 'pgnInJson') equals: 'true'.
	self deny: (url hasQuery and: [ url query includesKey: 'since' ])
]
