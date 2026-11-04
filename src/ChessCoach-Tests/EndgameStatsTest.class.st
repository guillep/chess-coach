Class {
	#name : 'EndgameStatsTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
EndgameStatsTest >> rookEndgameStats [
	"One game won from R+2P vs R: 'R vs R' from the start, 'R vs pawns' from ply 7"

	^ (EndgameStats maxPieces: 4)
		  addGame:
			  (PGNParser new parse: '[FEN "4k3/r7/8/8/8/8/PP6/R3K3 w - - 0 1"]
[SetUp "1"]

1. a3 Ke7 2. b4 Ke6 3. b5 Rxa3 4. Rxa3 Kd5 5. Ra8 Kc5 6. Kd2 Kxb5 7. Kc3 Kb6 8. Kd4 Kb7 9. Ra1')
		  id: 'g1'
		  color: #white
		  points: 1
		  analysis: nil;
		  yourself
]

{ #category : 'tests' }
EndgameStatsTest >> testAnUnreadableGameIsSkippedNotFatal [
	"Faouzi's hard quit when counting endgames: one game that fails no longer stops the count (nor the app)"

	| session page |
	session := (LichessAPIClientStub withGames: 3) newSessionOn:
		           FileSystem memory root.
	session login.
	session loadMoreGames.
	session games first instVarNamed: #gameId put: 'missing-game'.
	page := EndgamesPage new.
	page session: session runner: [ :aBlock | aBlock value ].
	self shouldnt: [ page count ] raise: Error.
	self assert: page stats notNil.
	self assert: page stats skipped >= 1
]

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
EndgameStatsTest >> testFewerPiecesNeverCountMoreGames [
	"A position with at most N pieces also has at most N+1: the games counted with N are a subset of those counted with any larger N, so smaller totals for 1 piece than for 6 are expected"

	| game gamesWith |
	game := PGNParser new parse:
		        '[FEN "4k3/r7/8/8/8/8/PP6/R3K3 w - - 0 1"]
[SetUp "1"]

1. a3 Ke7 2. b4 Ke6 3. b5 Rxa3 4. Rxa3 Kd5 5. Ra8 Kc5 6. Kd2 Kxb5 7. Kc3 Kb6 8. Kd4 Kb7 9. Ra1'.
	gamesWith := [ :maxPieces |
		             | stats |
		             stats := EndgameStats maxPieces: maxPieces.
		             stats
			             addGame: game
			             id: 'g1'
			             color: #white
			             points: 1
			             analysis: nil.
		             stats
			             addGame: (PGNParser new parse: '1. e4 e5 2. Nf3 Nc6')
			             id: 'g2'
			             color: #white
			             points: 0
			             analysis: nil.
		             (stats configurations values flatCollect: [ :each |
			              each collect: [ :occurrence | occurrence gameId ] ])
			             asSet ].
	0 to: 5 do: [ :n |
			self
				assert: ((gamesWith value: n) includesAll: (gamesWith value: n));
				assert:
					((gamesWith value: n + 1) includesAll: (gamesWith value: n)) ].
	self assert: (gamesWith value: 0) isEmpty.
	self assert: (gamesWith value: 1) asArray equals: #( 'g1' ).
	self deny: ((gamesWith value: 6) includes: 'g2')
]

{ #category : 'tests' }
EndgameStatsTest >> testThePageShowsAConfiguration [

	| session page |
	session := (LichessAPIClientStub withGames: 0) newSessionOn:
		           FileSystem memory root.
	page := EndgamesPage new.
	page session: session runner: [ :aBlock |  ].
	page stats: self rookEndgameStats for: 4.
	self
		assert: (page rows collect: [ :each | each name ]) asSet
		equals: #( 'R vs R' 'R vs pawns' ) asSet.
	page select: 'R vs R'.
	self
		assert: page overviewTexts asArray
		equals: { '1 games · 1W 0D 0L'. 'Entered worse: saved —'.
			'Entered better: converted —'. 'Games not analysed have no evaluation.'.
			'2 vs 0 pawns: 1W 0D 0L' }
]

{ #category : 'tests' }
EndgameStatsTest >> testTheUpsetFilter [
	"Only R vs pawns has an upset (entered losing, drew)"

	| session stats page |
	session := (LichessAPIClientStub withGames: 0) newSessionOn:
		           FileSystem memory root.
	stats := EndgameStats maxPieces: 4.
	(stats instVarNamed: #occurrences)
		at: 'R vs R' put: (OrderedCollection with: (EndgameOccurrence
						  gameId: 'a'
						  ply: 60
						  myPawns: 1
						  theirPawns: 1
						  points: 1 / 2
						  evaluation: 0.1));
		at: 'R vs pawns' put: (OrderedCollection with: (EndgameOccurrence
						  gameId: 'b'
						  ply: 70
						  myPawns: 0
						  theirPawns: 3
						  points: 1 / 2
						  evaluation: -4)).
	page := EndgamesPage new.
	page session: session runner: [ :aBlock |  ].
	page stats: stats for: 4.
	session settings at: 'endgameUpsetFilter' put: 'with'.
	self
		assert: (page rows collect: [ :each | each name ]) asArray
		equals: #( 'R vs pawns' ).
	session settings at: 'endgameUpsetFilter' put: 'without'.
	self
		assert: (page rows collect: [ :each | each name ]) asArray
		equals: #( 'R vs R' ).
	self assert: (page rows first savedText: page zones) equals: '—'.
	self
		assert:
			((stats rows detect: [ :each | each name = 'R vs pawns' ])
				 savedText: page zones)
		equals: '1/1'
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
