"
I find difficult positions with a single good move: the best line beats the second by at least 20 points of win percentage, and something is at stake (the position isn't decided, the second move loses a good position, or only the best line mates). I report whether the player found it.
"
Class {
	#name : 'OnlyMoveFinder',
	#superclass : 'MomentFinder',
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
	"Every move but the best would be a mistake or a blunder (see EvaluationZones)"

	aPlyAnalysis lines size < 2 ifTrue: [ ^ false ].
	^ #( #mistake #blunder ) includes: (self zones
			   kindFromLine: aPlyAnalysis lines first
			   to: aPlyAnalysis lines second
			   for: aColor)
]

{ #category : 'testing' }
OnlyMoveFinder >> isObviousAt: aPly [
	"An only move nobody needs to talk about: the only legal move, or the recapture of material my opponent just took when no other move gets it back"

	| before position best balance restoring |
	before := analysis atPly: aPly - 1.
	position := ChessPosition fromFEN: before fen.
	position legalUCIMoves size <= 1 ifTrue: [ ^ true ].
	aPly < 2 ifTrue: [ ^ false ].
	balance := (ChessPosition fromFEN: (analysis atPly: aPly - 2) fen)
		           materialBalanceFor: position turn.
	(position materialBalanceFor: position turn) < balance ifFalse: [
		^ false ].
	best := before bestLine firstMove.
	restoring := position legalUCIMoves select: [ :each |
			             ((position moveUCI: each) materialBalanceFor:
				              position turn) >= balance ].
	^ restoring asArray = { best }
]

{ #category : 'finding' }
OnlyMoveFinder >> moments [
	"Positions where every move but one was a mistake or worse; found when the played move was not a mistake. Obvious ones (forced moves, plain recaptures) are left out."

	| zones |
	zones := self zones.
	^ (1 to: analysis moveCount)
		  inject: OrderedCollection new
		  into: [ :moments :ply |
				  | before after mover found |
				  before := analysis atPly: ply - 1.
				  after := analysis atPly: ply.
				  mover := before sideToMove.
				  ((self hasOnlyMove: before for: mover) and: [
					   after lines notEmpty and: [ (self isObviousAt: ply) not ] ])
					  ifTrue: [
							  found := (#( #mistake #blunder ) includes:
								            (zones
									             kindFromLine: before bestLine
									             to: after bestLine
									             for: mover)) not.
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
													    (EvaluationFormat pawns
														     line: before bestLine
														     for: mover).
													    (before sanOf: before lines second firstMove).
													    (EvaluationFormat pawns
														     line: before lines second
														     for: mover) })) ].
				  moments ]
]

{ #category : 'initialization' }
OnlyMoveFinder >> setAnalysis: aGameAnalysis [

	analysis := aGameAnalysis
]
