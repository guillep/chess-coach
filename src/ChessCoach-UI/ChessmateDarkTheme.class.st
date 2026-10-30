"
I am the dark theme: the light theme's colours inverted, dark green with cream.
"
Class {
	#name : 'ChessmateDarkTheme',
	#superclass : 'ToRawDarkTheme',
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'accessing' }
ChessmateDarkTheme class >> defaultColorPrimary [

	^ Color fromHexString: '#e8cfa3'
]

{ #category : 'accessing' }
ChessmateDarkTheme class >> defaultTokenProperties [

	^ super defaultTokenProperties , {
		  (ToTokenProperty
			   name: #'background-color'
			   value: (Color fromHexString: '#12281b')).
		  (ToTokenProperty
			   name: #'color-bg-container'
			   value: (Color fromHexString: '#1c3a28')).
		  (ToTokenProperty
			   name: #'color-primary-unchecked'
			   value: (Color fromHexString: '#1c3a28')).
		  (ToTokenProperty
			   name: #'color-border'
			   value: (Color fromHexString: '#4d6b55')).
		  (ToTokenProperty
			   name: #'color-text'
			   value: (Color fromHexString: '#f6ead2')).
		  (ToTokenProperty
			   name: #'text-color-primary-checked'
			   value: (Color fromHexString: '#12281b')).
		  (ToTokenProperty
			   name: #'color-link'
			   value: (Color fromHexString: '#e8cfa3')) }
]
