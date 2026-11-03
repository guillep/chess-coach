Class {
	#name : 'MoveComparisonTableTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
MoveComparisonTableTest >> testDatabaseColumns [
	"With a Lichess login, the database's counts fill the rows and its most played moves are added"

	| fixture session explorer table before |
	fixture := CoachReviewTest new.
	fixture setUp.
	session := (LichessAPIClientStub withGames: 0) newSessionOn:
		           FileSystem memory root.
	explorer := LichessExplorerClientStub new.
	before := fixture game positionAfterPly: 6.
	explorer at: before fen moves: {
			{ 'd4'. 60. 20. 20 }.
			{ 'Ng5'. 30. 10. 60 }.
			{ 'O-O'. 50. 30. 20 } }.
	session explorer: explorer.
	table := MoveComparisonTable
		         session: session
		         game: fixture game
		         ply: 7
		         analysis: fixture analysisForTests
		         candidates: Dictionary new
		         runner: [ :aBlock | aBlock value ].
	table rebuild.
	self
		assert: (table rows collect: [ :each | each first ]) asArray
		equals: #( 'd4' 'Nc3' 'Ng5' 'O-O' ).
	self
		assert:
		(table rows detect: [ :each | each first = 'Ng5' ]) allButFirst
		equals: #( 'played' '-1.50' 'worse' '100' '30/10/60' )
]

{ #category : 'tests' }
MoveComparisonTableTest >> testLaysOutInASpace [

	| fixture session table space |
	fixture := CoachReviewTest new.
	fixture setUp.
	session := (LichessAPIClientStub withGames: 0) newSessionOn:
		           FileSystem memory root.
	table := MoveComparisonTable
		         session: session
		         game: fixture game
		         ply: 7
		         analysis: fixture analysisForTests
		         candidates: Dictionary new
		         runner: [ :aBlock | aBlock value ].
	space := BlSpace new.
	space extent: 400 @ 400.
	space root addChild: (ToElement new
			 layout: BlLinearLayout vertical;
			 width: 340;
			 vFitContent;
			 addChild: table;
			 yourself).
	space pulse.
	self assert: table width > 0
]

{ #category : 'tests' }
MoveComparisonTableTest >> testRowsWithoutTheDatabase [

	| fixture session table |
	fixture := CoachReviewTest new.
	fixture setUp.
	session := (LichessAPIClientStub withGames: 0) newSessionOn:
		           FileSystem memory root.
	table := MoveComparisonTable
		         session: session
		         game: fixture game
		         ply: 7
		         analysis: fixture analysisForTests
		         candidates: (Dictionary new
				          at: 'd2d3' put: 52;
				          yourself)
		         runner: [ :aBlock | aBlock value ].
	self
		assert: (table rows collect: [ :each | each first ]) asArray
		equals: #( 'd4' 'Nc3' 'Ng5' 'd3' )
]
