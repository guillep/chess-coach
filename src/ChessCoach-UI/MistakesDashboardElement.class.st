"
The landing of the right pane when no game is selected: my most frequent mistakes (bars coloured by category), the top tags per phase, a trend per block of 10 games, and the mistakes of a clicked tag. Clicking a mistake calls recordBlock with its MistakeRecord; the empty state offers startBlock.
"
Class {
	#name : 'MistakesDashboardElement',
	#superclass : 'ToElement',
	#instVars : [
		'database',
		'taxonomy',
		'content',
		'detail',
		'selectedTag',
		'recordBlock',
		'startBlock',
		'times',
		'speed',
		'speedBlock'
	],
	#category : 'ChessCoach-UI-Coach',
	#package : 'ChessCoach-UI',
	#tag : 'Coach'
}

{ #category : 'building' }
MistakesDashboardElement >> buildBars [
	"The 8 most frequent tags as bars proportional to the most frequent one, coloured by category; a click shows the tag's mistakes"

	| frequencies top max |
	frequencies := database tagFrequencies.
	top := frequencies associations first: (frequencies size min: 8).
	top ifEmpty: [
		^ content addChild: (ToLabel text: 'No tags confirmed yet') ].
	max := top first value.
	top do: [ :each |
			| row |
			row := ToElement new
				       layout: (BlLinearLayout horizontal cellSpacing: 8);
				       hMatchParent;
				       vFitContent;
				       yourself.
			row
				addChild: (ToLabel new
						 text: (self nameOf: each key);
						 width: 200;
						 yourself);
				addChild: (BlElement new
						 extent: (each value / max * 600) rounded @ 14;
						 background: (self colorOfTag: each key);
						 yourself);
				addChild: (ToLabel text: each value printString).
			row
				addEventHandlerOn: BlClickEvent
				do: [ :event | self selectTag: each key ].
			content addChild: row ]
]

{ #category : 'building' }
MistakesDashboardElement >> buildDetail [

	detail addChild: (self title:
			 selectedTag , ': ' , (taxonomy tagAt: selectedTag) description).
	(database recordsWithTag: selectedTag) reverseDo: [ :record |
			detail addChild: (ToButton new
					 labelText: ('{1} · game {2}, move {3}: {4}' format: {
									  record date yyyymmdd.
									  record gameId.
									  (record ply + 1 // 2).
									  (record explanation ifNil: [ '' ]) });
					 clickAction: [ recordBlock value: record ];
					 yourself) ]
]

{ #category : 'building' }
MistakesDashboardElement >> buildEmptyState [

	content
		addChild: (ChessCoachWidgets logo: 128);
		addChild: (self title: 'Nothing to talk about yet');
		addChild: (ChessCoachWidgets paragraph:
					 'Pour a mate and pick a game. Press "New analysis", mark the moves you want to discuss, and I''ll ask about the moments that mattered. Your typical mistakes will show up here.');
		addChild: (ToButton new
				 labelText: 'Open my latest game';
				 clickAction: [ startBlock value ];
				 yourself)
]

{ #category : 'building' }
MistakesDashboardElement >> buildPhases [

	| byPhase |
	byPhase := database tagFrequenciesByPhase.
	#( 'opening' 'middlegame' 'endgame' ) do: [ :phase |
			| frequencies |
			frequencies := byPhase
				               at: phase
				               ifAbsent: [ OrderedDictionary new ].
			content addChild:
				(ToLabel text: phase capitalized , ': ' , (frequencies isEmpty
						  ifTrue: [ '—' ]
						  ifFalse: [
								  ', ' join:
									  ((frequencies associations first: (frequencies size min: 3))
										   collect: [ :each |
										   (self nameOf: each key) , ' ×' , each value printString ]) ])) ]
]

{ #category : 'building' }
MistakesDashboardElement >> buildTimes [

	| kinds |
	kinds := [ :associations |
		         ', ' join: (associations asArray
				          sort: [ :a :b | a key < b key ];
				          collect: [ :each |
						          (ChessCoachWidgets humanize: each key) , ' '
						          , (self duration: each value) ]) ].
	content addChild: (ChessCoachWidgets paragraph:
			 'Per reviewed moment: ' , (self duration: times secondsPerMoment)
			 , ' (' , (kinds value: times secondsPerMomentKind associations)
			 , ')').
	content addChild: (ChessCoachWidgets paragraph: 'Per question: '
			 , (kinds value: times secondsPerQuestionKind associations)).
	content addChild: (ToLabel text:
			 'Marking pass: ' , (self duration: times markingSecondsPerGame)
			 , ' per game, ' , (self duration: times markingSecondsPerPly)
			 , ' per move').
	content addChild: (ToLabel text: 'Time per moment (blocks of 10)  '
			 , (self sparkline: (times secondsPerMomentInBlocksOf: 10)))
]

{ #category : 'building' }
MistakesDashboardElement >> buildTrend [
	"Small bars per top tag: one bar per block of 10 games, taller when the tag was more frequent. One block shows no trend yet."

	| blocks top |
	blocks := database tagFrequenciesByGames: 10.
	blocks size < 2 ifTrue: [
			^ content addChild:
				  (ToLabel text: 'A trend needs more than 10 reviewed games.') ].
	top := database tagFrequencies keys first:
		       (database tagFrequencies size min: 3).
	top do: [ :tag |
			| counts max row |
			counts := blocks collect: [ :each | each at: tag ifAbsent: [ 0 ] ].
			max := counts max max: 1.
			row := ToElement new
				       layout:
					       (BlLinearLayout horizontal alignBottomLeft cellSpacing: 3);
				       hMatchParent;
				       vFitContent;
				       addChild: (ToLabel new
						        text: (self nameOf: tag);
						        width: 200;
						        yourself);
				       yourself.
			counts do: [ :each |
					row addChild: (BlElement new
							 extent: 14 @ (each / max * 18) rounded + 2;
							 background: (self colorOfTag: tag);
							 yourself) ].
			content addChild: row ]
]

{ #category : 'actions' }
MistakesDashboardElement >> chooseSpeed: aSpeedOrNil [
	"Called from a speed toggle's check action. The page, toggles included, is rebuilt in a later task, not while the toggle runs its action."

	speed := aSpeedOrNil.
	speedBlock ifNil: [ ^ self ].
	self enqueueTask:
		(BlTaskAction new action: [ speedBlock value: aSpeedOrNil ])
]

{ #category : 'private' }
MistakesDashboardElement >> colorOfTag: aTagId [
	"The category colours, from the icon's palette, readable on both themes"

	| category |
	category := (taxonomy tagAt: aTagId) category.
	category = 'perception' ifTrue: [ ^ Color fromHexString: '#4f9a6a' ].
	category = 'calculation' ifTrue: [ ^ Color fromHexString: '#e0a458' ].
	category = 'evaluation' ifTrue: [ ^ Color fromHexString: '#a3b85c' ].
	category = 'decision' ifTrue: [ ^ Color fromHexString: '#b5652b' ].
	^ Color fromHexString: '#a08a6c'
]

{ #category : 'accessing' }
MistakesDashboardElement >> content [

	^ content
]

{ #category : 'accessing' }
MistakesDashboardElement >> database: aMistakeDatabase [

	database := aMistakeDatabase.
	selectedTag := nil.
	self rebuild
]

{ #category : 'accessing' }
MistakesDashboardElement >> database: aMistakeDatabase times: aReviewTimes [

	database := aMistakeDatabase.
	times := aReviewTimes.
	selectedTag := nil.
	self rebuild
]

{ #category : 'accessing' }
MistakesDashboardElement >> detail [

	^ detail
]

{ #category : 'private' }
MistakesDashboardElement >> duration: seconds [

	seconds < 60 ifTrue: [ ^ seconds rounded printString , ' s' ].
	^ (seconds // 60) printString , ' min '
	  , (seconds \\ 60) rounded printString , ' s'
]

{ #category : 'initialization' }
MistakesDashboardElement >> initialize [

	| page |
	super initialize.
	taxonomy := MistakeTaxonomy default.
	database := MistakeDatabase withRecords: #(  ).
	recordBlock := [ :record |  ].
	startBlock := [ ].
	self layout: BlFrameLayout new.
	self matchParent.
	content := ToElement new
		           layout: (BlLinearLayout vertical cellSpacing: 6);
		           hMatchParent;
		           vFitContent;
		           yourself.
	detail := ToElement new
		          layout: (BlLinearLayout vertical cellSpacing: 4);
		          hMatchParent;
		          vFitContent;
		          yourself.
	page := ToElement new
		        layout: (BlLinearLayout vertical cellSpacing: 10);
		        hMatchParent;
		        vFitContent;
		        padding: (BlInsets right: 16);
		        addChild: content;
		        addChild: detail;
		        yourself.
	self addChild: (ChessCoachWidgets
			 page: 'Stats'
			 subtitle:
			 'Your typical mistakes and how long your reviews take, from every review with the coach.'
			 body: (ChessCoachWidgets scrollable: page)).
	self rebuild
]

{ #category : 'private' }
MistakesDashboardElement >> nameOf: aTagId [

	^ (taxonomy tagAt: aTagId) name
]

{ #category : 'building' }
MistakesDashboardElement >> rebuild [

	content removeChildren.
	detail removeChildren.
	content addChild: (ChessCoachWidgets
			 speedBar: speed
			 do: [ :each | self chooseSpeed: each ]).
	database records ifEmpty: [
			^ speed ifNil: [ self buildEmptyState ] ifNotNil: [
					  content addChild: (ChessCoachWidgets paragraph:
							   'No reviewed mistakes in games of this time control yet.') ] ].
	self
		section: 'Your most frequent mistakes'
		help:
		'The mistake types you confirmed (or didn''t reject) most often. Click a bar to see those mistakes. The colours are the categories. Perception (green): you didn''t see something. Calculation (gold): you saw it but calculated badly. Evaluation (yerba green): you judged the position wrongly. Decision (mate brown): your process failed, such as no blunder check, impulse, the clock or nerves. Knowledge (taupe): you didn''t know the opening, endgame or pattern.'
		build: [ self buildBars ].
	self
		section: 'By phase'
		help:
		'The three most frequent mistake types in the opening (first 12 moves), the middlegame and the endgame (6 or fewer pieces).'
		build: [ self buildPhases ].
	self
		section: 'Trend'
		help:
		'One bar per block of 10 games, oldest first: the taller the bar, the more often the mistake appeared, for each of your top mistake types.'
		build: [ self buildTrend ].
	(times notNil and: [ times reviewedMomentCount > 0 ]) ifTrue: [
			self
				section: 'Time'
				help:
				'Averages over every reviewed moment, of every time control: per moment kind, per question, and for the marking pass. The last line shows how the time per moment changes, block by block.'
				build: [ self buildTimes ] ].
	selectedTag ifNotNil: [ self buildDetail ]
]

{ #category : 'building' }
MistakesDashboardElement >> section: aTitle help: aHelpString build: aBlock [
	"Build a section into a bordered group: aBlock adds its rows to content, which points to the group meanwhile"

	| page box |
	page := content.
	box := ChessCoachWidgets
		       section: aTitle
		       help: aHelpString
		       rows: #(  ).
	content := box.
	aBlock ensure: [ content := page ].
	content addChild: box
]

{ #category : 'actions' }
MistakesDashboardElement >> selectTag: aTagId [

	selectedTag := aTagId.
	detail removeChildren.
	self buildDetail
]

{ #category : 'private' }
MistakesDashboardElement >> sparkline: someCounts [
	"One digit per value, 0 to 9, relative to the largest one"

	| max |
	max := someCounts max max: 1.
	^ ' ' join:
		  (someCounts collect: [ :each |
			   (each / max * 9) rounded printString ])
]

{ #category : 'accessing' }
MistakesDashboardElement >> speed [
	"The time control shown (nil for all games)"

	^ speed
]

{ #category : 'accessing' }
MistakesDashboardElement >> texts [
	"Every label and paragraph text shown, in order (for tests)"

	| texts |
	texts := OrderedCollection new.
	self allChildrenBreadthFirstDo: [ :each |
			(each isKindOf: ToLabel) ifTrue: [ texts add: each text asString ].
			(ChessCoachWidgets paragraphTextOf: each) ifNotNil: [ :text |
				texts add: text ] ].
	^ texts
]

{ #category : 'private' }
MistakesDashboardElement >> title: aString [

	^ ToLabel new
		  text: (aString asRopedText
				   bold;
				   yourself);
		  yourself
]

{ #category : 'accessing' }
MistakesDashboardElement >> whenRecordSelectedDo: aBlock [
	"aBlock receives the MistakeRecord I click in a tag's detail"

	recordBlock := aBlock
]

{ #category : 'accessing' }
MistakesDashboardElement >> whenSpeedChosenDo: aBlock [
	"aBlock receives the chosen time control (nil for all games) and gives me the matching database"

	speedBlock := aBlock
]

{ #category : 'accessing' }
MistakesDashboardElement >> whenStartRequestedDo: aBlock [
	"aBlock runs when I ask, from the empty state, to review my latest analysed game"

	startBlock := aBlock
]
