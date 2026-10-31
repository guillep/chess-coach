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
			   value: (Color fromHexString: '#234a35')).
		  (ToTokenProperty
			   name: #'color-bg-container'
			   value: (Color fromHexString: '#46593a')).
		  (ToTokenProperty
			   name: #'color-primary-unchecked'
			   value: (Color fromHexString: '#46593a')).
		  (ToTokenProperty
			   name: #'color-border'
			   value: (Color fromHexString: '#7d8a5e')).
		  (ToTokenProperty
			   name: #'color-text'
			   value: (Color fromHexString: '#f6ead2')).
		  (ToTokenProperty
			   name: #'text-color-primary-checked'
			   value: (Color fromHexString: '#234a35')).
		  (ToTokenProperty
			   name: #'color-link'
			   value: (Color fromHexString: '#e8cfa3')) }
]
