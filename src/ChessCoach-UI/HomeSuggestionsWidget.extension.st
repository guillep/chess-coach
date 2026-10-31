Extension { #name : 'HomeSuggestionsWidget' }

{ #category : '*ChessCoach-UI' }
HomeSuggestionsWidget >> optionRowsOn: aHomeElement [

	^ { (self countRowOn: aHomeElement max: 10) }
	  , (self filterRowsOn: aHomeElement)
]

{ #category : '*ChessCoach-UI' }
HomeSuggestionsWidget >> rowsOn: aHomeElement [

	^ self
		  gameRows: (aHomeElement session suggestedGames: self filter)
		  on: aHomeElement
]
