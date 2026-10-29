"
Drives CoachElement through a whole moment with stubbed Stockfish and Ollama (the CoachReviewTest fixture) and a synchronous background runner.
"
Class {
	#name : 'CoachElementTest',
	#superclass : 'TestCase',
	#instVars : [
		'review',
		'coach',
		'scripter'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
CoachElementTest >> answer: aString [

	coach answerField text: aString.
	coach submitText.
	scripter pulse
]

{ #category : 'helpers' }
CoachElementTest >> arrowsOfStyle: aSymbol [

	^ (coach board arrows select: [ :each | each style = aSymbol ])
		  collect: [ :each | each uci ]
]

{ #category : 'helpers' }
CoachElementTest >> clickOn: aSquare [

	scripter testClick onChildFromBlock: [ :root |
		coach board squareElementAt: aSquare ].
	scripter syncContinue.
	scripter pulse
]

{ #category : 'running' }
CoachElementTest >> setUp [

	| fixture session |
	super setUp.
	fixture := CoachReviewTest new.
	fixture setUp.
	review := fixture newReview.
	session := (LichessAPIClientStub withGames: 0) newSessionOn:
		           FileSystem memory root.
	coach := CoachElement new.
	coach backgroundRunner: [ :work | work value ].
	coach session: session entry: nil review: review.
	scripter := BlDevScripter new.
	scripter element: coach.
	scripter space extent: 1100 @ 700.
	scripter pulse
]

{ #category : 'tests' }
CoachElementTest >> testAWholeMoment [

	self assert: coach mode equals: #list.
	self assert:
		(self zoneTexts includes:
			 'To do · Move 2 (Nf3) · onlyMoveFound · −0%').
	self assert:
		(self zoneTexts includes: 'To do · Move 4 (Ng5) · mistake · −18%').
	coach continueReview.
	scripter pulse.
	self assert: review currentQuestion kind equals: #whatDidYouSee.
	self answer: 'The bishop'.
	coach nextMoment.
	scripter pulse.
	self assert: (coach header text asString includesSubstring:
			 'Moment 2 of 2 · move 4 (Ng5)').
	self assert: coach board orientation equals: #white.
	self
		assert: (self arrowsOfStyle: #played) asArray
		equals: #( 'f3g5' ).
	self clickOn: 'd2'.
	self clickOn: 'd3'.
	self
		assert: (self arrowsOfStyle: #candidate) asArray
		equals: #( 'd2d3' ).
	self assert: (self zoneTexts includes: 'Marked: d3').
	self clickOn: 'e1'.
	self clickOn: 'e5'.
	self assert: coach message equals: 'Illegal move'.
	coach submitMoves.
	scripter pulse.
	self assert: (self zoneTexts includes: 'Why did you play Ng5?').
	self answer: 'I wanted to attack f7'.
	self assert: (coach history children anySatisfy: [ :each |
			 each text asString = '→ I wanted to attack f7' ]).
	self assert: (coach board chessPosition pieceAt: 'g5') equals: 'N'.
	self clickOn: 'h7'.
	self clickOn: 'h6'.
	coach submitMoves.
	scripter pulse.
	self assert:
		(self zoneTexts includes: 'You didn''t consider d4. Why?').
	self
		assert: (self arrowsOfStyle: #subject) asArray
		equals: #( 'd2d4' ).
	3 timesRepeat: [ self answer: 'I did not see it' ].
	self assert: review currentMoment isRevealed.
	self assert: (self zoneTexts includes: 'Engine line: d4').
	self assert:
		(self zoneTexts includes: 'missed-opponent-threat (70%)').
	self
		assert: (self arrowsOfStyle: #engine) asArray
		equals: #( 'd2d4' ).
	coach confirmTag: 'missed-opponent-threat'.
	self assert: (self zoneTexts includes: '✓ missed-opponent-threat').
	coach nextMoment.
	scripter pulse.
	self assert: coach mode equals: #summary.
	self assert:
		(self zoneTexts anySatisfy: [ :each |
			 each beginsWith: 'Move 4 (Ng5)' ])
]

{ #category : 'tests' }
CoachElementTest >> testListShowsPastMomentsAndReviewsOneMoment [

	| moment |
	moment := review moments last.
	coach showMoment: moment.
	scripter pulse.
	self assert: (self zoneTexts includes: 'Not reviewed yet.').
	coach reviewShown.
	scripter pulse.
	self assert: review currentMoment equals: moment.
	coach submitMoves.
	self answer: 'Attack'.
	coach stop.
	scripter pulse.
	self assert: coach mode equals: #list.
	self assert: review currentMoment isNil.
	self assert:
		(self zoneTexts includes: 'Started · Move 4 (Ng5) · mistake · −18%').
	coach filter: #blunders.
	scripter pulse.
	self assert:
		(self zoneTexts includes: 'No moments with this filter.').
	coach filter: #all.
	coach showMoment: moment.
	scripter pulse.
	self assert: (self zoneTexts includes:
			 'You started this moment but did not finish it.').
	coach reviewShown.
	self assert: review currentQuestion kind equals: #expectedReply
]

{ #category : 'helpers' }
CoachElementTest >> zoneTexts [
	"The texts of the labels and buttons in the current question zone"

	| texts |
	texts := OrderedCollection new.
	coach currentZone allChildrenBreadthFirstDo: [ :each |
			(each isKindOf: ToLabel) ifTrue: [ texts add: each text asString ].
			(each isKindOf: ToButton) ifTrue: [
				texts add: each labelText asString ] ].
	^ texts
]
