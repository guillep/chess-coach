"
The Help page. What it says about mistake types comes from the taxonomy and what it says about heuristics from the current thresholds, so it can't go out of date.
"
Class {
	#name : 'HelpElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'zone'
	],
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'accessing' }
HelpElement >> heuristicsText [
	"With the current thresholds, which Settings change"

	^ {
		  ('Evaluation drops compare the winning chances before and after your move, according to Stockfish. Losing {1} points of win percentage is an inaccuracy, {2} a mistake and {3} a blunder. Allowing a forced mate is always a blunder.' format: {
				   (self threshold: 'momentInaccuracyDrop').
				   (self threshold: 'momentMistakeDrop').
				   (self threshold: 'momentBlunderDrop') }).
		  ('Only moves are positions where the best move beats the second by at least {1} points of win percentage while something is at stake. The moment says whether you found it.' format: {
				   (self threshold: 'momentOnlyMoveGap') }).
		  ('Long thinks are moves that took at least {1} seconds and {2} times your average in that game. Games without clocks have none.' format: {
				   (self threshold: 'momentLongThinkSeconds').
				   (self threshold: 'momentLongThinkFactor') }).
		  ('Opening choices compare your move with the Lichess database at your rating and time control. A move is a moment when it scores {1} points or more below the best move, or is rarely played while others are common. Moves need {2} games to count, and the comparison stops when a position has fewer.' format: {
				   (self threshold: 'momentOpeningScoreGap').
				   (self threshold: 'momentOpeningMinimumGames') }).
		  'Each of these can be turned off or tuned in Settings, under Analysis.' }
]

{ #category : 'initialization' }
HelpElement >> initialize [

	super initialize.
	self layout: BlFrameLayout new.
	self matchParent.
	zone := ToElement new
		        layout: (BlLinearLayout vertical cellSpacing: 8);
		        hMatchParent;
		        vFitContent;
		        padding: (BlInsets right: 16);
		        yourself.
	self addChild: (ChessCoachWidgets
			 page: 'Help'
			 subtitle: 'How the coach thinks.'
			 body: (ChessCoachWidgets scrollable: zone)).
	self
		addEventHandlerOn: BlElementAddedToSceneGraphEvent
		do: [ :event | session ifNotNil: [ self update ] ]
]

{ #category : 'accessing' }
HelpElement >> mistakeTypesText [
	"Each category with what it means and its types, from the taxonomy"

	| tags |
	tags := MistakeTaxonomy default tags.
	^ {
		  ('perception' -> 'You didn''t see something.').
		  ('calculation' -> 'You saw it but calculated badly.').
		  ('evaluation' -> 'You judged the position wrongly.').
		  ('decision' -> 'Your process failed: no blunder check, impulse, the clock or nerves.').
		  ('knowledge' -> 'You didn''t know the opening, endgame or pattern.') } flatCollect: [ :category |
		  { (category key capitalized , ': ' , category value) } , ((tags select: [ :tag |
			    tag category = category key ]) collect: [ :tag |
			   tag name , ': ' , tag description ]) ]
]

{ #category : 'accessing' }
HelpElement >> momentsText [

	^ {
		  'A moment is a move of your game worth thinking about again. After you mark the moves you found interesting, the coach adds the ones it finds, and goes through them in game order.'.
		  'For each moment it asks questions before showing the engine: what you considered, why you played your move and what you expected. Then it shows what the engine thinks and proposes mistake types, which you confirm or reject.'.
		  'The moves you mark are always moments. A time box stops the review before the next moment once its time is up.' }
]

{ #category : 'accessing' }
HelpElement >> session: aChessCoachSession [

	session := aChessCoachSession.
	self update
]

{ #category : 'accessing' }
HelpElement >> threshold: aKey [

	^ (session settings at: aKey) printString
]

{ #category : 'accessing' }
HelpElement >> topics [
	"Title -> paragraphs; the first topic starts open"

	^ {
		  ('What are moments?' -> self momentsText).
		  ('How moments are found' -> self heuristicsText).
		  ('Mistake types' -> self mistakeTypesText) }
]

{ #category : 'updating' }
HelpElement >> update [

	zone removeChildren.
	self topics doWithIndex: [ :topic :index |
		| accordion |
		accordion := ToAccordionElement new
			             id: topic key asSymbol;
			             yourself.
		accordion headerBuilder: [ :header |
			header addChild: (ToLabel text: topic key) ].
		accordion bodyBuilder: [ :body |
			| column |
			column := ToElement new
				          layout: (BlLinearLayout vertical cellSpacing: 8);
				          hMatchParent;
				          vFitContent;
				          padding: (BlInsets all: 8);
				          yourself.
			topic value do: [ :each |
				column addChild: (ChessCoachWidgets paragraph: each) ].
			body addChild: column ].
		index = 1 ifTrue: [ accordion expand ].
		zone addChild: accordion ]
]
