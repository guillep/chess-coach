"
I run moment finders over a game, keep the automatic moments of the given colors plus every marked moment, and merge moments on the same ply. Answers are sorted by ply.
"
Class {
	#name : 'MomentDetector',
	#superclass : 'Object',
	#instVars : [
		'finders',
		'marksFinder',
		'colors'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
MomentDetector class >> finders: someFinders marksFinder: aMarkedMomentsFinder colors: someColors [

	^ self new
		  setFinders: someFinders
		  marksFinder: aMarkedMomentsFinder
		  colors: someColors
]

{ #category : 'detecting' }
MomentDetector >> moments [

	| byPly |
	byPly := Dictionary new.
	(finders flatCollect: [ :finder | finder moments ])
	, marksFinder moments do: [ :moment |
			(moment isMarked or: [ colors includes: moment color ]) ifTrue: [
					byPly
						at: moment ply
						ifPresent: [ :existing | existing absorb: moment ]
						ifAbsentPut: [ moment ] ] ].
	^ byPly values sort: [ :a :b | a ply < b ply ]
]

{ #category : 'initialization' }
MomentDetector >> setFinders: someFinders marksFinder: aMarkedMomentsFinder colors: someColors [

	finders := someFinders.
	marksFinder := aMarkedMomentsFinder.
	colors := someColors
]
