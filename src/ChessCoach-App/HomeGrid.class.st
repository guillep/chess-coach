"
The cells of the Home dashboard: 12 columns. Widgets never overlap and compact upwards; a placed widget pushes the others down.
"
Class {
	#name : 'HomeGrid',
	#superclass : 'Object',
	#instVars : [
		'widgets'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'instance creation' }
HomeGrid class >> withWidgets: someWidgets [

	^ self new
		  setWidgets: someWidgets;
		  yourself
]

{ #category : 'layout' }
HomeGrid >> compact [
	"Move every widget as high as it fits, in reading order"

	self compactKeeping: nil
]

{ #category : 'private' }
HomeGrid >> compactKeeping: aWidgetOrNil [
	"Lift each widget in reading order as high as it fits above the settled ones. aWidgetOrNil goes first among those on its row, so it wins ties, but never jumps over a widget above it."

	| settled ordered |
	settled := OrderedCollection new.
	ordered := self inReadingOrderWithout: aWidgetOrNil.
	aWidgetOrNil ifNotNil: [ :widget |
			| index |
			index := ordered findFirst: [ :each |
				         each cell top >= widget cell top ].
			ordered := index = 0
				           ifTrue: [ ordered , { widget } ]
				           ifFalse: [
						           (ordered first: index - 1) , { widget }
						           , (ordered allButFirst: index - 1) ] ].
	ordered do: [ :each |
			self lift: each among: settled.
			settled add: each ]
]

{ #category : 'private' }
HomeGrid >> inReadingOrderWithout: aWidget [

	^ (widgets copyWithout: aWidget) sorted: [ :a :b |
			  a cell top = b cell top
				  ifTrue: [ a cell left <= b cell left ]
				  ifFalse: [ a cell top < b cell top ] ]
]

{ #category : 'private' }
HomeGrid >> lift: aWidget among: someWidgets [
	"The highest free row: below its own row too, so an overlap read from a file gets repaired"

	| row candidate |
	row := 0.
	[
		candidate := aWidget cell left @ row extent: aWidget cell extent.
		someWidgets anySatisfy: [ :each | each cell intersects: candidate ] ]
		whileTrue: [ row := row + 1 ].
	aWidget cell: candidate
]

{ #category : 'layout' }
HomeGrid >> place: aWidget at: aRectangle [
	"Put aWidget at aRectangle, kept inside the 12 columns. The others go down when they are in the way, then everything compacts."

	| column width others |
	width := aRectangle width min: 12.
	column := (aRectangle left max: 0) min: 12 - width.
	aWidget cell:
		(column @ (aRectangle top max: 0) extent: width @ aRectangle height).
	others := self inReadingOrderWithout: aWidget.
	others do: [ :each |
		self push: each belowAll: (others copyUpTo: each) , { aWidget } ].
	self compactKeeping: aWidget
]

{ #category : 'private' }
HomeGrid >> push: aWidget belowAll: someWidgets [
	"Move aWidget down until it overlaps none of someWidgets"

	[
		someWidgets
			detect: [ :each | each cell intersects: aWidget cell ]
			ifFound: [ :each |
					aWidget cell:
						(aWidget cell left @ each cell bottom extent:
							 aWidget cell extent).
					true ]
			ifNone: [ false ] ] whileTrue
]

{ #category : 'initialization' }
HomeGrid >> setWidgets: someWidgets [

	widgets := someWidgets asOrderedCollection.
	self compact
]

{ #category : 'accessing' }
HomeGrid >> widgets [

	^ widgets
]
