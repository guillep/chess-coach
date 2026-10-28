"
I am announced by a ChessCoachSession when its login state or game list changes.
"
Class {
	#name : 'ChessCoachSessionChanged',
	#superclass : 'Announcement',
	#instVars : [
		'session'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'accessing' }
ChessCoachSessionChanged >> session [

	^ session
]

{ #category : 'accessing' }
ChessCoachSessionChanged >> session: aChessCoachSession [

	session := aChessCoachSession
]
