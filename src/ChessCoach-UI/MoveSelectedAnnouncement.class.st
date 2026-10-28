Class {
	#name : 'MoveSelectedAnnouncement',
	#superclass : 'Announcement',
	#instVars : [
		'moveIndex',
		'game'
	],
	#category : 'ChessCoach-UI-Board',
	#package : 'ChessCoach-UI',
	#tag : 'Board'
}

{ #category : 'accessing' }
MoveSelectedAnnouncement >> game [

	^ game
]

{ #category : 'accessing' }
MoveSelectedAnnouncement >> game: aGame [

	game := aGame
]

{ #category : 'accessing' }
MoveSelectedAnnouncement >> moveIndex [

	^ moveIndex
]

{ #category : 'accessing' }
MoveSelectedAnnouncement >> moveIndex: anInt [

	moveIndex := anInt
]
