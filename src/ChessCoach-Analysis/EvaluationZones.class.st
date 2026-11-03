"
I classify a move by how far it moved the evaluation across zones, seen from the mover's side, in pawns: decisive (>= decisive, or a forced mate), winning (>= winning), better (>= equal), equal (between -equal and equal), worse, losing, decisive against. Zones are numbered 3 to -3.
A move that stays in its zone is nothing, unless it lost at least twice the equality limit outside the decisive zones (an inaccuracy). Dropping one zone at an extreme (decisive -> winning, losing -> decisive against) is an inaccuracy, one zone in the middle a mistake, two or more a blunder. A zone change counts only when the drop is at least the equality limit, so that the engine's noise at a border is not a mistake.
The limits come from the settings in centipawns (60, 200, 500 by default).
"
Class {
	#name : 'EvaluationZones',
	#superclass : 'Object',
	#instVars : [
		'equal',
		'winning',
		'decisive'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
EvaluationZones class >> default [

	^ self equal: 0.6 winning: 2 decisive: 5
]

{ #category : 'instance creation' }
EvaluationZones class >> equal: anEqualLimit winning: aWinningLimit decisive: aDecisiveLimit [
	"Limits in pawns"

	self assert: (anEqualLimit > 0 and: [
			 anEqualLimit < aWinningLimit and: [
				 aWinningLimit < aDecisiveLimit ] ]).
	^ self new
		  setEqual: anEqualLimit
		  winning: aWinningLimit
		  decisive: aDecisiveLimit
]

{ #category : 'instance creation' }
EvaluationZones class >> thresholds: aDictionary [
	"From the settings, in centipawns"

	^ self
		  equal: (aDictionary at: 'zoneEqualCentipawns') / 100
		  winning: (aDictionary at: 'zoneWinningCentipawns') / 100
		  decisive: (aDictionary at: 'zoneDecisiveCentipawns') / 100
]

{ #category : 'constants' }
EvaluationZones class >> zoneNames [
	"Zone number -> name, from the mover's side"

	^ Dictionary new
		  at: 3 put: 'decisive';
		  at: 2 put: 'winning';
		  at: 1 put: 'better';
		  at: 0 put: 'equal';
		  at: -1 put: 'worse';
		  at: -2 put: 'losing';
		  at: -3 put: 'decisive against';
		  yourself
]

{ #category : 'accessing' }
EvaluationZones >> equal [
	"The equality limit, in pawns"

	^ equal
]

{ #category : 'classifying' }
EvaluationZones >> kindFrom: aPawnsBefore to: aPawnsAfter [
	"#blunder, #mistake, #inaccuracy or nil, for a move that took the mover's evaluation from aPawnsBefore to aPawnsAfter"

	| drop from to steps |
	drop := aPawnsBefore - aPawnsAfter.
	drop <= 0 ifTrue: [ ^ nil ].
	from := self zoneOf: aPawnsBefore.
	to := self zoneOf: aPawnsAfter.
	steps := drop >= equal
		         ifTrue: [ from - to ]
		         ifFalse: [ 0 ].
	steps >= 2 ifTrue: [ ^ #blunder ].
	steps = 1 ifTrue: [
			^ ((from = 3 and: [ to = 2 ]) or: [ from = -2 and: [ to = -3 ] ])
				  ifTrue: [ #inaccuracy ]
				  ifFalse: [ #mistake ] ].
	(drop >= (2 * equal) and: [ from abs < 3 ]) ifTrue: [ ^ #inaccuracy ].
	^ nil
]

{ #category : 'classifying' }
EvaluationZones >> kindFromLine: aLineBefore to: aLineAfter for: aColor [

	^ self
		  kindFrom: (aLineBefore pawnsFor: aColor)
		  to: (aLineAfter pawnsFor: aColor)
]

{ #category : 'initialization' }
EvaluationZones >> setEqual: anEqualLimit winning: aWinningLimit decisive: aDecisiveLimit [

	equal := anEqualLimit.
	winning := aWinningLimit.
	decisive := aDecisiveLimit
]

{ #category : 'classifying' }
EvaluationZones >> severityOf: aKind [
	"For sorting: blunder 3, mistake 2, inaccuracy 1, nothing 0"

	^ #( #inaccuracy #mistake #blunder ) indexOf: aKind
]

{ #category : 'classifying' }
EvaluationZones >> zoneOf: aPawns [
	"3 decisive, 2 winning, 1 better, 0 equal, -1 worse, -2 losing, -3 decisive against"

	aPawns >= decisive ifTrue: [ ^ 3 ].
	aPawns >= winning ifTrue: [ ^ 2 ].
	aPawns >= equal ifTrue: [ ^ 1 ].
	aPawns > equal negated ifTrue: [ ^ 0 ].
	aPawns > winning negated ifTrue: [ ^ -1 ].
	aPawns > decisive negated ifTrue: [ ^ -2 ].
	^ -3
]
