"
I declare an app on the Mamotreto shell. A subclass answers its name, its pages, its palette, the classes of its session and window, and the widgets of its Home; the repository and baseline come from the session class. The shell builds the rest: #open opens the window maximized on a session in the app's data directory.
"
Class {
	#name : 'MMApp',
	#superclass : 'Object',
	#category : 'Mamotreto-UI-App',
	#package : 'Mamotreto-UI',
	#tag : 'App'
}

{ #category : 'declaring' }
MMApp >> baselineName [

	^ self sessionClass baselineName
]

{ #category : 'declaring' }
MMApp >> dataDirectory [
	"Where the session keeps the app's files: ~/.<name>"

	^ FileLocator home / ('.' , self name asLowercase)
]

{ #category : 'declaring' }
MMApp >> homeWidgetClasses [
	"The widgets the Home may show; none means no Home"

	^ #(  )
]

{ #category : 'declaring' }
MMApp >> name [
	"The name in the title bar, the window title and the data directory"

	^ self subclassResponsibility
]

{ #category : 'opening' }
MMApp >> newSession [
	"A session on the app's data directory"

	^ self sessionClass onDirectory: self dataDirectory
]

{ #category : 'opening' }
MMApp >> open [
	"Open the window maximized on a new session"

	^ self windowClass openApp: self on: self newSession
]

{ #category : 'declaring' }
MMApp >> pages [
	"The MMPages of the rail, in order"

	^ self subclassResponsibility
]

{ #category : 'declaring' }
MMApp >> palette [
	"The colours of the light and dark themes: the window background and the text and icon tint"

	^ Dictionary new
		  at: #lightBackground put: Color white;
		  at: #lightText put: Color black;
		  at: #darkBackground put: (Color fromHexString: '#202124');
		  at: #darkText put: (Color fromHexString: '#e8eaed');
		  yourself
]

{ #category : 'declaring' }
MMApp >> repositoryName [

	^ self sessionClass repositoryName
]

{ #category : 'declaring' }
MMApp >> sessionClass [
	"An MMSession subclass, which names the repository and baseline"

	^ self subclassResponsibility
]

{ #category : 'declaring' }
MMApp >> windowClass [
	"Apps with more than pages (their own status labels or reactions) answer an MMWindow subclass"

	^ MMWindow
]
