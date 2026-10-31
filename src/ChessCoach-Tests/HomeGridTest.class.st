Class {
	#name : 'HomeGridTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
HomeGridTest >> testASavedOverlapIsRepaired [

	| widgets |
	widgets := {
		           (self widgetAt: (0 @ 0 extent: 6 @ 4)).
		           (self widgetAt: (0 @ 4 extent: 6 @ 4)).
		           (self widgetAt: (6 @ 0 extent: 6 @ 8)).
		           (self widgetAt: (0 @ 0 extent: 6 @ 7)) }.
	HomeGrid withWidgets: widgets.
	widgets do: [ :a |
			widgets do: [ :b |
				a == b ifFalse: [ self deny: (a cell intersects: b cell) ] ] ]
]

{ #category : 'tests' }
HomeGridTest >> testAdjacentWidgetsStayTogether [

	| first second |
	first := self widgetAt: (0 @ 0 extent: 6 @ 2).
	second := self widgetAt: (6 @ 0 extent: 6 @ 2).
	HomeGrid withWidgets: {
			first.
			second }.
	self assert: second cell origin equals: 6 @ 0
]

{ #category : 'tests' }
HomeGridTest >> testPlacedWidgetPushesTheOthersDown [

	| first second grid |
	first := self widgetAt: (0 @ 0 extent: 12 @ 2).
	second := self widgetAt: (0 @ 2 extent: 12 @ 3).
	grid := HomeGrid withWidgets: {
			        first.
			        second }.
	grid place: second at: (0 @ 0 extent: 12 @ 3).
	self assert: second cell origin equals: 0 @ 0.
	self assert: first cell origin equals: 0 @ 3
]

{ #category : 'tests' }
HomeGridTest >> testPlacedWidgetStaysInsideTheColumns [

	| widget grid |
	widget := self widgetAt: (0 @ 0 extent: 6 @ 2).
	grid := HomeGrid withWidgets: { widget }.
	grid place: widget at: (10 @ 0 extent: 6 @ 2).
	self assert: widget cell left equals: 6
]

{ #category : 'tests' }
HomeGridTest >> testResizingBelowAnotherKeepsThemApart [

	| top bottom grid |
	top := self widgetAt: (0 @ 0 extent: 6 @ 4).
	bottom := self widgetAt: (0 @ 4 extent: 6 @ 4).
	grid := HomeGrid withWidgets: {
			        top.
			        bottom }.
	grid place: bottom at: (0 @ 4 extent: 6 @ 7).
	self assert: top cell origin equals: 0 @ 0.
	self assert: bottom cell origin equals: 0 @ 4
]

{ #category : 'tests' }
HomeGridTest >> testThresholdsComeFromTheFinder [

	| finder |
	finder := EvaluationJumpFinder new.
	self assert: (finder kindForDrop: 15) equals: #inaccuracy.
	finder thresholds: (Dictionary new
			 at: 'momentInaccuracyDrop' put: 16;
			 yourself).
	self assert: (finder kindForDrop: 15) isNil.
	self assert: (finder kindForDrop: 30) equals: #blunder
]

{ #category : 'tests' }
HomeGridTest >> testWidgetsCompactUpwards [

	| widget |
	widget := self widgetAt: (0 @ 5 extent: 6 @ 2).
	HomeGrid withWidgets: { widget }.
	self assert: widget cell origin equals: 0 @ 0
]

{ #category : 'tests' }
HomeGridTest >> widgetAt: aRectangle [

	^ HomeWidget type: 'numbers' cell: aRectangle options: Dictionary new
]
