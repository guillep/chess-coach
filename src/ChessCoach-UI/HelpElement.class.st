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

	| pawns equal winning decisive |
	pawns := [ :key |
	         (session settings at: key) / 100.0
		         printShowingDecimalPlaces: 1 ].
	equal := pawns value: 'zoneEqualCentipawns'.
	winning := pawns value: 'zoneWinningCentipawns'.
	decisive := pawns value: 'zoneDecisiveCentipawns'.
	^ {
		  ('Evaluation drops look at the zone of the evaluation before and after your move, from your side, according to Stockfish: equal (between -{1} and +{1} pawns), better or worse (up to {2}), winning or losing (up to {3}), decisive (beyond {3}, or a forced mate). Dropping two zones or more is a blunder; one zone in the middle (winning to better, better to equal, equal to worse, worse to losing) a mistake; one zone at an extreme (decisive to winning, losing to decisive against) an inaccuracy. Losing twice the equality limit or more without changing zone is an inaccuracy too, except when it stays decisive. A zone change counts only when the move lost at least {1} pawns. Allowing a forced mate is always a blunder.'
			   format: {
					   equal.
					   winning.
					   decisive }).
		  'Only moves are positions where every move but the best would have been a mistake or worse. Forced moves and plain recaptures (getting back the material just taken when nothing else does) are left out. The moment says whether you found it.'.
		  ('Long thinks are moves that took at least {1} seconds and {2} times your average in that game. Games without clocks have none.'
			   format: {
					   (self threshold: 'momentLongThinkSeconds').
					   (self threshold: 'momentLongThinkFactor') }).
		  ('Opening choices compare your move with the Lichess database at your rating and time control. A move is a moment when it scores {1} points or more below the best move, or is rarely played while others are common. Moves need {2} games to count, and the comparison stops when a position has fewer.'
			   format: {
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
	"Every topic open, as a plain group: the page scrolls"

	zone removeChildren.
	self topics do: [ :topic |
			| group |
			group := MMGroupElement new.
			group title: topic key help: nil.
			topic value do: [ :each |
				group rows addChild: (ChessCoachWidgets paragraph: each) ].
			zone addChild: group ]
]
