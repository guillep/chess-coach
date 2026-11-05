"
I show engine evaluations the same way everywhere in the app, in the unit chosen in the settings: 'pawns' (+1.80, #3, from the given colour's side) or 'winPercent' (68%, Lichess formula). Win percentages stored elsewhere (my candidates) are turned back into pawns with the inverse of that formula.
"
Class {
	#name : 'EvaluationFormat',
	#superclass : 'Object',
	#instVars : [
		'unit'
	],
	#category : 'ChessCoach-Engine',
	#package : 'ChessCoach-Engine'
}

{ #category : 'instance creation' }
EvaluationFormat class >> pawns [

	^ self unit: 'pawns'
]

{ #category : 'instance creation' }
EvaluationFormat class >> unit: aString [
	"'pawns' or 'winPercent'"

	self assert: (#( 'pawns' 'winPercent' ) includes: aString).
	^ self new setUnit: aString
]

{ #category : 'constants' }
EvaluationFormat class >> units [
	"Setting value -> how the settings page names it"

	^ {
		  ('pawns' -> 'Pawns (+1.80)').
		  ('winPercent' -> 'Win chance (68%)') }
]

{ #category : 'formatting' }
EvaluationFormat >> dropFrom: aLineBefore to: aLineAfter for: aColor [
	"How much aColor lost with a move, '−0.90' or '−18%'; never a gain"

	| drop |
	unit = 'winPercent' ifTrue: [
			drop := (aLineBefore winPercentFor: aColor)
			        - (aLineAfter winPercentFor: aColor) max: 0.
			^ '−' , (drop printShowingDecimalPlaces: 0) , '%' ].
	drop := (aLineBefore pawnsFor: aColor)
	        - (aLineAfter pawnsFor: aColor) max: 0.
	^ '−' , (drop printShowingDecimalPlaces: 2)
]

{ #category : 'formatting' }
EvaluationFormat >> line: anEngineLine for: aColor [
	"anEngineLine's score like chess sites show it: pawns and mates from White's side (positive is good for White), or aColor's chance of winning"

	unit = 'winPercent' ifTrue: [
		^ self percent: (anEngineLine winPercentFor: aColor) ].
	anEngineLine mate ifNotNil: [ :mate | ^ '#' , mate printString ].
	^ self pawns: (anEngineLine pawnsFor: #white)
]

{ #category : 'private' }
EvaluationFormat >> pawns: aNumber [

	^ (aNumber >= 0
		   ifTrue: [ '+' ]
		   ifFalse: [ '' ]) , (aNumber printShowingDecimalPlaces: 2)
]

{ #category : 'private' }
EvaluationFormat >> percent: aNumber [

	^ (aNumber printShowingDecimalPlaces: 0) , '%'
]

{ #category : 'initialization' }
EvaluationFormat >> setUnit: aString [

	unit := aString
]

{ #category : 'accessing' }
EvaluationFormat >> unit [

	^ unit
]

{ #category : 'formatting' }
EvaluationFormat >> winPercent: aNumber [
	"A winning chance (0-100) stored without its line, in my unit"

	unit = 'winPercent' ifTrue: [ ^ self percent: aNumber ].
	^ self pawns: (EngineLine pawnsForWinPercent: aNumber)
]

{ #category : 'formatting' }
EvaluationFormat >> winPercent: aNumber for: aColor [
	"aColor's winning chance (0-100), stored without its line: as such, or as pawns from White's side like chess sites"

	| pawns |
	unit = 'winPercent' ifTrue: [ ^ self percent: aNumber ].
	pawns := EngineLine pawnsForWinPercent: aNumber.
	^ self pawns: (aColor = #white
			   ifTrue: [ pawns ]
			   ifFalse: [ pawns negated ])
]
