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
