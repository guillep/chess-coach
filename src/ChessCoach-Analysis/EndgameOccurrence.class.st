"
One game going through one endgame configuration: where it entered it (ply), the pawns each side had then, the game's result for me (1, 0.5, 0) and Stockfish's evaluation on entering, in pawns from my side (nil when the game isn't analysed). Upsets compare the evaluation's zone with the result.
"
Class {
	#name : 'EndgameOccurrence',
	#superclass : 'Object',
	#instVars : [
		'gameId',
		'ply',
		'myPawns',
		'theirPawns',
		'points',
		'evaluation'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
EndgameOccurrence class >> gameId: anId ply: aPly myPawns: aNumber theirPawns: anotherNumber points: somePoints evaluation: aPawnsOrNil [

	^ self new
		  setGameId: anId
		  ply: aPly
		  myPawns: aNumber
		  theirPawns: anotherNumber
		  points: somePoints
		  evaluation: aPawnsOrNil
]

{ #category : 'accessing' }
EndgameOccurrence >> evaluation [
	"Pawns from my side on entering, or nil without analysis"

	^ evaluation
]

{ #category : 'accessing' }
EndgameOccurrence >> gameId [

	^ gameId
]

{ #category : 'accessing' }
EndgameOccurrence >> pawnsText [
	"'2 vs 3 pawns'"

	^ myPawns printString , ' vs ' , theirPawns printString , ' pawns'
]

{ #category : 'accessing' }
EndgameOccurrence >> ply [
	"Where the game entered the configuration"

	^ ply
]

{ #category : 'accessing' }
EndgameOccurrence >> points [
	"My result: 1, 1/2 or 0"

	^ points
]

{ #category : 'initialization' }
EndgameOccurrence >> setGameId: anId ply: aPly myPawns: aNumber theirPawns: anotherNumber points: somePoints evaluation: aPawnsOrNil [

	gameId := anId.
	ply := aPly.
	myPawns := aNumber.
	theirPawns := anotherNumber.
	points := somePoints.
	evaluation := aPawnsOrNil
]

{ #category : 'testing' }
EndgameOccurrence >> upsetIn: someEvaluationZones [
	"#for when I entered worse or below and didn't lose, #against when I entered better or above and didn't win, nil otherwise (or without an evaluation)"

	| zone |
	evaluation ifNil: [ ^ nil ].
	zone := someEvaluationZones zoneOf: evaluation.
	(zone <= -1 and: [ points > 0 ]) ifTrue: [ ^ #for ].
	(zone >= 1 and: [ points < 1 ]) ifTrue: [ ^ #against ].
	^ nil
]
