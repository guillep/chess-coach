"
A small app on the Mamotreto shell, with no chess: a Greetings page that runs the session's one service on demand, and a Look page that switches between the light and dark themes. It proves the shell works on its own: MMExampleApp new open.
"
Class {
	#name : 'MMExampleApp',
	#superclass : 'MMApp',
	#category : 'Mamotreto-Example',
	#package : 'Mamotreto-Example'
}

{ #category : 'declaring' }
MMExampleApp >> name [

	^ 'Mamotreto Example'
]

{ #category : 'pages' }
MMExampleApp >> newGreetingsPageIn: aWindow [
	"A section explaining the service, with a button that runs it now"

	^ MMWidgets
		  page: 'Greetings'
		  subtitle: 'The example service, run by the scheduler every hour.'
		  body: (MMWidgets
				   section: 'Greeting'
				   help: 'It posts a notification under the bell.'
				   rows: {
						   (MMWidgets paragraph:
							    'Press the button to greet now instead of waiting.').
						   (MMWidgets
							    primaryButton: 'Greet'
							    icon: 'outlined_notifications'
							    do: [ aWindow session greet ]) })
]

{ #category : 'pages' }
MMExampleApp >> newLookPageIn: aWindow [
	"The app theme, as a choice bar saved in the settings"

	^ MMWidgets
		  page: 'Look'
		  subtitle: 'The theme of the whole window.'
		  body: (MMWidgets section: 'Theme' help: nil rows: { (MMWidgets
					    choiceBar: {
							    ('Light' -> 'Light').
							    ('Dark' -> 'Dark') }
					    selected: 'Light'
					    do: [ :theme |
					    aWindow session settings at: 'appTheme' put: theme ]) })
]

{ #category : 'declaring' }
MMExampleApp >> pages [

	^ {
		  (MMPage
			   named: 'Greetings'
			   icon: 'outlined_notifications'
			   build: [ :window | self newGreetingsPageIn: window ]).
		  (MMPage
			   named: 'Look'
			   icon: 'outlined_settings'
			   build: [ :window | self newLookPageIn: window ]) }
]

{ #category : 'declaring' }
MMExampleApp >> sessionClass [

	^ MMExampleSession
]
