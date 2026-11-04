"
One endgame configuration ('R vs pawns') with the games that went through it: their results, and how they compare with Stockfish's evaluation on entering (by evaluation zone). Entered worse = at 'worse' or below; saved = entered worse and didn't lose (an upset for me). Entered better = at 'better' or above; converted = entered better and won (not converting is an upset against me).
"
Class {
	#name : 'EndgameConfiguration',
	#superclass : 'Object',
	#instVars : [
		'name',
		'occurrences'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
EndgameConfiguration class >> name: aString occurrences: someEndgameOccurrences [

	^ self new setName: aString occurrences: someEndgameOccurrences
]

{ #category : 'counting' }
EndgameConfiguration >> convertedText: someEvaluationZones [
	"'5/6': entered better, and of those won; '—' when never entered better"

	| better |
	better := self enteredBetterIn: someEvaluationZones.
	better ifEmpty: [ ^ '—' ].
	^ (better count: [ :each | each points = 1 ]) printString , '/'
	  , better size printString
]

{ #category : 'counting' }
EndgameConfiguration >> countPoints: aNumber [

	^ occurrences count: [ :each | each points = aNumber ]
]

{ #category : 'counting' }
EndgameConfiguration >> enteredBetterIn: someEvaluationZones [
	"Games I entered at 'better' or above"

	^ occurrences select: [ :each |
			  each evaluation notNil and: [
				  (someEvaluationZones zoneOf: each evaluation) >= 1 ] ]
]

{ #category : 'counting' }
EndgameConfiguration >> enteredWorseIn: someEvaluationZones [
	"Games I entered at 'worse' or below"

	^ occurrences select: [ :each |
			  each evaluation notNil and: [
				  (someEvaluationZones zoneOf: each evaluation) <= -1 ] ]
]

{ #category : 'counting' }
EndgameConfiguration >> games [

	^ occurrences size
]

{ #category : 'accessing' }
EndgameConfiguration >> name [

	^ name
]

{ #category : 'accessing' }
EndgameConfiguration >> occurrences [

	^ occurrences
]

{ #category : 'counting' }
EndgameConfiguration >> savedText: someEvaluationZones [
	"'1/7': entered worse, and of those didn't lose; '—' when never entered worse"

	| worse |
	worse := self enteredWorseIn: someEvaluationZones.
	worse ifEmpty: [ ^ '—' ].
	^ (worse count: [ :each | each points > 0 ]) printString , '/'
	  , worse size printString
]

{ #category : 'counting' }
EndgameConfiguration >> score [
	"My score in these games, in % (a draw is half a point)"

	occurrences ifEmpty: [ ^ 0 ].
	^ ((occurrences inject: 0 into: [ :sum :each | sum + each points ])
	   * 100 / occurrences size) rounded
]

{ #category : 'initialization' }
EndgameConfiguration >> setName: aString occurrences: someEndgameOccurrences [

	name := aString.
	occurrences := someEndgameOccurrences
]

{ #category : 'counting' }
EndgameConfiguration >> upsetsAgainst: someEvaluationZones [
	"Entered better and didn't win"

	^ (occurrences select: [ :each |
		   (each upsetIn: someEvaluationZones) = #against ]) size
]

{ #category : 'counting' }
EndgameConfiguration >> upsetsFor: someEvaluationZones [
	"Entered worse and didn't lose"

	^ (occurrences select: [ :each |
		   (each upsetIn: someEvaluationZones) = #for ]) size
]

{ #category : 'counting' }
EndgameConfiguration >> upsetsIn: someEvaluationZones [

	^ (self upsetsFor: someEvaluationZones)
	  + (self upsetsAgainst: someEvaluationZones)
]
