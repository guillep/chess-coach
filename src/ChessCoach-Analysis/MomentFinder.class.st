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
	"Setting key -> default"

	^ Dictionary new
		  at: 'momentInaccuracyDrop' put: 10;
		  at: 'momentMistakeDrop' put: 20;
		  at: 'momentBlunderDrop' put: 30;
		  at: 'momentOnlyMoveGap' put: 20;
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
