"
The right pane when a game is selected: the game replayed on a board with its move list (GameAnalysisElement, no engine evaluation), the list of my coach reviews of it, and ""New analysis"". openBlock receives the review to open.
"
Class {
	#name : 'GameReviewsElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'entry',
		'game',
		'replay',
		'reviewsZone',
		'openBlock'
	],
	#category : 'ChessCoach-UI-Coach',
	#package : 'ChessCoach-UI',
	#tag : 'Coach'
}

{ #category : 'accessing' }
GameReviewsElement >> board [

	^ replay boardElement
]

{ #category : 'private' }
GameReviewsElement >> describe: aCoachReview [
	"'Analysis 1 · 2026-10-12 · 4/7 moments reviewed'"

	^ 'Analysis {1} · {2} · {3}' format: {
			  aCoachReview number.
			  aCoachReview date yyyymmdd.
			  (aCoachReview isMarking
				   ifTrue: [ 'marking' ]
				   ifFalse: [
						   aCoachReview reviewedMoments size printString , '/'
						   ,
							   (aCoachReview momentsPassing: session settings momentFilter)
								   size printString , ' moments reviewed' ]) }
]

{ #category : 'initialization' }
GameReviewsElement >> initialize [

	| panel |
	super initialize.
	openBlock := [ :review |  ].
	self layout: BlLinearLayout horizontal.
	self matchParent.
	replay := GameAnalysisElement new.
	reviewsZone := ToElement new
		               layout: (BlLinearLayout vertical cellSpacing: 6);
		               hMatchParent;
		               vFitContent;
		               yourself.
	panel := ToElement new
		         layout: (BlLinearLayout vertical cellSpacing: 10);
		         width: 300;
		         vMatchParent;
		         padding: (BlInsets all: 10);
		         yourself.
	panel
		addChild: (ToLabel text: 'Analyses with the coach');
		addChild: reviewsZone;
		addChild: (ToButton new
				 labelText: 'New analysis';
				 clickAction: [ self newAnalysis ];
				 yourself).
	self
		addChild: replay;
		addChild: panel
]

{ #category : 'actions' }
GameReviewsElement >> newAnalysis [

	openBlock value: (session newReviewFor: entry)
]

{ #category : 'accessing' }
GameReviewsElement >> reviewsZone [

	^ reviewsZone
]

{ #category : 'accessing' }
GameReviewsElement >> session: aChessCoachSession entry: aGameIndexEntry [

	| colors |
	session := aChessCoachSession.
	entry := aGameIndexEntry.
	game := session gameFor: aGameIndexEntry.
	colors := session myColorsIn: game.
	self board orientation: (colors size = 1
			 ifTrue: [ colors first ]
			 ifFalse: [ #white ]).
	replay game: game.
	self updateReviews
]

{ #category : 'updating' }
GameReviewsElement >> updateReviews [

	| reviews |
	reviewsZone removeChildren.
	reviews := session reviewsFor: entry.
	reviews ifEmpty: [
		^ reviewsZone addChild: (ToLabel text: 'No analysis yet.') ].
	reviews do: [ :review |
			reviewsZone addChild: (ToButton new
					 labelText: (self describe: review);
					 clickAction: [ openBlock value: review ];
					 yourself) ]
]

{ #category : 'accessing' }
GameReviewsElement >> whenOpenDo: aBlock [
	"aBlock receives the CoachReview to open"

	openBlock := aBlock
]
