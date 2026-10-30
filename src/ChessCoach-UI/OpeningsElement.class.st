"
I am the Openings page: the saved opening trees and the form that builds a new one.
"
Class {
	#name : 'OpeningsElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'backgroundRunner',
		'openBlock',
		'treesZone',
		'nameField',
		'fromField',
		'toField',
		'ratingField',
		'color',
		'speed',
		'databaseSource',
		'databaseSpeed',
		'periodSelect',
		'ratingSelect'
	],
	#category : 'ChessCoach-UI-Openings',
	#package : 'ChessCoach-UI',
	#tag : 'Openings'
}

{ #category : 'accessing' }
OpeningsElement >> backgroundRunner: aBlock [

	backgroundRunner := aBlock
]

{ #category : 'building' }
OpeningsElement >> build [

	| content |
	treesZone := ToElement new
		             layout: (BlLinearLayout vertical cellSpacing: 8);
		             hMatchParent;
		             vFitContent;
		             yourself.
	content := ToElement new
		           layout: (BlLinearLayout vertical cellSpacing: 12);
		           hMatchParent;
		           vFitContent;
		           padding: (BlInsets right: 16);
		           addChild: (ChessCoachWidgets
				            section: 'Saved trees'
				            help:
					            'A saved tree keeps its numbers until you rebuild it, so it opens at once.'
				            rows: { treesZone });
		           addChild: self newForm;
		           yourself.
	self removeChildren.
	self addChild: (ChessCoachWidgets
			 page: 'Openings'
			 subtitle:
			 'Trees of your games, compared with the Lichess database, to find your weak spots.'
			 body: (ChessCoachWidgets scrollable: content)).
	self updateTrees
]

{ #category : 'actions' }
OpeningsElement >> buildTree [
	"The tree page builds it and shows the progress"

	openBlock value: self newTree
]

{ #category : 'initialization' }
OpeningsElement >> initialize [

	super initialize.
	self layout: BlFrameLayout new.
	self matchParent.
	backgroundRunner := [ :aBlock |
	                    aBlock forkAt: Processor userBackgroundPriority ].
	openBlock := [ :tree |  ].
	color := #white.
	databaseSource := 'lichess'
]

{ #category : 'building' }
OpeningsElement >> newChoiceBar: someAssociations selected: aValue do: aBlock [
	"Toggle buttons for label -> value associations, one checked, in one row"

	| bar group |
	bar := ToElement new
		       layout: BlLinearLayout horizontal;
		       fitContent;
		       yourself.
	group := ToCheckableGroup new.
	someAssociations do: [ :each |
			| button |
			button := ToToggleButton new
				          labelText: each key;
				          yourself.
			group register: button.
			each value = aValue ifTrue: [ button check ].
			button newCheckAction: [
				button isChecked ifTrue: [ aBlock value: each value ] ].
			bar addChild: button ].
	^ bar
]

{ #category : 'building' }
OpeningsElement >> newForm [

	nameField := ToTextField new
		             hMatchParent;
		             yourself.
	periodSelect := self newSelect: {
			                ('Always' -> nil).
			                ('Today' -> 0).
			                ('Last week' -> 7).
			                ('Last month' -> 30).
			                ('Last year' -> 365) }.
	ratingSelect := self newSelect: {
			                ('Any rating' -> #(  )).
			                ('Under 1000' -> #( 0 )).
			                ('1000–1199' -> #( 1000 )).
			                ('1200–1399' -> #( 1200 )).
			                ('1400–1599' -> #( 1400 )).
			                ('1600–1799' -> #( 1600 )).
			                ('1800–1999' -> #( 1800 )).
			                ('2000–2199' -> #( 2000 )).
			                ('2200–2499' -> #( 2200 )).
			                ('2500 and up' -> #( 2500 )) }.
	^ ChessCoachWidgets
		  section: 'New tree'
		  help:
		  'Choose your games, then the database to compare with. The period counts back from each build, so Rebuild moves it forward.'
		  rows: {
				  (ToLabel text: 'Name').
				  nameField.
				  (ToLabel text: 'Colour').
				  (self
					   newChoiceBar: {
							   ('White' -> #white).
							   ('Black' -> #black) }
					   selected: color
					   do: [ :each | color := each ]).
				  (ToLabel text: 'Time control').
				  (ChessCoachWidgets speedBar: speed do: [ :each | speed := each ]).
				  (ToLabel text: 'Period').
				  periodSelect.
				  (ToLabel text: 'Database').
				  (self
					   newChoiceBar: {
							   ('Lichess players' -> 'lichess').
							   ('Masters' -> 'masters') }
					   selected: databaseSource
					   do: [ :each | databaseSource := each ]).
				  (ToLabel text: 'Database time control').
				  (ChessCoachWidgets
					   speedBar: databaseSpeed
					   do: [ :each | databaseSpeed := each ]).
				  (ToLabel text: 'Database rating').
				  ratingSelect.
				  (ChessCoachWidgets
					   primaryButton: 'Build tree'
					   icon: 'filled_arrowforward'
					   do: [ self buildTree ]) }
]

{ #category : 'building' }
OpeningsElement >> newRowOf: anOpeningTree [
	"Open, rename and delete a tree"

	| field |
	field := ToTextField new
		         hMatchParent;
		         text: anOpeningTree name;
		         yourself.
	^ ToElement new
		  layout: (BlLinearLayout horizontal cellSpacing: 8);
		  hMatchParent;
		  vFitContent;
		  addChild: (ToButton new
				   labelText: ('{1} games · {2}' format: {
								    anOpeningTree gameCount.
								    anOpeningTree color });
				   clickAction: [ openBlock value: anOpeningTree ];
				   yourself);
		  addChild: field;
		  addChild: (ToButton new
				   labelText: 'Rename';
				   clickAction: [
						   anOpeningTree name: field text asString trimBoth.
						   session saveOpeningTree: anOpeningTree.
						   self updateTrees ];
				   yourself);
		  addChild: (ToButton new
				   icon:
					   ((ToMaterialDesignIconProvider iconNamed: 'outlined_delete')
						    extent: 16 @ 16;
						    yourself);
				   tooltipText: 'Delete this tree';
				   clickAction: [
						   session deleteOpeningTree: anOpeningTree.
						   self updateTrees ];
				   yourself);
		  yourself
]

{ #category : 'building' }
OpeningsElement >> newSelect: someAssociations [
	"A dropdown of label -> value associations with the first one selected"

	| select |
	select := ToSingleSelectElement new
		          hMatchParent;
		          yourself.
	select popupListElement nodeBuilder: [ :node :assoc :holder |
		node addChild: (ToLabel text: assoc key) ].
	select dataViewBuilder: [ :view :assoc |
		view addChild: (ToLabel text: assoc key) ].
	select popupDataAccessor addAll: someAssociations.
	select selecter selectIndex: 1.
	^ select
]

{ #category : 'actions' }
OpeningsElement >> newTree [

	| name |
	name := nameField text asString trimBoth.
	^ (OpeningTree
		   named:
			   (name ifEmpty: [ color asString capitalized , ' repertoire' ])
		   color: color
		   speed: speed
		   from: nil
		   to: nil
		   databaseSource: databaseSource
		   databaseSpeed: (databaseSpeed ifNil: [
						    ',' join:
								    (ChessCoachWidgets speeds allButFirst collect: [ :each |
										     each value ]) ])
		   ratings: (self valueOf: ratingSelect))
		  period: (self valueOf: periodSelect);
		  yourself
]

{ #category : 'accessing' }
OpeningsElement >> session: aChessCoachSession [

	session := aChessCoachSession.
	self build
]

{ #category : 'updating' }
OpeningsElement >> updateTrees [

	treesZone removeChildren.
	session openingTrees ifEmpty: [
		^ treesZone addChild: (ToLabel text: 'No trees yet.') ].
	session openingTrees do: [ :each |
		treesZone addChild: (self newRowOf: each) ]
]

{ #category : 'private' }
OpeningsElement >> valueOf: aSelect [

	^ aSelect selectedDataItem value
]

{ #category : 'accessing' }
OpeningsElement >> whenOpenDo: aBlock [
	"aBlock receives the tree to open"

	openBlock := aBlock
]
