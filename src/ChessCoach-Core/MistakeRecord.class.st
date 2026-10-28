"
One reviewed moment in the mistake database: game, ply, date, phase, moment kinds, my move and the best move (UCI), win-% drop, my explanation and the taxonomy labels. Round-trips through JSON dictionaries.
"
Class {
	#name : 'MistakeRecord',
	#superclass : 'Object',
	#instVars : [
		'gameId',
		'ply',
		'date',
		'phase',
		'kinds',
		'playedMove',
		'bestMove',
		'winDrop',
		'explanation',
		'labels'
	],
	#category : 'ChessCoach-Core-Mistakes',
	#package : 'ChessCoach-Core',
	#tag : 'Mistakes'
}

{ #category : 'instance creation' }
MistakeRecord class >> fromDictionary: aDictionary [

	^ self new
		  gameId: (aDictionary at: 'game');
		  ply: (aDictionary at: 'ply');
		  date: (aDictionary at: 'date') asDate;
		  phase: (aDictionary at: 'phase');
		  kinds: (aDictionary at: 'kinds') asArray;
		  playedMove: (aDictionary at: 'played');
		  bestMove: (aDictionary at: 'best');
		  winDrop: (aDictionary at: 'winDrop');
		  explanation: (aDictionary at: 'explanation');
		  labels: ((aDictionary at: 'labels') collect: [ :each |
					   MistakeLabel fromDictionary: each ]) asArray;
		  yourself
]

{ #category : 'converting' }
MistakeRecord >> asDictionary [

	^ Dictionary new
		  at: 'game' put: gameId;
		  at: 'ply' put: ply;
		  at: 'date' put: date yyyymmdd;
		  at: 'phase' put: phase;
		  at: 'kinds'
		  put: (kinds collect: [ :each | each asString ]) asArray;
		  at: 'played' put: playedMove;
		  at: 'best' put: bestMove;
		  at: 'winDrop' put: winDrop;
		  at: 'explanation' put: explanation;
		  at: 'labels'
		  put: (labels collect: [ :each | each asDictionary ]) asArray;
		  yourself
]

{ #category : 'accessing' }
MistakeRecord >> bestMove [

	^ bestMove
]

{ #category : 'accessing' }
MistakeRecord >> bestMove: aUCIString [

	bestMove := aUCIString
]

{ #category : 'accessing' }
MistakeRecord >> date [

	^ date
]

{ #category : 'accessing' }
MistakeRecord >> date: aDate [

	date := aDate
]

{ #category : 'accessing' }
MistakeRecord >> explanation [

	^ explanation
]

{ #category : 'accessing' }
MistakeRecord >> explanation: aString [

	explanation := aString
]

{ #category : 'accessing' }
MistakeRecord >> gameId [

	^ gameId
]

{ #category : 'accessing' }
MistakeRecord >> gameId: aString [

	gameId := aString
]

{ #category : 'testing' }
MistakeRecord >> hasTag: aTagId [

	^ labels anySatisfy: [ :each | each tagId = aTagId ]
]

{ #category : 'initialization' }
MistakeRecord >> initialize [

	super initialize.
	kinds := #(  ).
	labels := #(  )
]

{ #category : 'accessing' }
MistakeRecord >> kinds [

	^ kinds
]

{ #category : 'accessing' }
MistakeRecord >> kinds: aCollection [

	kinds := aCollection
]

{ #category : 'accessing' }
MistakeRecord >> labels [

	^ labels
]

{ #category : 'accessing' }
MistakeRecord >> labels: aCollection [

	labels := aCollection
]

{ #category : 'accessing' }
MistakeRecord >> phase [

	^ phase
]

{ #category : 'accessing' }
MistakeRecord >> phase: aString [

	phase := aString
]

{ #category : 'accessing' }
MistakeRecord >> playedMove [

	^ playedMove
]

{ #category : 'accessing' }
MistakeRecord >> playedMove: aUCIString [

	playedMove := aUCIString
]

{ #category : 'accessing' }
MistakeRecord >> ply [

	^ ply
]

{ #category : 'accessing' }
MistakeRecord >> ply: anInteger [

	ply := anInteger
]

{ #category : 'accessing' }
MistakeRecord >> tagIds [

	^ labels collect: [ :each | each tagId ]
]

{ #category : 'accessing' }
MistakeRecord >> winDrop [

	^ winDrop
]

{ #category : 'accessing' }
MistakeRecord >> winDrop: aNumber [

	winDrop := aNumber
]
