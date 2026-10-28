"
The analysis state or progress of a game changed.
"
Class {
	#name : 'AnalysisQueueChanged',
	#superclass : 'Announcement',
	#instVars : [
		'gameId'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'accessing' }
AnalysisQueueChanged >> gameId [

	^ gameId
]

{ #category : 'accessing' }
AnalysisQueueChanged >> gameId: aString [

	gameId := aString
]
