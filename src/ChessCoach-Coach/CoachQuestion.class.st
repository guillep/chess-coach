"
A question the coach asks about a moment. kind is one of #candidates and #expectedReply (answered with moves on the board) or #why, #whyNotConsidered, #whyBadCandidate, #whyNotBetter, #whatDidYouSee (answered with text). move is the UCI move the question is about, or nil.
"
Class {
	#name : 'CoachQuestion',
	#superclass : 'Object',
	#instVars : [
		'kind',
		'text',
		'move'
	],
	#category : 'ChessCoach-Coach',
	#package : 'ChessCoach-Coach'
}

{ #category : 'instance creation' }
CoachQuestion class >> fromDictionary: aDictionary [

	^ self
		  kind: (aDictionary at: 'kind') asSymbol
		  text: (aDictionary at: 'text')
		  move: (aDictionary at: 'move')
]

{ #category : 'instance creation' }
CoachQuestion class >> kind: aSymbol text: aString [

	^ self kind: aSymbol text: aString move: nil
]

{ #category : 'instance creation' }
CoachQuestion class >> kind: aSymbol text: aString move: aUCIMoveOrNil [

	^ self new setKind: aSymbol text: aString move: aUCIMoveOrNil
]

{ #category : 'converting' }
CoachQuestion >> asDictionary [

	^ Dictionary new
		  at: 'kind' put: kind asString;
		  at: 'text' put: text;
		  at: 'move' put: move;
		  yourself
]

{ #category : 'testing' }
CoachQuestion >> expectsMoves [
	"Whether I answer by marking moves on the board instead of writing"

	^ #( #candidates #expectedReply ) includes: kind
]

{ #category : 'accessing' }
CoachQuestion >> kind [

	^ kind
]

{ #category : 'accessing' }
CoachQuestion >> move [
	"The UCI move this question is about, or nil"

	^ move
]

{ #category : 'printing' }
CoachQuestion >> printOn: aStream [

	aStream nextPutAll: text
]

{ #category : 'initialization' }
CoachQuestion >> setKind: aSymbol text: aString move: aUCIMoveOrNil [

	kind := aSymbol.
	text := aString.
	move := aUCIMoveOrNil
]

{ #category : 'accessing' }
CoachQuestion >> text [

	^ text
]
