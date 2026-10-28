"
I am an interesting moment of a game: the ply-th half-move, played by color.
kinds say what is interesting (#inaccuracy #mistake #blunder #onlyMoveFound #onlyMoveMissed #openingChoice #marked), sources who found it (#engine #explorer #marks), notes explain it.
Moments on the same ply merge into one.
"
Class {
	#name : 'ChessMoment',
	#superclass : 'Object',
	#instVars : [
		'ply',
		'color',
		'kinds',
		'sources',
		'notes'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
ChessMoment class >> ply: aPly color: aColor kind: aKind source: aSource note: aString [

	^ self new
		  setPly: aPly
		  color: aColor
		  kind: aKind
		  source: aSource
		  note: aString
]

{ #category : 'merging' }
ChessMoment >> absorb: aChessMoment [
	"Add another moment on the same ply to me"

	kinds addAll: aChessMoment kinds.
	sources addAll: aChessMoment sources.
	notes addAll: aChessMoment notes
]

{ #category : 'accessing' }
ChessMoment >> color [
	"The side that played the move"

	^ color
]

{ #category : 'testing' }
ChessMoment >> isMarked [
	"Whether the user marked this moment"

	^ sources includes: #marks
]

{ #category : 'accessing' }
ChessMoment >> kinds [

	^ kinds
]

{ #category : 'accessing' }
ChessMoment >> notes [

	^ notes
]

{ #category : 'accessing' }
ChessMoment >> ply [
	"The half-move this moment is about, 1 being White's first move"

	^ ply
]

{ #category : 'printing' }
ChessMoment >> printOn: aStream [

	aStream
		nextPutAll: 'ply ';
		print: ply;
		space;
		print: kinds asSortedCollection asArray
]

{ #category : 'initialization' }
ChessMoment >> setPly: aPly color: aColor kind: aKind source: aSource note: aString [

	ply := aPly.
	color := aColor.
	kinds := Set with: aKind.
	sources := Set with: aSource.
	notes := OrderedCollection new.
	aString isEmptyOrNil ifFalse: [ notes add: aString ]
]

{ #category : 'accessing' }
ChessMoment >> sources [

	^ sources
]
