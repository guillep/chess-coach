"
I find moves that lost winning chances compared with the engine's best move: a drop of 10, 20 or 30 points of win percentage is an inaccuracy, a mistake or a blunder (Lichess's thresholds).
"
Class {
	#name : 'EvaluationJumpFinder',
	#superclass : 'MomentFinder',
	#instVars : [
		'analysis'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
EvaluationJumpFinder class >> on: aGameAnalysis [

	^ self new
		  setAnalysis: aGameAnalysis;
		  yourself
]

{ #category : 'private' }
EvaluationJumpFinder >> allowsMate: mover before: before after: after [
	"Whether mover's move turned a position without a forced mate against it into one"

	| opponent |
	opponent := mover = #white
		            ifTrue: [ #black ]
		            ifFalse: [ #white ].
	^ (after bestLine isMateFor: opponent) and: [
		  (before bestLine isMateFor: opponent) not ]
]

{ #category : 'private' }
EvaluationJumpFinder >> kindForDrop: aNumber [

	aNumber >= (self threshold: 'momentBlunderDrop') ifTrue: [ ^ #blunder ].
	aNumber >= (self threshold: 'momentMistakeDrop') ifTrue: [ ^ #mistake ].
	aNumber >= (self threshold: 'momentInaccuracyDrop') ifTrue: [ ^ #inaccuracy ].
	^ nil
]

{ #category : 'finding' }
EvaluationJumpFinder >> moments [

	^ (1 to: analysis moveCount)
		  inject: OrderedCollection new
		  into: [ :moments :ply |
				  | before after mover drop |
				  before := analysis atPly: ply - 1.
				  after := analysis atPly: ply.
				  (before lines notEmpty and: [ after lines notEmpty ]) ifTrue: [
						  mover := before sideToMove.
						  drop := (before winPercentFor: mover)
						          - (after winPercentFor: mover).
						  ((self allowsMate: mover before: before after: after)
							   ifTrue: [ #blunder ]
							   ifFalse: [ self kindForDrop: drop ]) ifNotNil: [ :kind |
								  moments add: (ChessMoment
										   ply: ply
										   color: mover
										   kind: kind
										   source: #engine
										   note: (self noteBefore: before after: after for: mover)) ] ].
				  moments ]
]

{ #category : 'private' }
EvaluationJumpFinder >> noteBefore: before after: after for: aColor [

	^ 'Win chance went from {1}% to {2}% ({3} → {4}); best was {5}'
		  format: {
				  ((before winPercentFor: aColor) printShowingDecimalPlaces: 0).
				  ((after winPercentFor: aColor) printShowingDecimalPlaces: 0).
				  before bestLine scoreString.
				  after bestLine scoreString.
				  (before sanOf: before bestLine firstMove) }
]

{ #category : 'initialization' }
EvaluationJumpFinder >> setAnalysis: aGameAnalysis [

	analysis := aGameAnalysis
]
