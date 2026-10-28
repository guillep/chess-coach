Class {
	#name : 'MoveSelectedAnnouncement',
	#superclass : 'Announcement',
	#instVars : [
		'moveIndex',
		'game'
	],
	#category : 'ChessCoach-UI-Bloc',
	#package : 'ChessCoach-UI-Bloc'
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
