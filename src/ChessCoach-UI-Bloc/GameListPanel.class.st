"
Bloc panel displaying a scrollable list of imported games. Allows selection of a game to review. Displays player names, result, and date.
"
Class {
	#name : 'GameListPanel',
	#superclass : 'Object',
	#instVars : [
		'index',
		'selectedGame',
		'onGameSelected'
	],
	#category : 'ChessCoach-UI-Bloc',
	#package : 'ChessCoach-UI-Bloc'
}

{ #category : 'accessing' }
GameListPanel >> index [

	^ index
]

{ #category : 'initialization' }
GameListPanel >> initializeWithIndex: aGameIndex [

	index := aGameIndex.
	selectedGame := nil.
	onGameSelected := nil
]

{ #category : 'action' }
GameListPanel >> selectGame: aGameIndexEntry [

	selectedGame := aGameIndexEntry.
	onGameSelected ifNotNil: [ onGameSelected value: aGameIndexEntry ]
]

{ #category : 'accessing' }
GameListPanel >> selectedGame [

	^ selectedGame
]
