"
An arrow drawn on a ChessBoardElement for a UCI move. style is #candidate (green), #played (blue), #engine (orange) or #subject (orange, dashed: the move a question is about).
"
Class {
	#name : 'ChessArrow',
	#superclass : 'Object',
	#instVars : [
		'uci',
		'style'
	],
	#category : 'ChessCoach-UI-Board',
	#package : 'ChessCoach-UI',
	#tag : 'Board'
}

{ #category : 'instance creation' }
ChessArrow class >> uci: aUCIMove style: aSymbol [

	^ self new setUCI: aUCIMove style: aSymbol
]

{ #category : 'drawing' }
ChessArrow >> color [

	style = #candidate ifTrue: [
			^ Color
				  r: 0.15
				  g: 0.6
				  b: 0.25
				  alpha: 0.75 ].
	style = #played ifTrue: [
			^ Color
				  r: 0.15
				  g: 0.4
				  b: 0.85
				  alpha: 0.75 ].
	^ Color
		  r: 0.95
		  g: 0.55
		  b: 0.1
		  alpha: (style = #subject
				   ifTrue: [ 0.35 ]
				   ifFalse: [ 0.75 ])
]

{ #category : 'accessing' }
ChessArrow >> from [

	^ uci first: 2
]

{ #category : 'printing' }
ChessArrow >> printOn: aStream [

	aStream
		nextPutAll: uci;
		space;
		print: style
]

{ #category : 'initialization' }
ChessArrow >> setUCI: aUCIMove style: aSymbol [

	uci := aUCIMove.
	style := aSymbol
]

{ #category : 'accessing' }
ChessArrow >> style [

	^ style
]

{ #category : 'accessing' }
ChessArrow >> to [

	^ uci copyFrom: 3 to: 4
]

{ #category : 'accessing' }
ChessArrow >> uci [

	^ uci
]

{ #category : 'drawing' }
ChessArrow >> verticesFrom: aStart to: aTip squareSize: aSize [
	"A shaft with a triangular head, from the centre of the origin square to the centre of the target square"

	| direction normal shaft head headLength base |
	direction := aTip - aStart / ((aTip - aStart) r max: 1).
	normal := direction y negated @ direction x.
	shaft := aSize * 0.09.
	head := aSize * 0.24.
	headLength := aSize * 0.42.
	base := aTip - (direction * headLength).
	^ {
		  (aStart + (normal * shaft)).
		  (base + (normal * shaft)).
		  (base + (normal * head)).
		  aTip.
		  (base - (normal * head)).
		  (base - (normal * shaft)).
		  (aStart - (normal * shaft)) }
]
