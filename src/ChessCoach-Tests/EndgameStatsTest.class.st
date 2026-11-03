Class {
	#name : 'EndgameStatsTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
EndgameStatsTest >> testConfigurationsAGameWentThrough [
	"From R+2P vs R: 'R vs R' until 4. Rxa3 takes the black rook, then 'R vs pawns'; each held for 2 moves or more"

	| game stats configurations occurrence |
	game := PGNParser new parse:
		        '[FEN "4k3/r7/8/8/8/8/PP6/R3K3 w - - 0 1"]
[SetUp "1"]

1. a3 Ke7 2. b4 Ke6 3. b5 Rxa3 4. Rxa3 Kd5 5. Ra8 Kc5 6. Kd2 Kxb5 7. Kc3 Kb6 8. Kd4 Kb7 9. Ra1'.
	stats := EndgameStats maxPieces: 4.
	stats
		addGame: game
		id: 'g1'
		color: #white
		points: 1
		analysis: nil.
	configurations := stats configurations.
	self
		assert: configurations keys asSet
		equals: #( 'R vs R' 'R vs pawns' ) asSet.
	occurrence := (configurations at: 'R vs R') first.
	self assert: occurrence ply equals: 0.
	self assert: occurrence pawnsText equals: '2 vs 0 pawns'.
	self assert: (configurations at: 'R vs pawns') first ply equals: 7.
	self
		assert: (EndgameStats resultsText: (configurations at: 'R vs R'))
		equals: '1W 0D 0L'.
	stats := EndgameStats maxPieces: 1.
	stats
		addGame: game
		id: 'g1'
		color: #white
		points: 1
		analysis: nil.
	self
		assert: stats configurations keys asArray
		equals: #( 'R vs pawns' )
]

{ #category : 'tests' }
EndgameStatsTest >> testThePageShowsAConfiguration [

	| session stats page |
	session := (LichessAPIClientStub withGames: 0) newSessionOn:
		           FileSystem memory root.
	stats := EndgameStats maxPieces: 4.
	stats
		addGame:
			(PGNParser new parse: '[FEN "4k3/r7/8/8/8/8/PP6/R3K3 w - - 0 1"]
[SetUp "1"]

1. a3 Ke7 2. b4 Ke6 3. b5 Rxa3 4. Rxa3 Kd5 5. Ra8 Kc5 6. Kd2 Kxb5 7. Kc3 Kb6 8. Kd4 Kb7 9. Ra1')
		id: 'g1'
		color: #white
		points: 1
		analysis: nil.
	page := EndgamesElement session: session runner: [ :aBlock |  ].
	page stats: stats for: 4.
	page select: 'R vs R'.
	self
		assert: page detailTexts asArray
		equals:
			{ '1 games · 1W 0D 0L'. 'Upsets: 0 for you (you entered worse and didn''t lose), 0 against you (you entered better and didn''t win); games not analysed have no evaluation'.
			'2 vs 0 pawns: 1W 0D 0L' }
]

{ #category : 'tests' }
EndgameStatsTest >> testUpsets [

	| zones |
	zones := EvaluationZones default.
	self
		assert: ((EndgameOccurrence
				  gameId: 'a'
				  ply: 0
				  myPawns: 1
				  theirPawns: 1
				  points: 1 / 2
				  evaluation: -1.5) upsetIn: zones)
		equals: #for.
	self
		assert: ((EndgameOccurrence
				  gameId: 'b'
				  ply: 0
				  myPawns: 1
				  theirPawns: 1
				  points: 1 / 2
				  evaluation: 1.5) upsetIn: zones)
		equals: #against.
	self assert: ((EndgameOccurrence
			  gameId: 'c'
			  ply: 0
			  myPawns: 1
			  theirPawns: 1
			  points: 1
			  evaluation: 0.2) upsetIn: zones) isNil.
	self assert: ((EndgameOccurrence
			  gameId: 'd'
			  ply: 0
			  myPawns: 1
			  theirPawns: 1
			  points: 0
			  evaluation: nil) upsetIn: zones) isNil
]
