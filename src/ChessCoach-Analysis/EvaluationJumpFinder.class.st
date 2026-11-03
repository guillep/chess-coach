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

{ #category : 'finding' }
EvaluationJumpFinder >> moments [
	"Moves that dropped the mover's evaluation across zones (see EvaluationZones); a move that allowed a forced mate is a blunder"

	| zones |
	zones := self zones.
	^ (1 to: analysis moveCount)
		  inject: OrderedCollection new
		  into: [ :moments :ply |
				  | before after mover |
				  before := analysis atPly: ply - 1.
				  after := analysis atPly: ply.
				  (before lines notEmpty and: [ after lines notEmpty ]) ifTrue: [
						  mover := before sideToMove.
						  ((self allowsMate: mover before: before after: after)
							   ifTrue: [ #blunder ]
							   ifFalse: [
							   zones
								   kindFromLine: before bestLine
								   to: after bestLine
								   for: mover ]) ifNotNil: [ :kind |
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
	"'Evaluation went from +0.50 (equal) to -1.50 (worse); best was d4', in pawns from the mover's side"

	| format zones names |
	format := EvaluationFormat pawns.
	zones := self zones.
	names := EvaluationZones zoneNames.
	^ 'Evaluation went from {1} ({2}) to {3} ({4}); best was {5}'
		  format: {
				  (format line: before bestLine for: aColor).
				  (names at: (zones zoneOf: (before bestLine pawnsFor: aColor))).
				  (format line: after bestLine for: aColor).
				  (names at: (zones zoneOf: (after bestLine pawnsFor: aColor))).
				  (before sanOf: before bestLine firstMove) }
]

{ #category : 'initialization' }
EvaluationJumpFinder >> setAnalysis: aGameAnalysis [

	analysis := aGameAnalysis
]
