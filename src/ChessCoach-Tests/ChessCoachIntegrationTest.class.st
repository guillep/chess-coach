"
Integration tests for the chess coach system. Tests file storage, game loading, and basic review flow.
"
Class {
	#name : 'ChessCoachIntegrationTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
ChessCoachIntegrationTest >> testGameIndexCreation [
	"Test that we can create and manage a game index"

	| index entry |
	index := GameIndex new.
	self assert: index entries isEmpty.

	entry := GameIndexEntry new.
	entry
		gameId: 'game1'
		filepath: 'games/game1.json'
		dateImported: DateAndTime now asString
		source: 'test'
		players: #( 'player1' 'player2' )
		result: '1-0'
		date: '2024-10-15'.
	index addEntry: entry.

	self assert: index entries size equals: 1.
	self assert: (index findById: 'game1') notNil
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testGameReviewNavigation [
	"Test that we can create and navigate a game review"

	| game moves review |
	moves := OrderedCollection new.
	moves add: (ChessMove new
			 moveNumber: 1
			 color: #white
			 san: 'e4'
			 uci: 'e2e4'
			 timestamp: 0).
	moves add: (ChessMove new
			 moveNumber: 1
			 color: #black
			 san: 'e5'
			 uci: 'e7e5'
			 timestamp: 0).

	game := ChessGame new.
	game
		gameId: 'testgame'
		pgn: '[Event "Test"]\n1. e4 e5'
		metadata: Dictionary new
		moves: moves
		board: nil.

	review := GameReview new game: game positions: #(  ).
	self assert: review game equals: game.
	self assert: review currentPosition isNil
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testPGNParsing [

	| pgn game |
	pgn := '[Event "Test"]' , String crlf , String crlf , '1. e4 e5'.
	game := PGNParser new parse: pgn.
	self assert: (game metadata at: 'Event') equals: 'Test'.
	self assert: game moves size equals: 2.
	self assert: game moves first san equals: 'e4'
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testSocraticCoachPrompts [
	"Test that the Socratic coach provides meaningful prompts"

	| coach position prompt |
	coach := SocraticCoach new.
	position := ReviewPosition new
		            moveNumber: 5
		            board: nil
		            movePlayedSAN: 'Nf3'.

	prompt := coach promptForRecall: position.
	self assert: (prompt includesSubstring: 'move').
	self assert: (prompt includesSubstring: '5')
]
