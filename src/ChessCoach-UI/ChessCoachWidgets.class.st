"
The building blocks every page shares, so they look alike: page titles in a larger font, section headings, bordered groups of rows, and help icons whose tooltip explains the thing next to them.
"
Class {
	#name : 'ChessCoachWidgets',
	#superclass : 'MMWidgets',
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'mistakes' }
ChessCoachWidgets class >> categoryBar: someCounts scale: aMaximum width: aWidth [
	"A stacked bar, one segment per mistake category (category -> count), aMaximum mistakes filling aWidth pixels; each segment's tooltip gives its count"

	^ ToElement new
		  layout: BlLinearLayout horizontal;
		  fitContent;
		  addChildren: ((self mistakeCategories select: [ :category |
					    (someCounts at: category ifAbsent: [ 0 ]) > 0 ]) collect: [
						   :category |
						   | count |
						   count := someCounts at: category.
						   ToElement new
							   extent: (count / (aMaximum max: 1) * aWidth) rounded @ 14;
							   background: (self colorOfCategory: category);
							   tooltipString:
								   category capitalized , ': ' , count printString;
							   yourself ]);
		  yourself
]

{ #category : 'mistakes' }
ChessCoachWidgets class >> categoryLegend [
	"The colour of each mistake category"

	^ ToElement new
		  layout: BlFlowLayout horizontal;
		  hMatchParent;
		  vFitContent;
		  addChildren: (self mistakeCategories flatCollect: [ :category |
						   {
							   (BlElement new
								    extent: 12 @ 12;
								    margin: (BlInsets
										     top: 4
										     left: 8
										     bottom: 0
										     right: 4);
								    background: (self colorOfCategory: category);
								    yourself).
							   (ToLabel text: category capitalized) } ]);
		  yourself
]

{ #category : 'mistakes' }
ChessCoachWidgets class >> colorOfCategory: aCategory [
	"The mistake category colours, from the icon's palette, readable on both themes"

	aCategory = 'perception' ifTrue: [ ^ Color fromHexString: '#4f9a6a' ].
	aCategory = 'calculation' ifTrue: [ ^ Color fromHexString: '#e0a458' ].
	aCategory = 'evaluation' ifTrue: [ ^ Color fromHexString: '#a3b85c' ].
	aCategory = 'decision' ifTrue: [ ^ Color fromHexString: '#b5652b' ].
	^ Color fromHexString: '#a08a6c'
]

{ #category : 'building' }
ChessCoachWidgets class >> copyButton: aLabel tooltip: aTooltip text: aBlock [
	"A button that copies aBlock's text to the clipboard; it says 'copied' until the mouse leaves it"

	| button |
	button := ToButton new
		          labelText: aLabel;
		          icon:
			          ((ToMaterialDesignIconProvider iconNamed:
					            'outlined_contentcopy')
				           extent: 16 @ 16;
				           yourself);
		          tooltipText: aTooltip;
		          yourself.
	button clickAction: [
			Clipboard clipboardText: aBlock value.
			button labelText: aLabel , ' copied' ].
	button
		addEventHandlerOn: BlMouseLeaveEvent
		do: [ :event | button labelText: aLabel ].
	^ button
]

{ #category : 'building' }
ChessCoachWidgets class >> exportButtonsForBoard: aChessBoardElement game: aGame [
	"Copy the position shown on aChessBoardElement as FEN, and aGame as PGN"

	^ {
		  (self
			   copyButton: 'FEN'
			   tooltip: 'Copy the position on the board (FEN)'
			   text: [ aChessBoardElement chessPosition fen ]).
		  (self
			   copyButton: 'PGN'
			   tooltip: 'Copy the whole game (PGN)'
			   text: [ aGame pgn ]) }
]

{ #category : 'building' }
ChessCoachWidgets class >> logo: aSize [
	"The Chessmate icon, from the assets of the app's repository; an empty element without them"

	| element file |
	element := BlElement new
		           extent: aSize asPoint;
		           yourself.
	file := (IceRepository registry
		         detect: [ :each | each name = 'chess-coach' ]
		         ifNone: [ ^ element ]) location / 'assets'
	        / 'chessmate-128.png'.
	file exists ifFalse: [ ^ element ].
	^ element
		  background:
			  ((PNGReadWriter formFromFileNamed: file fullName) scaledToSize:
					   aSize asPoint);
		  yourself
]

{ #category : 'building' }
ChessCoachWidgets class >> logoIcon: aSize [
	"The Chessmate icon for a tab, or a plain home icon without the assets"

	| file |
	file := (IceRepository registry
		         detect: [ :each | each name = 'chess-coach' ]
		         ifNone: [
		         ^ self icon: 'outlined_home' extent: aSize asPoint ])
		        location / 'assets' / 'chessmate-128.png'.
	file exists ifFalse: [
		^ self icon: 'outlined_home' extent: aSize asPoint ].
	^ ToImage new
		  innerImage:
			  ((PNGReadWriter formFromFileNamed: file fullName) scaledToSize:
					   aSize asPoint);
		  extent: aSize asPoint;
		  yourself
]

{ #category : 'mistakes' }
ChessCoachWidgets class >> mistakeCategories [

	^ #( 'perception' 'calculation' 'evaluation' 'decision' 'knowledge' )
]

{ #category : 'building' }
ChessCoachWidgets class >> notificationRow: aNotification time: aTimeString onDismiss: aDismissBlock onShow: aShowBlock [
	"Show only for new games"

	^ super
		  notificationRow: aNotification
		  time: aTimeString
		  onDismiss: aDismissBlock
		  onShow: (aNotification kind = #newGames
				   ifTrue: [ aShowBlock ]
				   ifFalse: [ nil ])
]

{ #category : 'building' }
ChessCoachWidgets class >> speedBar: aSpeedOrNil do: aBlock [
	"The time controls, aSpeedOrNil chosen (nil is All); aBlock receives the chosen speed"

	^ self choiceBar: self speeds selected: aSpeedOrNil do: aBlock
]

{ #category : 'accessing' }
ChessCoachWidgets class >> speeds [
	"Label -> speed (nil for all games)"

	^ {
		  ('All' -> nil).
		  ('Bullet' -> 'bullet').
		  ('Blitz' -> 'blitz').
		  ('Rapid' -> 'rapid').
		  ('Classical' -> 'classical').
		  ('Daily' -> 'correspondence') }
]
