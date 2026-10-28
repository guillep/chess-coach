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
		'labels'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'instance creation' }
CoachAnswer class >> fromDictionary: aDictionary [

	^ self new
		  setQuestion:
		  (CoachQuestion fromDictionary: (aDictionary at: 'question'))
		  moves: (aDictionary at: 'moves') asArray
		  text: (aDictionary at: 'text')
		  labels: ((aDictionary at: 'labels') collect: [ :each |
				   MistakeLabel fromDictionary: each ]) asArray
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
		  yourself
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

{ #category : 'initialization' }
CoachAnswer >> setQuestion: aCoachQuestion moves: someUCIMoves text: aStringOrNil labels: someMistakeLabels [

	question := aCoachQuestion.
	moves := someUCIMoves.
	text := aStringOrNil.
	labels := someMistakeLabels
]

{ #category : 'accessing' }
CoachAnswer >> text [

	^ text
]
