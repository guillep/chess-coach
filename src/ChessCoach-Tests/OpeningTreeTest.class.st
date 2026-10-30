"
I test the opening tree model with games parsed from PGN.
"
Class {
	#name : 'OpeningTreeTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
OpeningTreeTest >> gameWith: aMoveText [

	^ PGNParser new parse: aMoveText
]

{ #category : 'helpers' }
OpeningTreeTest >> newTree [

	^ OpeningTree
		  named: 'Test'
		  color: #white
		  speed: nil
		  from: nil
		  to: nil
		  databaseSource: 'lichess'
		  databaseSpeed: 'blitz'
		  ratings: #(  )
]

{ #category : 'tests' }
OpeningTreeTest >> testPeriodCountsBackFromToday [

	| tree |
	tree := self newTree.
	tree period: 7.
	self assert: (tree matchesDate: Date today yyyymmdd).
	self deny: (tree matchesDate: (Date today subtractDays: 8) yyyymmdd)
]

{ #category : 'tests' }
OpeningTreeTest >> testTranspositionsMergeAndSingleGameBranchesEnd [

	| tree node |
	tree := self newTree.
	tree addGame: (self gameWith: '1. d4 Nf6 2. c4 *') points: 1.
	tree addGame: (self gameWith: '1. c4 Nf6 2. d4 e6 *') points: 0.
	tree addGame: (self gameWith: '1. d4 d5 *') points: 0.5.
	tree finishBuildingOn: '2026-10-30'.
	self assert: tree root games equals: 3.
	self assert: tree root moves first san equals: 'd4'.
	self assert: tree root moves first games equals: 2.
	self assert: tree root moves first score equals: 0.75.
	node := tree nodeAt: tree root moves first nextKey.
	self assert: node games equals: 2.
	self
		assert: (node moves collect: [ :each | each san ]) asSet
		equals: #( 'Nf6' 'd5' ) asSet.
	self assert:
		(tree nodeAt:
			 (node moves detect: [ :each | each san = 'd5' ]) nextKey) isNil
]

{ #category : 'tests' }
OpeningTreeTest >> testWeakSpotsAndJSONRoundTrip [

	| tree reread |
	tree := self newTree.
	5 timesRepeat: [
		tree addGame: (self gameWith: '1. e4 c5 *') points: 0 ].
	tree finishBuildingOn: '2026-10-30'.
	tree root database: (Dictionary new
			 at: 'moves' put: { (Dictionary new
					  at: 'uci' put: 'e2e4';
					  at: 'san' put: 'e4';
					  at: 'white' put: 50;
					  at: 'draws' put: 0;
					  at: 'black' put: 50;
					  yourself) };
			 yourself).
	self assert: tree lowScoreSpots first san equals: 'e4'.
	self assert: tree prepGapSpots first san equals: 'c5'.
	self assert: tree scoreGapSpots first gap equals: 1 / 2.
	reread := OpeningTree fromJSON: tree asJSON.
	self assert: reread gameCount equals: 5.
	self assert: reread color equals: #white.
	self assert: reread scoreGapSpots first san equals: 'e4'
]
