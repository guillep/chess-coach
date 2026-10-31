Extension { #name : 'HomeNotificationsWidget' }

{ #category : '*ChessCoach-UI' }
HomeNotificationsWidget >> optionRowsOn: aHomeElement [

	| rows hidden |
	hidden := self option: 'hiddenKinds' ifAbsent: [ #(  ) ].
	rows := #( 'newGames' 'update' 'error' ) collect: [ :kind |
			        self
				        cycle: kind capitalized
				        values: #( 'shown' 'hidden' )
				        current: ((hidden includes: kind)
						         ifTrue: [ 'hidden' ]
						         ifFalse: [ 'shown' ])
				        do: [ :value |
						        self option: 'hiddenKinds' put: (value = 'hidden'
								         ifTrue: [ hidden , { kind } ]
								         ifFalse: [ hidden copyWithout: kind ]) ]
				        on: aHomeElement ].
	^ {
		  (self countRowOn: aHomeElement max: 20).
		  (self
			   cycle: 'Unread only'
			   values: #( 'no' 'yes' )
			   current: ((self option: 'unreadOnly' ifAbsent: [ false ])
					    ifTrue: [ 'yes' ]
					    ifFalse: [ 'no' ])
			   do: [ :value | self option: 'unreadOnly' put: value = 'yes' ]
			   on: aHomeElement) } , rows
]

{ #category : '*ChessCoach-UI' }
HomeNotificationsWidget >> rowsOn: aHomeElement [

	| shown hidden rows |
	hidden := self option: 'hiddenKinds' ifAbsent: [ #(  ) ].
	shown := aHomeElement session notifications visible reject: [ :each |
			         (hidden includes: each kind asString) or: [
				         (self option: 'unreadOnly' ifAbsent: [ false ]) and: [
					         each isRead ] ] ].
	shown ifEmpty: [ ^ { (ToLabel text: 'No notifications') } ].
	rows := OrderedCollection new.
	(shown first: (shown size min: self count))
		do: [ :each | rows add: (aHomeElement notificationRow: each) ]
		separatedBy: [ rows add: ChessCoachWidgets separator ].
	^ rows asArray
]
