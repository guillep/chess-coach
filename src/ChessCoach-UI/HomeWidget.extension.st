Extension { #name : 'HomeWidget' }

{ #category : '*ChessCoach-UI' }
HomeWidget >> countRowOn: aHomeElement max: aNumber [

	^ self
		  cycle: 'Count'
		  values: (1 to: aNumber) asArray
		  current: self count
		  do: [ :value | self option: 'count' put: value ]
		  on: aHomeElement
]

{ #category : '*ChessCoach-UI' }
HomeWidget >> cycle: aLabel values: someValues current: aValue do: aBlock on: aHomeElement [
	"A button naming the value; a click moves to the next one and refreshes the Home"

	^ ToButton new
		  labelText: aLabel , ': ' , (aValue ifNil: [ 'any' ]) asString;
		  clickAction: [
				  aBlock value:
						  (someValues at:
								   (someValues indexOf: aValue) \\ someValues size + 1).
				  aHomeElement update ];
		  yourself
]

{ #category : '*ChessCoach-UI' }
HomeWidget >> filterRowsOn: aHomeElement [

	^ {
		  ('Result' -> #( nil 'won' 'lost' 'draw' ) -> 'result').
		  ('Color' -> #( nil 'white' 'black' ) -> 'color').
		  ('Speed' -> #( nil 'bullet' 'blitz' 'rapid' 'classical' )
		   -> 'speed').
		  ('Source' -> #( nil 'lichess' 'chess.com' ) -> 'source').
		  ('Last days' -> #( nil 7 30 90 365 ) -> 'days').
		  ('Review' -> #( nil 'unreviewed' 'inProgress' 'reviewed' )
		   -> 'review') } collect: [ :each |
			  self
				  cycle: each key key
				  values: each key value
				  current: (self filter at: each value)
				  do: [ :value | self filterAt: each value put: value ]
				  on: aHomeElement ]
]

{ #category : '*ChessCoach-UI' }
HomeWidget >> gameRows: someEntries on: aHomeElement [
	"A button per game, or a friendly line: the card stays in its place"

	someEntries ifEmpty: [ ^ { (ToLabel text: 'No games right now') } ].
	^ (someEntries first: (someEntries size min: self count)) collect: [
		  :each | aHomeElement gameButton: each ]
]
