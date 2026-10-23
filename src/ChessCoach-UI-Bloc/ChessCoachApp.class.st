"
Main application window. Coordinates navigation between game list and review modes. Manages the overall Bloc UI layout and user interactions.
"
Class {
	#name : 'ChessCoachApp',
	#superclass : 'Object',
	#instVars : [
		'window',
		'indexManager',
		'gameListPanel',
		'boardReviewPanel'
	],
	#category : 'ChessCoach-UI-Bloc',
	#package : 'ChessCoach-UI-Bloc'
}

{ #category : 'private' }
ChessCoachApp >> buildUI [
	"Construct the main UI layout (scaffolded; Bloc integration pending)"

	gameListPanel := GameListPanel new initializeWithIndex:
		                 indexManager index.
	boardReviewPanel := Object new. "Placeholder; will add board viewer"
	window := Object new
	"TODO: Add Bloc layout and components once Bloc is loaded"
]

{ #category : 'initialization' }
ChessCoachApp >> initialize [

	super initialize.
	indexManager := nil.
	gameListPanel := nil.
	boardReviewPanel := nil
]

{ #category : 'opening' }
ChessCoachApp >> openWithIndexManager: anIndexManager [
	"Initialize and display the main app window"

	indexManager := anIndexManager.
	self buildUI.
	^ self
]
