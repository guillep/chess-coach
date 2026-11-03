Class {
	#name : 'EvaluationFormatTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
EvaluationFormatTest >> testPawnsAndWinPercent [

	| line mate pawns percent |
	line := EngineLine
		        moves: #( 'e2e4' )
		        centipawns: 180
		        sideToMove: #white.
	mate := EngineLine moves: #( 'd8h4' ) mate: 1 sideToMove: #black.
	pawns := EvaluationFormat pawns.
	percent := EvaluationFormat unit: 'winPercent'.
	self assert: (pawns line: line for: #white) equals: '+1.80'.
	self assert: (pawns line: line for: #black) equals: '-1.80'.
	self assert: (pawns line: mate for: #black) equals: '#1'.
	self assert: (pawns line: mate for: #white) equals: '#-1'.
	self assert: (percent line: line for: #white) equals: '66%'.
	self assert: (percent winPercent: 50) equals: '50%'.
	self assert: (pawns winPercent: 50) equals: '+0.00'.
	self
		assert: (pawns winPercent: (line winPercentFor: #white))
		equals: '+1.80'
]
