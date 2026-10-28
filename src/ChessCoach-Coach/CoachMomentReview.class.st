"
The dialogue about one moment: questions still pending, my answers, the engine's evaluation of my candidates (UCI -> my win %) and the taxonomy labels proposed from my text answers, which I can confirm or drop at the reveal.
"
Class {
	#name : 'CoachMomentReview',
	#superclass : 'Object',
	#instVars : [
		'ply',
		'color',
		'kinds',
		'pending',
		'answers',
		'candidateWinPercents',
		'labels'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'instance creation' }
CoachMomentReview class >> fromDictionary: aDictionary [

	| review |
	review := self new
		          setPly: (aDictionary at: 'ply')
		          color: (aDictionary at: 'color') asSymbol
		          kinds:
		          ((aDictionary at: 'kinds') collect: [ :each |
			           each asSymbol ]) asArray.
	review ask: ((aDictionary at: 'pending') collect: [ :each |
			 CoachQuestion fromDictionary: each ]).
	(aDictionary at: 'answers') do: [ :each |
		review addAnswer: (CoachAnswer fromDictionary: each) ].
	(aDictionary at: 'candidates') keysAndValuesDo: [ :move :percent |
		review candidate: move winPercent: percent ].
	review labels: ((aDictionary at: 'labels') collect: [ :each |
			 MistakeLabel fromDictionary: each ]).
	^ review
]

{ #category : 'instance creation' }
CoachMomentReview class >> ply: aPly color: aColor kinds: someKinds questions: someQuestions [

	^ self new
		  setPly: aPly color: aColor kinds: someKinds asArray;
		  ask: someQuestions;
		  yourself
]

{ #category : 'dialogue' }
CoachMomentReview >> addAnswer: aCoachAnswer [

	answers add: aCoachAnswer.
	self proposeLabels: aCoachAnswer labels
]

{ #category : 'dialogue' }
CoachMomentReview >> answer: aCoachAnswer [
	"Answer the current question"

	self assert: pending first == aCoachAnswer question.
	pending removeFirst.
	self addAnswer: aCoachAnswer
]

{ #category : 'accessing' }
CoachMomentReview >> answerTo: aKind [

	^ answers detect: [ :each | each question kind = aKind ]
]

{ #category : 'accessing' }
CoachMomentReview >> answers [

	^ answers
]

{ #category : 'converting' }
CoachMomentReview >> asDictionary [

	^ Dictionary new
		  at: 'ply' put: ply;
		  at: 'color' put: color asString;
		  at: 'kinds' put: (kinds collect: [ :each | each asString ]);
		  at: 'pending'
		  put: (pending collect: [ :each | each asDictionary ]) asArray;
		  at: 'answers'
		  put: (answers collect: [ :each | each asDictionary ]) asArray;
		  at: 'candidates' put: candidateWinPercents copy;
		  at: 'labels'
		  put: (labels collect: [ :each | each asDictionary ]) asArray;
		  yourself
]

{ #category : 'dialogue' }
CoachMomentReview >> ask: someQuestions [

	pending addAll: someQuestions
]

{ #category : 'accessing' }
CoachMomentReview >> candidate: aUCIMove winPercent: aNumber [

	candidateWinPercents at: aUCIMove put: aNumber
]

{ #category : 'accessing' }
CoachMomentReview >> candidateWinPercents [
	"My candidates (UCI) and my win % after each, from the engine"

	^ candidateWinPercents
]

{ #category : 'accessing' }
CoachMomentReview >> color [

	^ color
]

{ #category : 'labels' }
CoachMomentReview >> confirmTag: aTagId [
	"Confirm a proposed tag, or add it confirmed if the classifier missed it"

	(labels
		 detect: [ :each | each tagId = aTagId ]
		 ifNone: [ labels add: (MistakeLabel tagId: aTagId confidence: 1) ])
		confirm
]

{ #category : 'dialogue' }
CoachMomentReview >> currentQuestion [

	^ pending first
]

{ #category : 'labels' }
CoachMomentReview >> dropTag: aTagId [

	labels removeAllSuchThat: [ :each | each tagId = aTagId ]
]

{ #category : 'testing' }
CoachMomentReview >> isClassifying [
	"Whether some written answer still waits for the classifier"

	^ answers anySatisfy: [ :each | each isClassified not ]
]

{ #category : 'testing' }
CoachMomentReview >> isRevealed [
	"No question left: the engine's view and the proposed tags can be shown"

	^ pending isEmpty
]

{ #category : 'accessing' }
CoachMomentReview >> kinds [

	^ kinds
]

{ #category : 'accessing' }
CoachMomentReview >> labels [
	"Taxonomy labels proposed from my answers"

	^ labels
]

{ #category : 'accessing' }
CoachMomentReview >> labels: someMistakeLabels [

	labels := someMistakeLabels asOrderedCollection
]

{ #category : 'accessing' }
CoachMomentReview >> pending [
	"Questions not answered yet, next first"

	^ pending
]

{ #category : 'accessing' }
CoachMomentReview >> ply [

	^ ply
]

{ #category : 'labels' }
CoachMomentReview >> proposeLabels: someMistakeLabels [
	"Merge someMistakeLabels into the proposed ones, keeping the highest confidence per tag and any confirmation"

	someMistakeLabels do: [ :label |
			(labels
				 detect: [ :each | each tagId = label tagId ]
				 ifNone: [ nil ])
				ifNil: [ labels add: label ]
				ifNotNil: [ :existing |
						(existing isConfirmed not and: [
							 label confidence > existing confidence ]) ifTrue: [
							labels at: (labels indexOf: existing) put: label ] ] ]
]

{ #category : 'initialization' }
CoachMomentReview >> setPly: aPly color: aColor kinds: someKinds [

	ply := aPly.
	color := aColor.
	kinds := someKinds.
	pending := OrderedCollection new.
	answers := OrderedCollection new.
	candidateWinPercents := Dictionary new.
	labels := OrderedCollection new
]
