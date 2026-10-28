"
I find difficult positions with a single good move: the best line beats the second by at least 20 points of win percentage, and something is at stake (the position isn't decided, the second move loses a good position, or only the best line mates). I report whether the player found it.
"
Class {
	#name : 'OnlyMoveFinder',
	#superclass : 'Object',
	#instVars : [
		'analysis'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
OnlyMoveFinder class >> on: aGameAnalysis [

	^ self new
		  setAnalysis: aGameAnalysis;
		  yourself
]

{ #category : 'testing' }
OnlyMoveFinder >> hasOnlyMove: aPlyAnalysis for: aColor [

	| best second |
	aPlyAnalysis lines size < 2 ifTrue: [ ^ false ].
	best := aPlyAnalysis lines first winPercentFor: aColor.
	second := aPlyAnalysis lines second winPercentFor: aColor.
	best - second >= 20 ifFalse: [ ^ false ].
	^ (best between: 10 and: 90) or: [
			  (best >= 50 and: [ second <= 10 ]) or: [
					  (aPlyAnalysis lines first isMateFor: aColor) and: [
						  (aPlyAnalysis lines second isMateFor: aColor) not ] ] ]
]

{ #category : 'finding' }
OnlyMoveFinder >> moments [

	^ (1 to: analysis moveCount)
		  inject: OrderedCollection new
		  into: [ :moments :ply |
				  | before after mover second found |
				  before := analysis atPly: ply - 1.
				  after := analysis atPly: ply.
				  mover := before sideToMove.
				  ((self hasOnlyMove: before for: mover) and: [
					   after lines notEmpty ]) ifTrue: [
						  second := before lines second winPercentFor: mover.
						  found := (after winPercentFor: mover)
						           > (second + (before winPercentFor: mover) / 2).
						  moments add: (ChessMoment
								   ply: ply
								   color: mover
								   kind: (found
										    ifTrue: [ #onlyMoveFound ]
										    ifFalse: [ #onlyMoveMissed ])
								   source: #engine
								   note:
									   ('Only one good move: {1} ({2}); the next best, {3}, gives {4}'
										    format: {
												    (before sanOf: before bestLine firstMove).
												    before bestLine scoreString.
												    (before sanOf: before lines second firstMove).
												    before lines second scoreString })) ].
				  moments ]
]

{ #category : 'initialization' }
OnlyMoveFinder >> setAnalysis: aGameAnalysis [

	analysis := aGameAnalysis
]
