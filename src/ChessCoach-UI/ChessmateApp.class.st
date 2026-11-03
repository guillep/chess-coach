"
I declare Chessmate on the Mamotreto shell: its name, palette, pages, session and window, and the widgets of its Home.
"
Class {
	#name : 'ChessmateApp',
	#superclass : 'MMApp',
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'declaring' }
ChessmateApp >> dataDirectory [
	"Older than the shell's ~/.chessmate convention"

	^ FileLocator home / '.chess-coach'
]

{ #category : 'declaring' }
ChessmateApp >> homeWidgetClasses [

	^ {
		  HomeSuggestionsWidget.
		  HomeNumbersWidget.
		  HomeLatestGamesWidget.
		  HomeNotificationsWidget }
]

{ #category : 'declaring' }
ChessmateApp >> name [

	^ 'Chessmate'
]

{ #category : 'declaring' }
ChessmateApp >> pages [
	"Home (the logo), Stats, Games, Openings, Endgames, Settings and Help; the window builds their elements"

	^ {
		  (MMPage
			   named: 'Home'
			   icon: [ ChessCoachWidgets logoIcon: MMWidgets logoTabSize ]
			   build: [ :window | window home ]).
		  (MMPage
			   named: 'Stats'
			   icon: 'outlined_insights'
			   build: [ :window | window dashboard ]).
		  (MMPage
			   named: 'Games'
			   icon: 'outlined_managesearch'
			   build: [ :window | window gamesPage ]).
		  (MMPage
			   named: 'Openings'
			   icon: 'outlined_accounttree'
			   build: [ :window | window openings ]).
		  (MMPage
			   named: 'Endgames'
			   icon: 'outlined_flag'
			   build: [ :window | window endgamesElement ]).
		  (MMPage
			   named: 'Settings'
			   icon: 'outlined_settings'
			   build: [ :window | window settingsElement ]).
		  (MMPage
			   named: 'Help'
			   icon: 'outlined_helpoutline'
			   build: [ :window | window helpElement ]) }
]

{ #category : 'declaring' }
ChessmateApp >> palette [
	"Cream and dark green"

	^ Dictionary new
		  at: #lightBackground put: (Color fromHexString: '#f6ead2');
		  at: #lightText put: (Color fromHexString: '#12281b');
		  at: #darkBackground put: (Color fromHexString: '#234a35');
		  at: #darkText put: (Color fromHexString: '#f6ead2');
		  yourself
]

{ #category : 'declaring' }
ChessmateApp >> sessionClass [

	^ ChessCoachSession
]

{ #category : 'declaring' }
ChessmateApp >> windowClass [

	^ ChessCoachAppElement
]
