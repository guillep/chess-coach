"
I am the light theme: the colours of the Chessmate icon, cream with dark green.
"
Class {
	#name : 'ChessmateTheme',
	#superclass : 'ToRawTheme',
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'accessing' }
ChessmateTheme class >> defaultColorPrimary [

	^ Color fromHexString: '#2f6b45'
]

{ #category : 'accessing' }
ChessmateTheme class >> defaultTokenProperties [

	^ super defaultTokenProperties , {
		  (ToTokenProperty
			   name: #'background-color'
			   value: (Color fromHexString: '#f6ead2')).
		  (ToTokenProperty
			   name: #'color-bg-container'
			   value: (Color fromHexString: '#fbf4e4')).
		  (ToTokenProperty
			   name: #'color-primary-unchecked'
			   value: (Color fromHexString: '#fbf4e4')).
		  (ToTokenProperty
			   name: #'color-border'
			   value: (Color fromHexString: '#d9bf92')).
		  (ToTokenProperty
			   name: #'color-text'
			   value: (Color fromHexString: '#12281b')).
		  (ToTokenProperty
			   name: #'color-link'
			   value: (Color fromHexString: '#b5652b')) }
]
