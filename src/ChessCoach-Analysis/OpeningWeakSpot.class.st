"
I am an entry of a weak-spot list: a move of a position with its games and my score. kind is #scoreGap, #lowScore or #prepGap; gap is only known for #scoreGap.
"
Class {
	#name : 'OpeningWeakSpot',
	#superclass : 'Object',
	#instVars : [
		'kind',
		'key',
		'san',
		'games',
		'score',
		'gap'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
OpeningWeakSpot class >> kind: aKind node: anOpeningNode move: anOpeningMove gap: aNumberOrNil [

	^ self new
		  setKind: aKind
		  key: anOpeningNode key
		  san: anOpeningMove san
		  games: anOpeningMove games
		  score: anOpeningMove score
		  gap: aNumberOrNil
]

{ #category : 'accessing' }
OpeningWeakSpot >> games [

	^ games
]

{ #category : 'accessing' }
OpeningWeakSpot >> gap [

	^ gap
]

{ #category : 'accessing' }
OpeningWeakSpot >> key [

	^ key
]

{ #category : 'accessing' }
OpeningWeakSpot >> kind [

	^ kind
]

{ #category : 'accessing' }
OpeningWeakSpot >> pointsLost [
	"What ranks the score-gap list"

	^ games * gap
]

{ #category : 'printing' }
OpeningWeakSpot >> positionLabelFrom: aNode [
	"'Move 7: Bd3', with dots for Black's moves"

	^ 'Move {1}{2} {3}' format: {
			  aNode fen substrings last.
			  (aNode turn = #white
				   ifTrue: [ '.' ]
				   ifFalse: [ '...' ]).
			  san }
]

{ #category : 'accessing' }
OpeningWeakSpot >> san [

	^ san
]

{ #category : 'accessing' }
OpeningWeakSpot >> score [

	^ score
]

{ #category : 'initialization' }
OpeningWeakSpot >> setKind: aKind key: aKey san: aSAN games: aCount score: aScore gap: aGap [

	kind := aKind.
	key := aKey.
	san := aSAN.
	games := aCount.
	score := aScore.
	gap := aGap
]
