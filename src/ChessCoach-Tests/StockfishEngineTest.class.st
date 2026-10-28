Class {
	#name : 'StockfishEngineTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
StockfishEngineTest >> testParsesMatedPosition [

	| lines |
	lines := Dictionary new.
	StockfishEngine new
		parseInfo: 'info depth 0 score mate 0'
		sideToMove: #white
		into: lines.
	self assert: (lines at: 1) moves isEmpty.
	self assert: ((lines at: 1) winPercentFor: #black) equals: 100.
	self assert: ((lines at: 1) isMateFor: #black)
]

{ #category : 'tests' }
StockfishEngineTest >> testParsesMultiPVInfoFromBlacksPointOfView [

	| lines |
	lines := Dictionary new.
	StockfishEngine new
		parseInfo:
		'info depth 18 seldepth 25 multipv 2 score cp -31 nodes 1 pv e7e5 g1f3'
		sideToMove: #black
		into: lines.
	self assert: (lines at: 2) moves equals: #( 'e7e5' 'g1f3' ).
	self assert: (lines at: 2) scoreString equals: '+0.31'.
	self assert: ((lines at: 2) winPercentFor: #white) > 50
]

{ #category : 'tests' }
StockfishEngineTest >> testWinPercentMatchesLichess [

	self assert: (EngineLine winPercentForCentipawns: 0) equals: 50.
	self
		assert: ((EngineLine winPercentForCentipawns: 100) roundTo: 0.1)
		equals: 59.1
]
