"
Controls move replay and navigation. Provides next/previous buttons and move jump slider. Synchronizes the board display with the current move.
"
Class {
	#name : 'MoveReplayController',
	#superclass : 'Object',
	#instVars : [
		'game',
		'currentMoveIndex',
		'board'
	],
	#category : 'ChessCoach-UI-Bloc',
	#package : 'ChessCoach-UI-Bloc'
}

{ #category : 'accessing' }
MoveReplayController >> board [

	^ board
]

{ #category : 'accessing' }
MoveReplayController >> board: aChessBoard [

	board := aChessBoard.
	^ self
]

{ #category : 'accessing' }
MoveReplayController >> currentMoveIndex [

	^ currentMoveIndex
]

{ #category : 'accessing' }
MoveReplayController >> game [

	^ game
]

{ #category : 'accessing' }
MoveReplayController >> game: aChessGame [

	game := aChessGame.
	currentMoveIndex := 0.
	^ self
]

{ #category : 'accessing' }
MoveReplayController >> gameMoves [

	| m |
	game ifNil: [ ^ #(  ) ].
	m := game moves.
	m ifNil: [ ^ #(  ) ].
	(m isKindOf: OrderedCollection) ifTrue: [ ^ m asArray ].
	(m isKindOf: Array) ifTrue: [ ^ m ].
	^ #(  )
]

{ #category : 'initialization' }
MoveReplayController >> initialize [

	game := nil.
	currentMoveIndex := 0.
	board := nil.
	^ self
]

{ #category : 'initialization' }
MoveReplayController >> initializeWithGame: aChessGame [

	game := aChessGame.
	currentMoveIndex := 0.
	board := nil
]

{ #category : 'navigation' }
MoveReplayController >> jumpToMove: moveIndex [

	(moveIndex >= 0 and: [ moveIndex <= game moves size ]) ifTrue: [
		currentMoveIndex := moveIndex ]
]

{ #category : 'accessing' }
MoveReplayController >> moveAtIndex: anIndex [

	| moves |
	moves := self gameMoves.
	(anIndex < 1 or: [ anIndex > moves size ]) ifTrue: [ ^ nil ].
	^ moves at: anIndex
]

{ #category : 'accessing' }
MoveReplayController >> moveList [

	| moves stream previous |
	moves := self gameMoves.
	stream := WriteStream on: String new.
	previous := nil.
	moves withIndexDo: [ :move :idx |
			| needsSpace |
			needsSpace := idx > 1.
			needsSpace ifTrue: [ stream space ].
			move color = 'w'
				ifTrue: [ stream nextPutAll: move moveNumber asString , '. ' ]
				ifFalse: [
						(previous notNil and: [
							 previous color = 'w' and: [
								 previous moveNumber = move moveNumber ] ]) not ifTrue: [
							stream nextPutAll: move moveNumber asString , '... ' ] ].
			stream nextPutAll: move san.
			previous := move ].
	^ stream contents
]

{ #category : 'navigation' }
MoveReplayController >> nextMove [

	currentMoveIndex < game moves size ifTrue: [
		currentMoveIndex := currentMoveIndex + 1 ]
]

{ #category : 'navigation' }
MoveReplayController >> previousMove [

	currentMoveIndex > 0 ifTrue: [
		currentMoveIndex := currentMoveIndex - 1 ]
]
