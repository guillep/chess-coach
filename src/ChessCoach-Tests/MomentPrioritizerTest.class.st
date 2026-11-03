Class {
	#name : 'MomentPrioritizerTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
MomentPrioritizerTest >> testByImportance [

	| analysis moments ordered prioritizer |
	"Engine lines per position, White's centipawns. Ply 1: a mistake, White +0.50 -> -1.00 (200 + 1.5 pawns x 9).
	Ply 4: an opening choice that lost nothing (at least 10). Ply 5: White misses the only move, +3.00 -> -1.00, counted as a mistake (200 + 4 x 9). My marks come first."
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
	self assert: (prioritizer scoreOf: moments first) equals: 213.5.
	self assert: (prioritizer scoreOf: moments third) equals: 36.
	self assert: (prioritizer scoreOf: moments fourth) equals: 236.
	ordered := prioritizer byImportance: moments.
	self
		assert: (ordered collect: [ :each | each ply ]) asArray
		equals: #( 2 5 1 4 )
]
