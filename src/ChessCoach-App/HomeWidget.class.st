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
HomeWidget class >> atCell: aRectangle [

	^ self type: self typeName cell: aRectangle options: Dictionary new
]

{ #category : 'types' }
HomeWidget class >> classForType: aString [
	"The subclass of that type, or nil"

	^ self subclasses
		  detect: [ :each | each typeName = aString ]
		  ifNone: [ nil ]
]

{ #category : 'instance creation' }
HomeWidget class >> defaultWidgets [
	"Suggestions, numbers and latest games in one column, notifications along the other"

	^ {
		  (HomeSuggestionsWidget atCell: (0 @ 0 extent: 6 @ 3)).
		  (HomeNumbersWidget atCell: (0 @ 3 extent: 6 @ 4)).
		  (HomeNotificationsWidget atCell: (6 @ 0 extent: 6 @ 16)).
		  (HomeLatestGamesWidget atCell: (0 @ 7 extent: 6 @ 9)) }
]

{ #category : 'instance creation' }
HomeWidget class >> fromDictionary: aDictionary [
	"Fields missing from an older file get their defaults"

	^ self
		  type: self typeName
		  cell: ((aDictionary at: 'x' ifAbsent: [ 0 ])
			   @ (aDictionary at: 'y' ifAbsent: [ 1000 ]) extent:
				   (aDictionary at: 'w' ifAbsent: [ 6 ])
				   @ (aDictionary at: 'h' ifAbsent: [ 4 ]))
		  options: (aDictionary at: 'options' ifAbsent: [ Dictionary new ])
]

{ #category : 'types' }
HomeWidget class >> minimumExtent [
	"In cells"

	^ 3 @ 3
]

{ #category : 'instance creation' }
HomeWidget class >> type: aString cell: aRectangle options: aDictionary [

	^ self new
		  setType: aString cell: aRectangle options: aDictionary;
		  yourself
]

{ #category : 'types' }
HomeWidget class >> typeName [

	^ nil
]

{ #category : 'converting' }
HomeWidget >> asDictionary [

	^ Dictionary new
		  at: 'type' put: type;
		  at: 'x' put: cell left;
		  at: 'y' put: cell top;
		  at: 'w' put: cell width;
		  at: 'h' put: cell height;
		  at: 'options' put: options;
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
HomeWidget >> count [

	^ options at: 'count' ifAbsent: [ self defaultCount ]
]

{ #category : 'accessing' }
HomeWidget >> defaultCount [

	^ 5
]

{ #category : 'accessing' }
HomeWidget >> filter [

	^ GameFilter fromDictionary:
		  (options at: 'filter' ifAbsent: [ Dictionary new ])
]

{ #category : 'accessing' }
HomeWidget >> filterAt: aKey put: aValueOrNil [

	| filter |
	filter := self filter.
	filter at: aKey put: aValueOrNil.
	options at: 'filter' put: filter criteria
]

{ #category : 'accessing' }
HomeWidget >> option: aKey ifAbsent: aBlock [

	^ options at: aKey ifAbsent: aBlock
]

{ #category : 'accessing' }
HomeWidget >> option: aKey put: aValueOrNil [

	aValueOrNil
		ifNil: [ options removeKey: aKey ifAbsent: [ ] ]
		ifNotNil: [ options at: aKey put: aValueOrNil ]
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
HomeWidget >> title [

	^ options at: 'title' ifAbsent: [ self defaultTitle ]
]

{ #category : 'accessing' }
HomeWidget >> type [

	^ type
]
