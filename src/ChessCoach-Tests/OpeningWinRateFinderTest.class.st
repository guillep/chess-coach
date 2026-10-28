Class {
	#name : 'OpeningWinRateFinderTest',
	#superclass : 'TestCase',
	#instVars : [
		'game',
		'explorer'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
OpeningWinRateFinderTest >> fenAfter: aPly [

	^ (game positionAfterPly: aPly) fen
]

{ #category : 'helpers' }
OpeningWinRateFinderTest >> momentsFor: someColors [

	^ (OpeningWinRateFinder
		   game: game
		   explorer: explorer
		   colors: someColors) moments
]

{ #category : 'running' }
OpeningWinRateFinderTest >> setUp [

	super setUp.
	game := PGNParser new parse: '[WhiteElo "1500"]
[BlackElo "1550"]
[TimeControl "180+2"]

1. e4 e5 2. Nf3 Nc6'.
	explorer := LichessExplorerClientStub new
]

{ #category : 'tests' }
OpeningWinRateFinderTest >> testLowerScoringMoveIsAMoment [
	"e4 scores 58% for White here, d4 69%"

	| moments |
	explorer
		at: (self fenAfter: 0)
		moves: #( #( 'e4' 300 100 200 ) #( 'd4' 250 50 100 ) ).
	explorer at: (self fenAfter: 2) moves: #( #( 'Nf3' 300 100 200 ) ).
	moments := self momentsFor: #( #white ).
	self assert: moments size equals: 1.
	self assert: moments first ply equals: 1.
	self assert: (moments first kinds includes: #openingChoice).
	self assert:
		(moments first notes first includesSubstring: 'd4 (69%)')
]

{ #category : 'tests' }
OpeningWinRateFinderTest >> testOnlyAsksForMyMovesAtMyRatingAndSpeed [

	explorer at: (self fenAfter: 0) moves: #( #( 'e4' 300 100 200 ) ).
	explorer at: (self fenAfter: 2) moves: #( #( 'Nf3' 300 100 200 ) ).
	self assert: (self momentsFor: #( #white )) isEmpty.
	self
		assert: (explorer requests collect: [ :each | each first ]) asArray
		equals: {
				(self fenAfter: 0).
				(self fenAfter: 2) }.
	self assert: explorer requests first second equals: 'blitz'.
	self
		assert: explorer requests first third asArray
		equals: #( 1200 1400 1600 )
]

{ #category : 'tests' }
OpeningWinRateFinderTest >> testRareMoveIsAMoment [

	| moments |
	explorer
		at: (self fenAfter: 0)
		moves: #( #( 'd4' 250 50 100 ) #( 'e4' 10 5 10 ) ).
	moments := self momentsFor: #( #white ).
	self assert: moments size equals: 1.
	self assert: (moments first notes first includesSubstring: 'rarely')
]

{ #category : 'tests' }
OpeningWinRateFinderTest >> testStopsWhenThePositionHasFewGames [

	explorer at: (self fenAfter: 0) moves: #( #( 'e4' 10 5 10 ) ).
	self assert: (self momentsFor: #( #white )) isEmpty.
	self assert: explorer requests size equals: 1
]
