"
One widget of the Home: its type, its cell in the grid (a Rectangle in cells) and its options. It is plain data, saved in home.json.
"
Class {
	#name : 'HomeWidget',
	#superclass : 'Object',
	#instVars : [
		'type',
		'cell',
		'options'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'instance creation' }
HomeWidget class >> type: aString cell: aRectangle options: aDictionary [

	^ self new
		  setType: aString cell: aRectangle options: aDictionary;
		  yourself
]

{ #category : 'accessing' }
HomeWidget >> cell [

	^ cell
]

{ #category : 'accessing' }
HomeWidget >> cell: aRectangle [

	cell := aRectangle
]

{ #category : 'accessing' }
HomeWidget >> options [

	^ options
]

{ #category : 'initialization' }
HomeWidget >> setType: aString cell: aRectangle options: aDictionary [

	type := aString.
	cell := aRectangle.
	options := aDictionary
]

{ #category : 'accessing' }
HomeWidget >> type [

	^ type
]
