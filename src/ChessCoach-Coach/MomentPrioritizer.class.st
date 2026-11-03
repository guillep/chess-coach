"
Scores moments by importance from the engine analysis: the mover's win-% drop, plus the gap to the second line for a missed only move, plus 20 when the move crossed the 70 % or 30 % line. Opening choices and found only moves get a fixed score. Marked moments are always selected.
"
Class {
	#name : 'MomentPrioritizer',
	#superclass : 'Object',
	#instVars : [
		'analysis'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'instance creation' }
MomentPrioritizer class >> on: aGameAnalysis [

	^ self new setAnalysis: aGameAnalysis
]

{ #category : 'scoring' }
MomentPrioritizer >> byImportance: someMoments [
	"Marked moments first (in game order), then the others by decreasing score"

	| marked others |
	marked := someMoments select: [ :each | each isMarked ].
	others := someMoments reject: [ :each | each isMarked ].
	^ (marked asArray sort: [ :a :b | a ply < b ply ])
	  ,
	  (others asArray sort: [ :a :b |
		   (self scoreOf: a) > (self scoreOf: b) ])
]

{ #category : 'scoring' }
MomentPrioritizer >> scoreOf: aMoment [
	"Blunders first, then mistakes (a missed only move counts as one), then inaccuracies; within a kind, the larger drop in pawns first (capped at 10 pawns, so that a mate doesn't hide everything else). Opening choices and found only moves score at least as a small drop."

	| before after mover drop severity score |
	severity := aMoment kinds inject: 0 into: [ :max :kind |
			            max max:
				            (#( #inaccuracy #mistake #blunder ) indexOf:
					             (kind = #onlyMoveMissed
						              ifTrue: [ #mistake ]
						              ifFalse: [ kind ])) ].
	before := analysis atPly: aMoment ply - 1.
	after := analysis atPly: aMoment ply.
	mover := aMoment color.
	drop := (before lines isEmpty or: [ after lines isEmpty ])
		        ifTrue: [ 0 ]
		        ifFalse: [
				        ((before bestLine pawnsFor: mover)
				         - (after bestLine pawnsFor: mover) max: 0) min: 10 ].
	score := severity * 100 + (drop * 9).
	(aMoment kinds includesAny: #( #openingChoice #onlyMoveFound ))
		ifTrue: [ score := score max: 10 ].
	^ score
]

{ #category : 'initialization' }
MomentPrioritizer >> setAnalysis: aGameAnalysis [

	analysis := aGameAnalysis
]
