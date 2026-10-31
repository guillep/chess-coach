"
How long my coach reviews take, from the saved review files: per reviewed moment (overall and by moment kind), per question kind, and for the manual marking pass (per game and per ply). Feeds the dashboard's Time section and plans time-boxed analyses.

moments: kinds -> seconds of every reviewed moment, oldest review first. answers: question kind -> seconds. markingPasses: plies looked at -> seconds, per finished marking pass.
"
Class {
	#name : 'ReviewTimes',
	#superclass : 'Object',
	#instVars : [
		'moments',
		'answers',
		'markingPasses'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'instance creation' }
ReviewTimes class >> fromReviewDictionaries: someDictionaries [
	"someDictionaries are parsed review files (games/<id>.review-<n>.json)"

	^ self new
		  setFromReviewDictionaries: someDictionaries;
		  yourself
]

{ #category : 'private' }
ReviewTimes >> average: someNumbers [

	someNumbers ifEmpty: [ ^ 0 ].
	^ (someNumbers inject: 0 into: [ :sum :each | sum + each ])
	  / someNumbers size
]

{ #category : 'statistics' }
ReviewTimes >> markingSecondsPerGame [

	^ self average: (markingPasses collect: [ :each | each value ])
]

{ #category : 'statistics' }
ReviewTimes >> markingSecondsPerPly [

	| plies |
	plies := markingPasses
		         inject: 0
		         into: [ :sum :each | sum + each key ].
	plies = 0 ifTrue: [ ^ 0 ].
	^ (markingPasses inject: 0 into: [ :sum :each | sum + each value ])
	  / plies
]

{ #category : 'accessing' }
ReviewTimes >> reviewedMomentCount [

	^ moments size
]

{ #category : 'statistics' }
ReviewTimes >> secondsPerMoment [

	^ self average: (moments collect: [ :each | each value ])
]

{ #category : 'statistics' }
ReviewTimes >> secondsPerMomentInBlocksOf: anInteger [
	"Average seconds per moment for each block of anInteger reviewed moments, oldest first"

	^ ((1 to: moments size by: anInteger) collect: [ :start |
			   self average: ((moments
					     copyFrom: start
					     to: (start + anInteger - 1 min: moments size)) collect: [
					    :each | each value ]) ]) asArray
]

{ #category : 'statistics' }
ReviewTimes >> secondsPerMomentKind [
	"Moment kind -> average seconds, for the kinds of the reviewed moments"

	| byKind |
	byKind := Dictionary new.
	moments do: [ :each |
			each key do: [ :kind |
					(byKind at: kind asString ifAbsentPut: [ OrderedCollection new ])
						add: each value ] ].
	^ byKind collect: [ :seconds | self average: seconds ]
]

{ #category : 'statistics' }
ReviewTimes >> secondsPerQuestionKind [
	"Question kind -> average seconds to answer it"

	| byKind |
	byKind := Dictionary new.
	answers do: [ :each |
			(byKind at: each key ifAbsentPut: [ OrderedCollection new ]) add:
				each value ].
	^ byKind collect: [ :seconds | self average: seconds ]
]

{ #category : 'initialization' }
ReviewTimes >> setFromReviewDictionaries: someDictionaries [

	moments := OrderedCollection new.
	answers := OrderedCollection new.
	markingPasses := OrderedCollection new.
	(someDictionaries asArray sort: [ :a :b |
		 (a at: 'date' ifAbsent: [ '' ]) <= (b at: 'date' ifAbsent: [ '' ]) ])
		do: [ :review |
				| plies |
				plies := review at: 'plySeconds' ifAbsent: [ #(  ) ].
				((review at: 'marking' ifAbsent: [ false ]) not and: [
					 plies notEmpty ]) ifTrue: [
						markingPasses add: plies size
							-> (plies inject: 0 into: [ :sum :pair | sum + pair second ]) ].
				(review at: 'moments') do: [ :moment |
						((moment at: 'answers') notEmpty and: [
							 (moment at: 'pending') isEmpty ]) ifTrue: [
								moments add:
									(moment at: 'kinds') asArray
									-> (moment at: 'seconds' ifAbsent: [ 0 ]).
								(moment at: 'answers') do: [ :answer |
										answers add: ((answer at: 'question') at: 'kind')
											-> (answer at: 'seconds' ifAbsent: [ 0 ]) ] ] ] ]
]
