Extension { #name : 'HomeNumbersWidget' }

{ #category : '*ChessCoach-UI' }
HomeNumbersWidget >> optionRowsOn: aHomeElement [

	^ (#( 'games' 'reviewed' 'mistake' 'winrate' 'rating' 'streak' )
		   collect: [ :key |
				   | shown |
				   shown := self shownNumbers includes: key.
				   self
					   cycle: key capitalized
					   values: #( 'shown' 'hidden' )
					   current: (shown
							    ifTrue: [ 'shown' ]
							    ifFalse: [ 'hidden' ])
					   do: [ :value |
							   self option: 'numbers' put: (value = 'shown'
									    ifTrue: [ self shownNumbers , { key } ]
									    ifFalse: [ self shownNumbers copyWithout: key ]) ]
					   on: aHomeElement ]) , (self filterRowsOn: aHomeElement)
]

{ #category : '*ChessCoach-UI' }
HomeNumbersWidget >> rowsOn: aHomeElement [
	"Winrate and streak read the latest 100 games, so opening the Home stays fast"

	| session games recent points records states lines streak |
	session := aHomeElement session.
	games := session gamesPassing: self filter.
	states := session reviewStates.
	recent := games first: (games size min: 100).
	points := recent collect: [ :entry |
			          | game |
			          game := session gameFor: entry.
			          session
				          pointsIn: game
				          as: (session myColorsIn: game) first ].
	records := session mistakeDatabase.
	streak := (points
		           detectIndex: [ :each | each < 1 ]
		           ifNone: [ points size + 1 ]) - 1.
	lines := OrderedCollection new.
	self shownNumbers do: [ :each |
			each = 'games' ifTrue: [
				lines add: games size printString , ' games' ].
			each = 'reviewed' ifTrue: [
					lines add: (games count: [ :entry |
							 states includesKey: entry gameId ])
							printString , ' reviewed' ].
			each = 'mistake' ifTrue: [
					lines add: (records tagFrequencies
							 ifEmpty: [ 'No mistakes tagged yet' ]
							 ifNotEmpty: [ :frequencies |
									 'Most frequent mistake: '
									 ,
									 (MistakeTaxonomy default tagAt: frequencies keys first) name ]) ].
			each = 'winrate' ifTrue: [
					points ifNotEmpty: [
							lines add:
								'Winrate: '
								, (points sum * 100 / points size) rounded printString
								, '% (latest ' , points size printString , ')' ] ].
			each = 'rating' ifTrue: [
					| speed |
					speed := (self filter at: 'speed') ifNil: [ 'blitz' ].
					(session lichessRatingAt: speed) ifNotNil: [ :rating |
						lines add: 'Rating (' , speed , '): ' , rating printString ] ].
			each = 'streak' ifTrue: [
				lines add: 'Winning streak: ' , streak printString ] ].
	^ lines asArray collect: [ :each | ToLabel text: each ]
]
