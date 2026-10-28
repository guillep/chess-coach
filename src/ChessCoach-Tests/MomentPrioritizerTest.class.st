Class {
	#name : 'MomentPrioritizerTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
MomentPrioritizerTest >> testByImportance [

	| analysis moments ordered prioritizer |
	"Engine lines per position, White's centipawns. Ply 1: White 55% -> 41%, no line crossed (14).
	Ply 4: Black 59% -> 25%, crosses 30% (34 + 20). Ply 5: White misses the only move, 75% -> 41%,
	crosses 70% (34 + gap 34 + 20)."
	analysis := GameAnalysis
		            depth: 18
		            plies:
			            (#( #( 50 ) #( -100 ) #( -100 ) #( -100 ) #( 300 -100 )
			                #( -100 ) #( -100 ) ) withIndexCollect: [
					             :scores
					             :index |
					             PlyAnalysis
						             ply: index - 1
						             fen: '8/8/8/8/8/8/8/8 ' , (index odd
								              ifTrue: [ 'w' ]
								              ifFalse: [ 'b' ]) , ' - - 0 1'
						             lines: (scores collect: [ :cp |
								              EngineLine
									              moves: #( 'a2a3' )
									              centipawns: cp
									              sideToMove: #white ]) ]).
	moments := {
		           (ChessMoment
			            ply: 1
			            color: #white
			            kind: #mistake
			            source: #engine
			            note: nil).
		           (ChessMoment
			            ply: 2
			            color: #black
			            kind: #marked
			            source: #marks
			            note: nil).
		           (ChessMoment
			            ply: 4
			            color: #black
			            kind: #openingChoice
			            source: #explorer
			            note: nil).
		           (ChessMoment
			            ply: 5
			            color: #white
			            kind: #onlyMoveMissed
			            source: #engine
			            note: nil) }.
	prioritizer := MomentPrioritizer on: analysis.
	self assert:
		((prioritizer scoreOf: moments first) between: 13 and: 15).
	self assert:
		((prioritizer scoreOf: moments third) between: 53 and: 55).
	self assert:
		((prioritizer scoreOf: moments fourth) between: 87 and: 90).
	ordered := prioritizer byImportance: moments.
	self
		assert: (ordered collect: [ :each | each ply ]) asArray
		equals: #( 2 5 4 1 )
]
