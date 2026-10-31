"
I compare each opening move of the given colors with what scores best in the Lichess database at the mover's rating (±200) and the game's speed.
A move is a moment when it scores 5 points or more below the best candidate (candidates need 50 games), or is barely played while other moves are common. I stop once a position has fewer than 50 games.
"
Class {
	#name : 'OpeningWinRateFinder',
	#superclass : 'MomentFinder',
	#instVars : [
		'game',
		'explorer',
		'colors',
		'problem'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
OpeningWinRateFinder class >> game: aGame explorer: aLichessExplorerClient colors: someColors [
	"Examine only the moves of someColors (#white and/or #black)"

	^ self new
		  setGame: aGame
		  explorer: aLichessExplorerClient
		  colors: someColors
]

{ #category : 'private' }
OpeningWinRateFinder >> databaseMovesFrom: aPosition [
	"Explorer data for aPosition at the mover's rating and the game's speed"

	| eloTag |
	eloTag := aPosition turn = #white
		          ifTrue: [ 'WhiteElo' ]
		          ifFalse: [ 'BlackElo' ].
	^ explorer
		  lichessMovesFor: aPosition fen
		  speed: (LichessExplorerClient speedForTimeControl:
				   (game metadata at: 'TimeControl' ifAbsent: [ nil ]))
		  ratings: ((game metadata at: eloTag ifAbsent: [ nil ])
				   ifNil: [ #(  ) ]
				   ifNotNil: [ :elo |
				   LichessExplorerClient ratingBucketsAround: elo asInteger ])
]

{ #category : 'private' }
OpeningWinRateFinder >> describeTop: candidates for: aColor [

	^ ', ' join: (((candidates asArray sort: [ :a :b |
			     (self score: a for: aColor) > (self score: b for: aColor) ])
			    first: (3 min: candidates size)) collect: [ :each |
				   (each at: 'san') , ' ('
				   , (self percent: (self score: each for: aColor)) , ')' ])
]

{ #category : 'private' }
OpeningWinRateFinder >> gameCountOf: data [

	^ (data at: 'white') + (data at: 'draws') + (data at: 'black')
]

{ #category : 'accessing' }
OpeningWinRateFinder >> minimumGames [

	^ self threshold: 'momentOpeningMinimumGames'
]

{ #category : 'private' }
OpeningWinRateFinder >> momentForMove: aSAN ply: aPly color: aColor in: data [

	| candidates best played note |
	candidates := (data at: 'moves') select: [ :each |
		              (self gameCountOf: each) >= self minimumGames ].
	candidates ifEmpty: [ ^ nil ].
	best := candidates detectMax: [ :each | self score: each for: aColor ].
	played := (data at: 'moves')
		          detect: [ :each |
			          (self normalizedSAN: (each at: 'san'))
			          = (self normalizedSAN: aSAN) ]
		          ifNone: [ nil ].
	note := (played isNil or: [
		         (self gameCountOf: played) < self minimumGames ])
		        ifTrue: [
				        'You played {1}, rarely seen at your level; usual moves: {2}'
					        format: {
							        aSAN.
							        (self describeTop: candidates for: aColor) } ]
		        ifFalse: [
				        (self score: played for: aColor) + (self threshold: 'momentOpeningScoreGap')
				        <= (self score: best for: aColor) ifFalse: [ ^ nil ].
				        'You played {1} ({2}); better scoring: {3}' format: {
						        aSAN.
						        (self percent: (self score: played for: aColor)).
						        (self describeTop: candidates for: aColor) } ].
	^ ChessMoment
		  ply: aPly
		  color: aColor
		  kind: #openingChoice
		  source: #explorer
		  note: note
]

{ #category : 'finding' }
OpeningWinRateFinder >> moments [
	"When the explorer can't be reached or refuses the request, the moments found so far are answered and the reason is kept in problem"

	| moments |
	moments := OrderedCollection new.
	[
		game moves withIndexDo: [ :move :ply |
				| position data |
				position := game positionAfterPly: ply - 1.
				(colors includes: position turn) ifTrue: [
						data := self databaseMovesFrom: position.
						(self gameCountOf: data) < self minimumGames ifTrue: [
							^ moments ].
						(self
							 momentForMove: move san
							 ply: ply
							 color: position turn
							 in: data) ifNotNil: [ :moment | moments add: moment ] ] ] ]
		on: LichessError , NetworkError
		do: [ :error |
			problem := 'Opening statistics unavailable: ' , error messageText ].
	^ moments
]

{ #category : 'private' }
OpeningWinRateFinder >> normalizedSAN: aString [

	^ aString reject: [ :each | '+#!?' includes: each ]
]

{ #category : 'private' }
OpeningWinRateFinder >> percent: aNumber [

	^ (aNumber printShowingDecimalPlaces: 0) , '%'
]

{ #category : 'accessing' }
OpeningWinRateFinder >> problem [
	"Why the explorer could not be used, or nil"

	^ problem
]

{ #category : 'private' }
OpeningWinRateFinder >> score: data for: aColor [
	"Percentage of points scored by aColor: wins plus half the draws"

	| wins |
	wins := data at: aColor asString.
	^ 100 * (wins + ((data at: 'draws') / 2)) / (self gameCountOf: data)
]

{ #category : 'initialization' }
OpeningWinRateFinder >> setGame: aGame explorer: aLichessExplorerClient colors: someColors [

	game := aGame.
	explorer := aLichessExplorerClient.
	colors := someColors
]
