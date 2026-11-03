"
A way of finding moments, with thresholds that can be set in Settings. Any threshold not given takes its default.
"
Class {
	#name : 'MomentFinder',
	#superclass : 'Object',
	#instVars : [
		'thresholds'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'accessing' }
MomentFinder class >> defaultThresholds [
	"Setting key -> default. The evaluation zones are in centipawns, from the mover's side (see EvaluationZones)."

	^ Dictionary new
		  at: 'zoneEqualCentipawns' put: 60;
		  at: 'zoneWinningCentipawns' put: 200;
		  at: 'zoneDecisiveCentipawns' put: 500;
		  at: 'momentLongThinkSeconds' put: 10;
		  at: 'momentLongThinkFactor' put: 3;
		  at: 'momentOpeningScoreGap' put: 5;
		  at: 'momentOpeningMinimumGames' put: 50;
		  yourself
]

{ #category : 'accessing' }
MomentFinder >> threshold: aKey [

	^ (thresholds ifNil: [ self class defaultThresholds ])
		  at: aKey
		  ifAbsent: [ self class defaultThresholds at: aKey ]
]

{ #category : 'accessing' }
MomentFinder >> thresholds: aDictionary [

	thresholds := aDictionary
]

{ #category : 'accessing' }
MomentFinder >> zones [
	"The evaluation zones of my thresholds"

	^ EvaluationZones thresholds:
		  (#( 'zoneEqualCentipawns' 'zoneWinningCentipawns'
		      'zoneDecisiveCentipawns' ) collect: [ :each |
			   each -> (self threshold: each) ]) asDictionary
]
