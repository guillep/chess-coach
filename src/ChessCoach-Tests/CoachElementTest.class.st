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
		(self zoneTexts includes: 'Move 2 (Nf3) · onlyMoveFound · −0%').
	self assert:
		(self zoneTexts includes: 'Move 4 (Ng5) · mistake · −18%').
	self
		assert: (coach stateIconNameOf: review moments last)
		equals: 'outlined_radiobuttonunchecked'.
	coach continueReview.
	scripter pulse.
	self assert: review currentQuestion kind equals: #whatDidYouSee.
	self assert: (self zoneTexts includes: 'I calculated the line').
	self answer: 'The bishop'.
	self assert:
		(self zoneTexts includes: 'Well found: no mistake to tag.').
	self assert: review moments first labels isEmpty.
	self
		assert: (coach stateIconNameOf: review moments first)
		equals: 'outlined_checkcircle'.
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
	self assert: (self zoneTexts includes: 'It looked natural').
	self deny: (self zoneTexts includes: 'I didn''t see it').
	coach addQuickAnswer: 'It looked natural'.
	coach addQuickAnswer: 'Intuition'.
	self
		assert: coach answerField text asString
		equals: 'It looked natural. Intuition'.
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
	self assert: (self zoneTexts includes: 'I didn''t see it').
	self
		assert: (self arrowsOfStyle: #subject) asArray
		equals: #( 'd2d4' ).
	3 timesRepeat: [ self answer: 'I did not see it' ].
	self assert: review currentMoment isRevealed.
	self assert: (self zoneTexts includes: 'Engine line (+0.50): d4').
	self assert:
		(self zoneTexts includes:
			 'Missed opponent threat · perception (70%)').
	self assert: review mistakeRecords first labels size equals: 1.
	self
		assert: (self arrowsOfStyle: #engine) asArray
		equals: #( 'd2d4' ).
	coach toggleTag: 'missed-opponent-threat'.
	self assert: review mistakeRecords first labels isEmpty.
	coach toggleTag: 'missed-opponent-threat'.
	self assert:
		(self zoneTexts includes: 'Missed opponent threat · perception').
	self assert: review mistakeRecords first labels size equals: 1.
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
		(self zoneTexts includes: 'Move 4 (Ng5) · mistake · −18%').
	self
		assert: (coach stateIconNameOf: moment)
		equals: 'outlined_timelapse'.
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

{ #category : 'tests' }
CoachElementTest >> testMarkingWithTheKeyboard [

	| fixture marking session keys |
	fixture := CoachReviewTest new.
	fixture setUp.
	marking := fixture newReviewMarking.
	session := (LichessAPIClientStub withGames: 0) newSessionOn:
		           FileSystem memory root.
	coach := CoachElement new.
	coach session: session entry: nil review: marking.
	keys := BlDevScripter new.
	keys element: coach.
	keys space extent: 1100 @ 700.
	self assert: coach mode equals: #marking.
	keys keyClick: KeyboardKey right.
	keys keyClick: KeyboardKey right.
	keys keyClick: KeyboardKey enter.
	keys syncContinue.
	self assert: (marking isMarked: 2).
	self assert: (coach replay moveList moveTexts at: 2) equals: '*e5'.
	keys keyClick: KeyboardKey space.
	keys syncContinue.
	self deny: (marking isMarked: 2).
	self assert: (coach replay moveList moveTexts at: 2) equals: 'e5'
]

{ #category : 'tests' }
CoachElementTest >> testReport [

	coach continueReview.
	self answer: 'The bishop'.
	coach nextMoment.
	coach submitMoves.
	self answer: 'Attack'.
	coach submitMoves.
	scripter pulse.
	[ review currentMoment isRevealed ] whileFalse: [ self answer: 'No' ].
	review classifyPending.
	coach nextMoment.
	scripter pulse.
	self assert: coach mode equals: #summary.
	self assert: (self zoneTexts includes: 'Reviewed 2 of 2 moments').
	self assert:
		(self zoneTexts includes: 'Mistakes 1 · Only moves found 1').
	self assert:
		(self zoneTexts includes: 'Perception: Missed opponent threat ×1').
	self assert: (self zoneTexts includes:
			 'Not enough earlier reviews to compare with yet.').
	self assert:
		(self zoneTexts anySatisfy: [ :each | each beginsWith: 'Total ' ])
]

{ #category : 'tests' }
CoachElementTest >> testReportAProblem [

	| session entry marking reportedCoach |
	session := (LichessAPIClientStub withGames: 1) newSessionOn:
		           FileSystem memory root.
	session login.
	session loadMoreGames.
	entry := session games first.
	marking := session newReviewFor: entry.
	reportedCoach := CoachElement new.
	reportedCoach session: session entry: entry review: marking.
	reportedCoach reportProblem.
	self assert: (reportedCoach message beginsWith: 'Report saved in ').
	self assert:
		(((session errorLog parent / 'reports') children first children
			  collect: [ :each | each basename ]) includesAll: {
				 'note.txt'.
				 (entry gameId , '.pgn').
				 'current-review-1.json' })
]

{ #category : 'helpers' }
CoachElementTest >> zoneTexts [
	"The texts of the labels, paragraphs and buttons in the current question zone"

	| texts |
	texts := OrderedCollection new.
	coach currentZone allChildrenBreadthFirstDo: [ :each |
			(each isKindOf: ToLabel) ifTrue: [ texts add: each text asString ].
			(each isKindOf: ToTextField) ifTrue: [
				texts add: each text asString ].
			(each isKindOf: ToButton) ifTrue: [
				texts add: each labelText asString ] ].
	^ texts
]
