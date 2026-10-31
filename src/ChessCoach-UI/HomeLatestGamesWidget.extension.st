Extension { #name : 'HomeLatestGamesWidget' }

{ #category : '*ChessCoach-UI' }
HomeLatestGamesWidget >> optionRowsOn: aHomeElement [

	^ { (self countRowOn: aHomeElement max: 20) }
	  , (self filterRowsOn: aHomeElement)
]

{ #category : '*ChessCoach-UI' }
HomeLatestGamesWidget >> rowsOn: aHomeElement [

	^ self
		  gameRows: (aHomeElement session gamesPassing: self filter)
		  on: aHomeElement
]
