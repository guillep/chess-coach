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
		'times'
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
						 text: each key;
						 width: 200;
						 yourself);
				addChild: (BlElement new
						 extent: (each value / max * 240) rounded @ 14;
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
		addChild: (self title: 'No reviewed mistakes yet');
		addChild: (ToLabel new
				 beMultiLine;
				 hMatchParent;
				 text:
					 'Select a game and press "New analysis". You first mark the moves you want to talk about, then the coach asks about the important moments and keeps track of your mistakes here.';
				 yourself);
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
										   each key , ' ×' , each value printString ]) ])) ]
]

{ #category : 'building' }
MistakesDashboardElement >> buildTimes [

	content addChild: (ToLabel text:
			 'Per reviewed moment: ' , (self duration: times secondsPerMoment)
			 , ' ('
			 , (', ' join: (times secondsPerMomentKind associations asArray
						   sort: [ :a :b | a key < b key ];
						   collect: [ :each |
							   each key , ' ' , (self duration: each value) ])) , ')').
	content addChild: (ToLabel text: 'Per question: '
			 , (', ' join: (times secondsPerQuestionKind associations asArray
						   sort: [ :a :b | a key < b key ];
						   collect: [ :each |
							   each key , ' ' , (self duration: each value) ]))).
	content addChild: (ToLabel text:
			 'Marking pass: ' , (self duration: times markingSecondsPerGame)
			 , ' per game, ' , (self duration: times markingSecondsPerPly)
			 , ' per move').
	content addChild: (ToLabel text: 'Time per moment (blocks of 10)  '
			 , (self sparkline: (times secondsPerMomentInBlocksOf: 10)))
]

{ #category : 'building' }
MistakesDashboardElement >> buildTrend [
	"A text sparkline per top tag: one block per 10 games, higher when the tag was more frequent"

	| blocks top |
	blocks := database tagFrequenciesByGames: 10.
	top := database tagFrequencies keys first:
		       (database tagFrequencies size min: 3).
	top do: [ :tag |
			content addChild: (ToLabel text: tag , '  ' , (self sparkline:
						  (blocks collect: [ :each | each at: tag ifAbsent: [ 0 ] ]))) ]
]

{ #category : 'private' }
MistakesDashboardElement >> colorOfTag: aTagId [

	| category |
	category := (taxonomy tagAt: aTagId) category.
	category = 'perception' ifTrue: [ ^ Color fromHexString: '#4e79a7' ].
	category = 'calculation' ifTrue: [ ^ Color fromHexString: '#f28e2b' ].
	category = 'evaluation' ifTrue: [ ^ Color fromHexString: '#59a14f' ].
	category = 'decision' ifTrue: [ ^ Color fromHexString: '#e15759' ].
	^ Color fromHexString: '#9c755f'
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

	super initialize.
	taxonomy := MistakeTaxonomy default.
	database := MistakeDatabase withRecords: #(  ).
	recordBlock := [ :record |  ].
	startBlock := [ ].
	self layout: (BlLinearLayout vertical cellSpacing: 10).
	self matchParent.
	self padding: (BlInsets all: 16).
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
	self
		addChild: content;
		addChild: detail.
	self rebuild
]

{ #category : 'building' }
MistakesDashboardElement >> rebuild [

	content removeChildren.
	detail removeChildren.
	content addChild: (ChessCoachWidgets
			 pageTitle: 'Stats'
			 subtitle:
			 'Your typical mistakes and how long your reviews take, from every review with the coach.').
	database records ifEmpty: [ ^ self buildEmptyState ].
	self
		section: 'Your most frequent mistakes'
		help:
		'The mistake types you confirmed (or didn''t reject) most often. Click a bar to see those mistakes.'
		build: [ self buildBars ].
	self
		section: 'By phase'
		help:
		'The three most frequent mistake types in the opening (first 12 moves), the middlegame and the endgame (6 or fewer pieces).'
		build: [ self buildPhases ].
	self
		section: 'Trend'
		help:
		'One digit per block of 10 games, oldest first: 0 is the least frequent, 9 the most, for each of your top mistake types.'
		build: [ self buildTrend ].
	(times notNil and: [ times reviewedMomentCount > 0 ]) ifTrue: [
			self
				section: 'Time'
				help:
				'Averages over every reviewed moment: per moment kind, per question, and for the marking pass. The last line shows how the time per moment changes, block by block.'
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
MistakesDashboardElement >> texts [
	"Every label and button text shown, in order (for tests)"

	| texts |
	texts := OrderedCollection new.
	self allChildrenBreadthFirstDo: [ :each |
		(each isKindOf: ToLabel) ifTrue: [ texts add: each text asString ] ].
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
MistakesDashboardElement >> whenStartRequestedDo: aBlock [
	"aBlock runs when I ask, from the empty state, to review my latest analysed game"

	startBlock := aBlock
]
