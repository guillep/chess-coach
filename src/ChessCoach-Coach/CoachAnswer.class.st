"
My answer to a CoachQuestion: UCI moves for board questions, text otherwise. Text answers carry the MistakeLabels proposed by the classifier (empty when it was unavailable).
"
Class {
	#name : 'CoachAnswer',
	#superclass : 'Object',
	#instVars : [
		'question',
		'moves',
		'text',
		'labels',
		'classified',
		'seconds'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'instance creation' }
CoachAnswer class >> fromDictionary: aDictionary [

	^ (self new
		   setQuestion:
			   (CoachQuestion fromDictionary: (aDictionary at: 'question'))
		   moves: (aDictionary at: 'moves') asArray
		   text: (aDictionary at: 'text')
		   labels: ((aDictionary at: 'labels') collect: [ :each |
					    MistakeLabel fromDictionary: each ]) asArray)
		  classified: (aDictionary at: 'classified' ifAbsent: [ true ]);
		  seconds: (aDictionary at: 'seconds' ifAbsent: [ 0 ]);
		  yourself
]

{ #category : 'instance creation' }
CoachAnswer class >> question: aCoachQuestion moves: someUCIMoves [

	^ self new
		  setQuestion: aCoachQuestion
		  moves: someUCIMoves asArray
		  text: nil
		  labels: #(  )
]

{ #category : 'instance creation' }
CoachAnswer class >> question: aCoachQuestion text: aString [
	"A written answer waiting to be classified"

	^ (self new
		   setQuestion: aCoachQuestion
		   moves: #(  )
		   text: aString
		   labels: #(  ))
		  classified: false;
		  yourself
]

{ #category : 'instance creation' }
CoachAnswer class >> question: aCoachQuestion text: aString labels: someMistakeLabels [

	^ self new
		  setQuestion: aCoachQuestion
		  moves: #(  )
		  text: aString
		  labels: someMistakeLabels asArray
]

{ #category : 'converting' }
CoachAnswer >> asDictionary [

	^ Dictionary new
		  at: 'question' put: question asDictionary;
		  at: 'moves' put: moves copy;
		  at: 'text' put: text;
		  at: 'labels' put: (labels collect: [ :each | each asDictionary ]);
		  at: 'classified' put: classified;
		  at: 'seconds' put: self seconds;
		  yourself
]

{ #category : 'accessing' }
CoachAnswer >> classified: aBoolean [

	classified := aBoolean
]

{ #category : 'accessing' }
CoachAnswer >> classifiedAs: someMistakeLabels [

	labels := someMistakeLabels asArray.
	classified := true
]

{ #category : 'testing' }
CoachAnswer >> isClassified [
	"Board answers need no classification; written ones do, once"

	^ classified
]

{ #category : 'accessing' }
CoachAnswer >> labels [

	^ labels
]

{ #category : 'accessing' }
CoachAnswer >> moves [

	^ moves
]

{ #category : 'accessing' }
CoachAnswer >> question [

	^ question
]

{ #category : 'accessing' }
CoachAnswer >> seconds [
	"How long I took to answer, from the moment the question was shown"

	^ seconds ifNil: [ 0 ]
]

{ #category : 'accessing' }
CoachAnswer >> seconds: aNumber [

	seconds := aNumber
]

{ #category : 'initialization' }
CoachAnswer >> setQuestion: aCoachQuestion moves: someUCIMoves text: aStringOrNil labels: someMistakeLabels [

	question := aCoachQuestion.
	moves := someUCIMoves.
	text := aStringOrNil.
	labels := someMistakeLabels.
	classified := true
]

{ #category : 'accessing' }
CoachAnswer >> text [

	^ text
]
