"
The multi-label mistake taxonomy, organised by stage of the thinking process. `MistakeTaxonomy default` holds the agreed tags.
"
Class {
	#name : 'MistakeTaxonomy',
	#superclass : 'Object',
	#instVars : [
		'tags'
	],
	#category : 'ChessCoach-Core-Mistakes',
	#package : 'ChessCoach-Core',
	#tag : 'Mistakes'
}

{ #category : 'instance creation' }
MistakeTaxonomy class >> default [

	^ self withTags: {
			  (MistakeTag
				   id: 'missed-opponent-threat'
				   category: 'perception'
				   description:
				   'Did not see the opponent''s threat or forcing reply').
			  (MistakeTag
				   id: 'missed-own-tactic'
				   category: 'perception'
				   description: 'Did not see a tactic available to me').
			  (MistakeTag
				   id: 'candidate-not-considered'
				   category: 'perception'
				   description:
				   'Did not consider a good candidate (retreat, quiet move, sacrifice)').
			  (MistakeTag
				   id: 'hanging-piece'
				   category: 'perception'
				   description:
				   'Did not notice a hanging piece, mine or the opponent''s').
			  (MistakeTag
				   id: 'line-too-short'
				   category: 'calculation'
				   description: 'Stopped calculating too early (horizon)').
			  (MistakeTag
				   id: 'visualisation-error'
				   category: 'calculation'
				   description: 'Misplaced pieces while calculating').
			  (MistakeTag
				   id: 'missed-intermezzo'
				   category: 'calculation'
				   description: 'Missed an in-between move').
			  (MistakeTag
				   id: 'hope-chess'
				   category: 'calculation'
				   description: 'Only considered the replies I expected').
			  (MistakeTag
				   id: 'material-vs-activity'
				   category: 'evaluation'
				   description: 'Misjudged material against activity').
			  (MistakeTag
				   id: 'king-safety'
				   category: 'evaluation'
				   description: 'Underestimated king safety').
			  (MistakeTag
				   id: 'wrong-transition'
				   category: 'evaluation'
				   description: 'Misjudged an exchange or endgame transition').
			  (MistakeTag
				   id: 'wrong-plan'
				   category: 'evaluation'
				   description: 'Followed a wrong plan').
			  (MistakeTag
				   id: 'no-blunder-check'
				   category: 'decision'
				   description: 'Did not check the move for blunders').
			  (MistakeTag
				   id: 'impulsive'
				   category: 'decision'
				   description: 'Played on unchecked intuition').
			  (MistakeTag
				   id: 'clock-management'
				   category: 'decision'
				   description: 'Time trouble or poor use of the clock').
			  (MistakeTag
				   id: 'psychological'
				   category: 'decision'
				   description: 'Overconfidence, fear, settling or tilt').
			  (MistakeTag
				   id: 'opening-theory'
				   category: 'knowledge'
				   description: 'Did not know the opening').
			  (MistakeTag
				   id: 'endgame-technique'
				   category: 'knowledge'
				   description: 'Did not know the endgame technique').
			  (MistakeTag
				   id: 'pattern-unknown'
				   category: 'knowledge'
				   description: 'Did not know the tactical or strategic pattern') }
]

{ #category : 'instance creation' }
MistakeTaxonomy class >> withTags: aCollection [

	^ self new setTags: aCollection
]

{ #category : 'accessing' }
MistakeTaxonomy >> categories [

	^ (tags collect: [ :each | each category ]) asOrderedCollection
		  removeDuplicates asArray
]

{ #category : 'initialization' }
MistakeTaxonomy >> setTags: aCollection [

	tags := aCollection asArray
]

{ #category : 'accessing' }
MistakeTaxonomy >> tagAt: anId [

	^ tags detect: [ :each | each id = anId ]
]

{ #category : 'accessing' }
MistakeTaxonomy >> tagIds [

	^ tags collect: [ :each | each id ]
]

{ #category : 'accessing' }
MistakeTaxonomy >> tags [

	^ tags
]

{ #category : 'accessing' }
MistakeTaxonomy >> tagsInCategory: aCategory [

	^ tags select: [ :each | each category = aCategory ]
]
