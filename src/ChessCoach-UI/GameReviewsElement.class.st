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
		'reviewsZone',
		'openBlock',
		'timeBoxNote',
		'infoZone',
		'playThroughBlock',
		'timeBoxMinutes',
		'timeBoxButtons'
	],
	#category : 'ChessCoach-UI-Coach',
	#package : 'ChessCoach-UI',
	#tag : 'Coach'
}

{ #category : 'private' }
GameReviewsElement >> analysisStateText [

	| state |
	(session isAnalysed: entry) ifTrue: [ ^ 'analysed' ].
	state := session analysisQueue stateOf: entry.
	state = #analysing ifTrue: [ ^ 'analysing now' ].
	state = #queued ifTrue: [ ^ 'waiting in the queue' ].
	^ 'not analysed yet'
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

{ #category : 'private' }
GameReviewsElement >> infoLines [
	"One line per known PGN header, then the number of moves and the Stockfish analysis state"

	| headers lines player opening |
	headers := game metadata.
	lines := OrderedCollection new.
	player := [ :color |
		          (headers at: color ifAbsent: [ '?' ])
		          , ((headers at: color , 'Elo' ifAbsent: [ nil ])
				           ifNil: [ '' ]
				           ifNotNil: [ :elo | ' (' , elo , ')' ]) ].
	lines
		add: 'White: ' , (player value: 'White');
		add: 'Black: ' , (player value: 'Black').
	headers
		at: 'Result'
		ifPresent: [ :result | lines add: 'Result: ' , result ].
	(headers
		 at: 'UTCDate'
		 ifAbsent: [ headers at: 'Date' ifAbsent: [ nil ] ]) ifNotNil: [
		:date | lines add: 'Date: ' , date ].
	headers at: 'TimeControl' ifPresent: [ :timeControl |
		lines add: 'Time control: ' , timeControl , ' (' , game speed , ')' ].
	opening := headers at: 'Opening' ifAbsent: [ nil ].
	headers at: 'ECO' ifPresent: [ :eco |
		opening := opening ifNil: [ eco ] ifNotNil: [ eco , ' ' , opening ] ].
	opening ifNotNil: [ lines add: 'Opening: ' , opening ].
	(headers
		 at: 'Link'
		 ifAbsent: [ headers at: 'Site' ifAbsent: [ nil ] ]) ifNotNil: [
		:site | lines add: 'Site: ' , site ].
	lines add: 'Moves: ' , (game moves size + 1 // 2) printString.
	lines add: 'Stockfish: ' , self analysisStateText.
	^ lines
]

{ #category : 'initialization' }
GameReviewsElement >> initialize [
	"The selected game: its information on top, its analyses with the coach in the middle, and the two main actions at the bottom"

	| analyses actions |
	super initialize.
	openBlock := [ :review |  ].
	playThroughBlock := [ ].
	self layout: (BlLinearLayout vertical cellSpacing: 12).
	self matchParent.
	self padding: (BlInsets
			 top: 0
			 left: 12
			 bottom: 8
			 right: 12).
	infoZone := ToElement new
		            layout: (BlLinearLayout vertical cellSpacing: 4);
		            hMatchParent;
		            vFitContent;
		            yourself.
	reviewsZone := ToElement new
		               layout: (BlLinearLayout vertical cellSpacing: 6);
		               hMatchParent;
		               vFitContent;
		               yourself.
	timeBoxNote := ToLabel text: ''.
	analyses := (ChessCoachWidgets
		             section: 'Analyses with the coach'
		             help:
			             'Each analysis is one pass with the coach: you mark the moves you found interesting, then answer questions about the important moments. Click one to continue it or look at it again.'
		             rows: { (ChessCoachWidgets scrollable: reviewsZone) })
		            vMatchParent;
		            yourself.
	actions := ToElement new
		           layout: (BlLinearLayout vertical cellSpacing: 8);
		           hMatchParent;
		           vFitContent;
		           addChild: (ChessCoachWidgets
				            bigButton: 'Play through'
				            icon: 'outlined_slideshow'
				            do: [ playThroughBlock value ]);
		           addChild: self newTimeBoxChoice;
		           addChild: timeBoxNote;
		           addChild: (ChessCoachWidgets
				            bigButton: 'New analysis'
				            icon: 'outlined_school'
				            do: [ self newAnalysis ]);
		           yourself.
	self
		addChild: (ChessCoachWidgets
				 section: 'Game'
				 help:
					 'From the game''s PGN headers. Stockfish shows the state of the analysis, which the end of the marking pass needs.'
				 rows: { infoZone });
		addChild: analyses;
		addChild: actions
]

{ #category : 'building' }
GameReviewsElement >> linkTo: aUrl [
	"A blue text element rather than a label: the label skin replaces the text colour. Blue reads on light and dark themes."

	^ BlTextElement new
		  text: (('Site: ' , aUrl) asRopedText
				   foreground: (Color fromHexString: '#3b82f6');
				   yourself);
		  mouseCursor: Cursor webLink;
		  addEventHandlerOn: BlClickEvent
		  do: [ :event | WebBrowser openOn: aUrl ];
		  yourself
]

{ #category : 'actions' }
GameReviewsElement >> newAnalysis [
	"Start a review, limited to the chosen time box when there is one"

	openBlock value: (session
			 newReviewFor: entry
			 timeBox: (session canTimeBox ifTrue: [ timeBoxMinutes ]))
]

{ #category : 'building' }
GameReviewsElement >> newTimeBoxChoice [
	"Toggle buttons for the time box of a new analysis, wrapping when narrow: none, or a number of minutes. A Toplo checkable group keeps exactly one checked."

	| row group |
	row := ToElement new
		       layout: BlFlowLayout horizontal;
		       hMatchParent;
		       vFitContent;
		       addChild: ((ToLabel text: 'Time box:')
				        margin: (BlInsets right: 8);
				        yourself);
		       yourself.
	group := ToCheckableGroup new.
	timeBoxButtons := OrderedCollection new.
	#( nil 10 20 30 45 60 ) do: [ :minutes |
			| button |
			button := ToToggleButton new
				          labelText:
					          (minutes
						           ifNil: [ 'None' ]
						           ifNotNil: [ minutes printString , ' min' ]);
				          yourself.
			group register: button.
			button newCheckAction: [
				button isChecked ifTrue: [ timeBoxMinutes := minutes ] ].
			timeBoxButtons add: button.
			row addChild: button ].
	timeBoxButtons first check.
	^ row
]

{ #category : 'accessing' }
GameReviewsElement >> reviewsZone [

	^ reviewsZone
]

{ #category : 'accessing' }
GameReviewsElement >> session: aChessCoachSession entry: aGameIndexEntry [

	session := aChessCoachSession.
	entry := aGameIndexEntry.
	game := session gameFor: aGameIndexEntry.
	timeBoxButtons do: [ :each | each enabled: session canTimeBox ].
	timeBoxNote text: (session canTimeBox
			 ifTrue: [ '' ]
			 ifFalse: [ 'The time box needs a few finished reviews first.' ]).
	self updateInfo.
	self updateReviews
]

{ #category : 'updating' }
GameReviewsElement >> updateInfo [
	"The site is a link that opens the game in the web browser"

	infoZone removeChildren.
	self infoLines do: [ :line |
			infoZone addChild: ((line beginsWith: 'Site: http')
					 ifTrue: [ self linkTo: (line allButFirst: 'Site: ' size) ]
					 ifFalse: [ ChessCoachWidgets paragraph: line ]) ]
]

{ #category : 'updating' }
GameReviewsElement >> updateReviews [
	"The right padding keeps the scrollbar off the delete buttons"

	| reviews |
	reviewsZone removeChildren.
	reviewsZone padding: (BlInsets right: 16).
	reviews := session reviewsFor: entry.
	reviews ifEmpty: [
		^ reviewsZone addChild: (ToLabel text: 'No analysis yet.') ].
	reviews do: [ :review |
			reviewsZone addChild: (ToElement new
					 layout: (BlLinearLayout horizontal cellSpacing: 8);
					 hMatchParent;
					 vFitContent;
					 addChild: (ToButton new
							  labelText: (self describe: review);
							  clickAction: [ openBlock value: review ];
							  yourself);
					 addChild: (ToButton new
							  icon:
								  ((ToMaterialDesignIconProvider iconNamed: 'outlined_delete')
									   extent: 16 @ 16;
									   yourself);
							  tooltipText: 'Delete this analysis';
							  clickAction: [
									  session deleteReview: review.
									  self updateReviews ];
							  yourself);
					 yourself) ]
]

{ #category : 'accessing' }
GameReviewsElement >> whenOpenDo: aBlock [
	"aBlock receives the CoachReview to open"

	openBlock := aBlock
]

{ #category : 'accessing' }
GameReviewsElement >> whenPlayThroughDo: aBlock [

	playThroughBlock := aBlock
]
