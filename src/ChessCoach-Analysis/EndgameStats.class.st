"
I gather the endgames of my games. A position is an endgame when it has maxPieces pieces or fewer, kings and pawns not counted. Its configuration is my pieces against my opponent's ('R vs R', 'R vs pawns'), pawns left out. A game counts in every configuration it went through and held for at least 4 plies (2 moves), once per configuration, entered at its first ply.
occurrences maps each configuration to its EndgameOccurrences.
"
Class {
	#name : 'EndgameStats',
	#superclass : 'Object',
	#instVars : [
		'maxPieces',
		'occurrences',
		'skipped'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
EndgameStats class >> maxPieces: aNumber [

	^ self new setMaxPieces: aNumber
]

{ #category : 'signatures' }
EndgameStats class >> pawnsOf: aColor in: aChessPosition [

	^ aChessPosition pieces values count: [ :piece |
			  piece = (aColor = #white
				   ifTrue: [ 'P' ]
				   ifFalse: [ 'p' ]) ]
]

{ #category : 'signatures' }
EndgameStats class >> piecesOf: aColor in: aChessPosition [
	"aColor's pieces without king and pawns, strongest first: 'QR', 'RB', '' "

	| letters |
	letters := (aChessPosition pieces values select: [ :piece |
			            piece first isUppercase = (aColor = #white) and: [
				            'QRBN' includes: piece first asUppercase ] ])
		           collect: [ :piece | piece first asUppercase ].
	^ String withAll: (letters asArray sort: [ :a :b |
			   ('QRBN' indexOf: a) <= ('QRBN' indexOf: b) ])
]

{ #category : 'summaries' }
EndgameStats class >> resultsText: someOccurrences [
	"'7W 3D 2L'"

	^ '{1}W {2}D {3}L' format: {
			  (someOccurrences count: [ :each | each points = 1 ]).
			  (someOccurrences count: [ :each | each points = (1 / 2) ]).
			  (someOccurrences count: [ :each | each points = 0 ]) }
]

{ #category : 'adding' }
EndgameStats >> addGame: aGame id: anId color: aColor points: somePoints analysis: aGameAnalysisOrNil [
	"Every endgame configuration aGame went through, from aColor's side. The positions are played one after the other (not rebuilt from the start each time). The evaluation on entering comes from aGameAnalysisOrNil, when it has engine lines there."

	| opponent runStart runKey runPosition found position |
	opponent := aColor = #white
		            ifTrue: [ #black ]
		            ifFalse: [ #white ].
	found := Set new.
	runKey := nil.
	runStart := 0.
	position := aGame initialPosition.
	0 to: aGame moves size do: [ :ply |
			| mine theirs key |
			ply > 0 ifTrue: [
				position := position move: (aGame moves at: ply) san ].
			mine := self class piecesOf: aColor in: position.
			theirs := self class piecesOf: opponent in: position.
			key := mine size + theirs size <= maxPieces ifTrue: [
				       (mine ifEmpty: [ 'pawns' ]) , ' vs '
				       , (theirs ifEmpty: [ 'pawns' ]) ].
			key = runKey ifFalse: [
					runKey := key.
					runStart := ply.
					runPosition := position ].
			(key notNil and: [
				 ply - runStart = 4 and: [ (found includes: key) not ] ]) ifTrue: [
					found add: key.
					(occurrences at: key ifAbsentPut: [ OrderedCollection new ])
						add: (EndgameOccurrence
								 gameId: anId
								 ply: runStart
								 myPawns: (self class pawnsOf: aColor in: runPosition)
								 theirPawns: (self class pawnsOf: opponent in: runPosition)
								 points: somePoints
								 evaluation:
								 (self
									  evaluationAt: runStart
									  in: aGameAnalysisOrNil
									  for: aColor)) ] ]
]

{ #category : 'accessing' }
EndgameStats >> configurations [
	"Configuration -> its occurrences, the most frequent first"

	| sorted |
	sorted := OrderedDictionary new.
	(occurrences associations asArray sort: [ :a :b |
		 a value size >= b value size ]) do: [ :each |
		sorted at: each key put: each value ].
	^ sorted
]

{ #category : 'private' }
EndgameStats >> evaluationAt: aPly in: aGameAnalysisOrNil for: aColor [
	"Pawns from aColor's side, or nil without engine lines there"

	| plyAnalysis |
	aGameAnalysisOrNil ifNil: [ ^ nil ].
	aPly > aGameAnalysisOrNil moveCount ifTrue: [ ^ nil ].
	plyAnalysis := aGameAnalysisOrNil atPly: aPly.
	plyAnalysis lines ifEmpty: [ ^ nil ].
	^ plyAnalysis bestLine pawnsFor: aColor
]

{ #category : 'accessing' }
EndgameStats >> rows [
	"One EndgameConfiguration per configuration, the most frequent first"

	^ self configurations associations collect: [ :each |
		  EndgameConfiguration name: each key occurrences: each value ]
]

{ #category : 'initialization' }
EndgameStats >> setMaxPieces: aNumber [

	maxPieces := aNumber.
	occurrences := Dictionary new
]

{ #category : 'accessing' }
EndgameStats >> skipped [
	"How many games couldn't be read"

	^ skipped ifNil: [ 0 ]
]

{ #category : 'accessing' }
EndgameStats >> skipped: aNumber [
	"How many games couldn't be read (their errors are in errors.log)"

	skipped := aNumber
]
