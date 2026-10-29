"
My preferences, kept in settings.json next to the games: piece set, games per Load more, Stockfish path, depth and MultiPV, Ollama URL and model, coach moments per round. Each change is saved at once and reported to changedBlock (the session applies it).
"
Class {
	#name : 'ChessCoachSettings',
	#superclass : 'Object',
	#instVars : [
		'file',
		'values',
		'changedBlock'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'defaults' }
ChessCoachSettings class >> defaults [

	^ Dictionary new
		  at: 'pieceSet' put: 'Meridian';
		  at: 'gamesPerLoad' put: 20;
		  at: 'stockfishPath' put: '/opt/homebrew/bin/stockfish';
		  at: 'depth' put: 18;
		  at: 'multiPV' put: 3;
		  at: 'ollamaUrl' put: 'http://localhost:11434';
		  at: 'ollamaModel' put: 'qwen2.5:7b-instruct';
		  at: 'momentFilter' put: 'mistakes';
		  at: 'setupDone' put: false;
		  yourself
]

{ #category : 'instance creation' }
ChessCoachSettings class >> onFile: aFileReference [
	"Settings stored in aFileReference; missing values take their defaults"

	^ self new setFile: aFileReference
]

{ #category : 'accessing' }
ChessCoachSettings >> at: aKey [

	^ values at: aKey
]

{ #category : 'accessing' }
ChessCoachSettings >> at: aKey put: aValue [
	"Change one setting, save the file and report it"

	self assert: (self class defaults includesKey: aKey).
	(values at: aKey) = aValue ifTrue: [ ^ aValue ].
	values at: aKey put: aValue.
	file parent ensureCreateDirectory.
	file
		ensureDelete;
		writeStreamDo: [ :stream |
			stream nextPutAll: (STONJSON toStringPretty: values) ].
	changedBlock value: aKey.
	^ aValue
]

{ #category : 'accessing' }
ChessCoachSettings >> depth [

	^ self at: 'depth'
]

{ #category : 'accessing' }
ChessCoachSettings >> gamesPerLoad [

	^ self at: 'gamesPerLoad'
]

{ #category : 'accessing' }
ChessCoachSettings >> momentFilter [
	"Which moments a review lists and walks through: #all, #mistakes or #blunders"

	^ (self at: 'momentFilter') asSymbol
]

{ #category : 'accessing' }
ChessCoachSettings >> multiPV [

	^ self at: 'multiPV'
]

{ #category : 'accessing' }
ChessCoachSettings >> ollamaModel [

	^ self at: 'ollamaModel'
]

{ #category : 'accessing' }
ChessCoachSettings >> ollamaUrl [

	^ self at: 'ollamaUrl'
]

{ #category : 'accessing' }
ChessCoachSettings >> pieceSet [
	"The name of the board's piece set (Meridian, Meridian shaded, Livius, Madware)"

	^ self at: 'pieceSet'
]

{ #category : 'initialization' }
ChessCoachSettings >> setFile: aFileReference [

	file := aFileReference.
	values := self class defaults.
	changedBlock := [ :key |  ].
	file exists ifTrue: [
		values addAll: (STONJSON fromString: file contents) ]
]

{ #category : 'accessing' }
ChessCoachSettings >> stockfishPath [

	^ (self at: 'stockfishPath') asFileReference
]

{ #category : 'accessing' }
ChessCoachSettings >> whenChangedDo: aBlock [
	"aBlock receives the key of each changed setting"

	changedBlock := aBlock
]
