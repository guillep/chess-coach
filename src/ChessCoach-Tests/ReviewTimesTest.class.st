Class {
	#name : 'ReviewTimesTest',
	#superclass : 'TestCase',
	#instVars : [
		'fixture'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
ReviewTimesTest >> reviewDictionary [
	"A review: 10 s on ply 1 and 20 s on ply 2 while marking; the mistake at ply 7 takes 30 + 45 s of answers and 15 s of reveal; the found only move at ply 3 takes 20 s"

	| review |
	review := fixture newReviewMarking.
	review showPly: 1.
	fixture wait: 10.
	review showPly: 2.
	fixture wait: 20.
	review
		finishMarkingWith: fixture analysisForTests
		moments: fixture momentsForTests.
	review start: review moments last.
	fixture wait: 30.
	review answerMoves: #( 'f3g5' ).
	fixture wait: 45.
	review answerText: 'attack'.
	review answerMoves: #(  ).
	[ review currentMoment isRevealed ] whileFalse: [
		review answerText: 'no' ].
	fixture wait: 15.
	review leaveMoment.
	review start: review moments first.
	fixture wait: 20.
	review answerText: 'the fork'.
	review leaveMoment.
	^ STONJSON fromString: review asJSON
]

{ #category : 'running' }
ReviewTimesTest >> setUp [

	super setUp.
	fixture := CoachReviewTest new.
	fixture setUp
]

{ #category : 'tests' }
ReviewTimesTest >> testATimeBoxHasAnEstimateBeforeAnyReview [

	self
		assert: ((ReviewTimes new setFromReviewDictionaries: #(  ); yourself)
				 expectedSecondsFor: #( #mistake ))
		equals: 120
]

{ #category : 'tests' }
ReviewTimesTest >> testAverages [

	| times |
	times := ReviewTimes fromReviewDictionaries: {
			         self reviewDictionary.
			         self reviewDictionary }.
	self assert: times reviewedMomentCount equals: 4.
	self assert: times secondsPerMoment equals: 55.
	self assert: (times secondsPerMomentKind at: 'mistake') equals: 90.
	self
		assert: (times secondsPerMomentKind at: 'onlyMoveFound')
		equals: 20.
	self
		assert: (times secondsPerQuestionKind at: 'candidates')
		equals: 30.
	self assert: (times secondsPerQuestionKind at: 'why') equals: 45.
	self
		assert: (times secondsPerQuestionKind at: 'whatDidYouSee')
		equals: 20.
	self assert: times markingSecondsPerGame equals: 30.
	self assert: times markingSecondsPerPly equals: 15.
	self
		assert: ((times secondsPerMomentInBlocksOf: 3) collect: [ :each |
				 each rounded ])
		equals: #( 43 90 ).
	self assert: (times expectedSecondsFor: #( #mistake )) equals: 55.
	times := ReviewTimes fromReviewDictionaries:
		         ((1 to: 3) collect: [ :each | self reviewDictionary ]).
	self assert: (times expectedSecondsFor: #( #mistake )) equals: 90
]

{ #category : 'tests' }
ReviewTimesTest >> testDashboardShowsTheTimeSection [

	| dashboard dictionary |
	dictionary := self reviewDictionary.
	dashboard := MistakesDashboardElement new.
	dashboard
		database: (MistakeDatabase withRecords:
				 ((dictionary at: 'mistakes') collect: [ :each |
					  MistakeRecord fromDictionary: each ]))
		times: (ReviewTimes fromReviewDictionaries: { dictionary }).
	self assert: (dashboard texts includes: 'Time').
	self assert: (dashboard texts includes:
			 'Marking pass: 30 s per game, 15 s per move').
	self assert: (dashboard texts anySatisfy: [ :each |
			 each beginsWith: 'Per reviewed moment: 55 s (mistake 1 min 30 s' ])
]
