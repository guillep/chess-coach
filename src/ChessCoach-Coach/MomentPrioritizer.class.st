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

{ #category : 'private' }
MomentPrioritizer >> crossedOutcome: aWinPercent to: anotherWinPercent [
	"Whether the move turned a win into a non-win, or a non-loss into a loss"

	^ (aWinPercent >= 70 and: [ anotherWinPercent < 70 ]) or: [
		  aWinPercent > 30 and: [ anotherWinPercent <= 30 ] ]
]

{ #category : 'scoring' }
MomentPrioritizer >> scoreOf: aMoment [

	| before after mover drop score |
	before := analysis atPly: aMoment ply - 1.
	after := analysis atPly: aMoment ply.
	(before lines isEmpty or: [ after lines isEmpty ]) ifTrue: [ ^ 0 ].
	mover := aMoment color.
	drop := (before winPercentFor: mover) - (after winPercentFor: mover)
		        max: 0.
	score := drop.
	((aMoment kinds includes: #onlyMoveMissed) and: [
		 before lines size > 1 ]) ifTrue: [
			score := score + ((before lines first winPercentFor: mover)
			          - (before lines second winPercentFor: mover)) ].
	(self
		 crossedOutcome: (before winPercentFor: mover)
		 to: (after winPercentFor: mover)) ifTrue: [ score := score + 20 ].
	(aMoment kinds includesAny: #( #openingChoice #onlyMoveFound ))
		ifTrue: [ score := score max: 10 ].
	^ score
]

{ #category : 'initialization' }
MomentPrioritizer >> setAnalysis: aGameAnalysis [

	analysis := aGameAnalysis
]
