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
		'labels',
		'score',
		'winDrop',
		'seconds'
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
	review
		score: (aDictionary at: 'score' ifAbsent: [ 0 ]);
		winDrop: (aDictionary at: 'winDrop' ifAbsent: [ 0 ]);
		addSeconds: (aDictionary at: 'seconds' ifAbsent: [ 0 ]).
	^ review
]

{ #category : 'instance creation' }
CoachMomentReview class >> ply: aPly color: aColor kinds: someKinds [

	^ self new
		  setPly: aPly color: aColor kinds: someKinds asArray;
		  yourself
]

{ #category : 'dialogue' }
CoachMomentReview >> addAnswer: aCoachAnswer [

	answers add: aCoachAnswer.
	self proposeLabels: aCoachAnswer labels
]

{ #category : 'accessing' }
CoachMomentReview >> addSeconds: aNumber [

	seconds := seconds + aNumber
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
		  at: 'score' put: score;
		  at: 'winDrop' put: winDrop;
		  at: 'seconds' put: seconds;
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

{ #category : 'labels' }
CoachMomentReview >> countedLabels [
	"The tags that count as my mistakes: proposed or confirmed, not rejected"

	^ labels reject: [ :each | each isRejected ]
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
CoachMomentReview >> isMarked [

	^ kinds includes: #marked
]

{ #category : 'testing' }
CoachMomentReview >> isRevealed [
	"No question left: the engine's view and the proposed tags can be shown"

	^ pending isEmpty
]

{ #category : 'testing' }
CoachMomentReview >> isReviewed [
	"Every question about this moment has been answered"

	^ self isStarted and: [ self isRevealed ]
]

{ #category : 'testing' }
CoachMomentReview >> isStarted [
	"Whether the coach has asked anything about this moment yet"

	^ answers notEmpty or: [ pending notEmpty ]
]

{ #category : 'testing' }
CoachMomentReview >> isSuccess [
	"A found only move and nothing else: there is no mistake to tag"

	^ kinds notEmpty and: [
		  kinds allSatisfy: [ :each | each = #onlyMoveFound ] ]
]

{ #category : 'accessing' }
CoachMomentReview >> kinds [

	^ kinds
]

{ #category : 'accessing' }
CoachMomentReview >> kinds: someKinds [

	kinds := someKinds asArray
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

{ #category : 'testing' }
CoachMomentReview >> passes: aFilter [
	"aFilter is #all, #mistakes (mistakes, blunders, only moves, long thinks) or #blunders. My marks always pass."

	aFilter = #all ifTrue: [ ^ true ].
	aFilter = #mistakes ifTrue: [
			^ kinds includesAny:
				  #( #mistake #blunder #onlyMoveMissed #onlyMoveFound
				     #longThink #marked ) ].
	aFilter = #blunders ifTrue: [
		^ kinds includesAny: #( #blunder #marked ) ].
	self error: 'Unknown moment filter: ' , aFilter printString
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

{ #category : 'accessing' }
CoachMomentReview >> score [
	"Importance from MomentPrioritizer"

	^ score
]

{ #category : 'accessing' }
CoachMomentReview >> score: aNumber [

	score := aNumber
]

{ #category : 'accessing' }
CoachMomentReview >> seconds [
	"Time spent on this moment: its questions and its reveal"

	^ seconds
]

{ #category : 'initialization' }
CoachMomentReview >> setPly: aPly color: aColor kinds: someKinds [

	ply := aPly.
	color := aColor.
	kinds := someKinds.
	pending := OrderedCollection new.
	answers := OrderedCollection new.
	candidateWinPercents := Dictionary new.
	labels := OrderedCollection new.
	score := 0.
	winDrop := 0.
	seconds := 0
]

{ #category : 'labels' }
CoachMomentReview >> toggleTag: aTagId [
	"A counted tag stops counting; a rejected one, or one not proposed, counts and is confirmed"

	(labels detect: [ :each | each tagId = aTagId ] ifNone: [ nil ])
		ifNil: [ self confirmTag: aTagId ]
		ifNotNil: [ :label |
				label isRejected
					ifTrue: [ label confirm ]
					ifFalse: [ label reject ] ]
]

{ #category : 'accessing' }
CoachMomentReview >> winDrop [
	"How many win-% points my move lost against the best one"

	^ winDrop
]

{ #category : 'accessing' }
CoachMomentReview >> winDrop: aNumber [

	winDrop := aNumber
]
