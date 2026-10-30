Class {
	#name : 'MistakeDatabaseTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
MistakeDatabaseTest >> record: aGameId date: aDate phase: aPhase tags: someTagIds [

	^ MistakeRecord new
		  gameId: aGameId;
		  ply: 10;
		  date: aDate;
		  phase: aPhase;
		  playedMove: 'e2e4';
		  bestMove: 'd2d4';
		  winDrop: 25;
		  labels:
			  (someTagIds collect: [ :each |
					   MistakeLabel tagId: each confidence: 1 ]);
		  yourself
]

{ #category : 'tests' }
MistakeDatabaseTest >> testAFileFromBeforeFormatVersionsStillLoads [

	self assert: (MistakeDatabase fromJSON: '[]') records isEmpty.
	self assert:
		(MistakeDatabase fromJSON:
			 (MistakeDatabase withRecords: #(  )) asJSON) records isEmpty
]

{ #category : 'tests' }
MistakeDatabaseTest >> testQueries [

	| database |
	database := MistakeDatabase withRecords: {
			            (self
				             record: 'b'
				             date: (Date year: 2026 month: 10 day: 2)
				             phase: 'endgame'
				             tags: #( 'hope-chess' 'clock-management' )).
			            (self
				             record: 'a'
				             date: (Date year: 2026 month: 9 day: 30)
				             phase: 'opening'
				             tags: #( 'hope-chess' )).
			            (self
				             record: 'c'
				             date: (Date year: 2026 month: 10 day: 5)
				             phase: 'endgame'
				             tags: #( 'endgame-technique' )) }.
	self
		assert: (database records collect: [ :each | each gameId ]) asArray
		equals: #( 'a' 'b' 'c' ).
	self assert: database tagFrequencies keys first equals: 'hope-chess'.
	self assert: (database tagFrequencies at: 'hope-chess') equals: 2.
	self
		assert:
		((database tagFrequenciesByPhase at: 'endgame') at:
			 'clock-management')
		equals: 1.
	self
		assert: database tagFrequenciesByMonth keys asArray
		equals: #( '2026-09' '2026-10' ).
	self assert: (database tagFrequenciesByGames: 2) size equals: 2.
	self
		assert: ((database tagFrequenciesByGames: 2) first at: 'hope-chess')
		equals: 2.
	self assert: (database recordsWithTag: 'hope-chess') size equals: 2.
	self
		assert:
			((MistakeDatabase fromJSON: database asJSON) records collect: [
				 :each | each asDictionary ])
		equals: (database records collect: [ :each | each asDictionary ])
]
