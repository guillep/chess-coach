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
		'startBlock'
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
					 'Select a game and press "Review with coach". The coach asks about the important moments of the game and keeps track of your mistakes here.';
				 yourself);
		addChild: (ToButton new
				 labelText: 'Review my latest game';
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
MistakesDashboardElement >> detail [

	^ detail
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
	database records ifEmpty: [ ^ self buildEmptyState ].
	content addChild: (self title: 'Your most frequent mistakes').
	self buildBars.
	content addChild: (self title: 'By phase').
	self buildPhases.
	content addChild:
		(self title: 'Trend (blocks of 10 games, oldest first)').
	self buildTrend.
	selectedTag ifNotNil: [ self buildDetail ]
]

{ #category : 'actions' }
MistakesDashboardElement >> selectTag: aTagId [

	selectedTag := aTagId.
	detail removeChildren.
	self buildDetail
]

{ #category : 'private' }
MistakesDashboardElement >> sparkline: someCounts [

	| bars max |
	bars := '▁▂▃▄▅▆▇█'.
	max := someCounts max max: 1.
	^ String withAll: (someCounts collect: [ :each |
			   bars at: (each / max * (bars size - 1)) rounded + 1 ])
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
