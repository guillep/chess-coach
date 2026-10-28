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
ChessCoachIntegrationTest >> testFENBlackToMove [

	| board |
	board := ChessPosition fromFEN:
		         'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1'.
	self assert: board turn equals: #black
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testFENCastlingOrder [

	| board |
	board := ChessPosition fromFEN:
		         'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w QkKq - 0 1'.
	self assert: board castlingWhiteQueenSide.
	self assert: board castlingBlackKingSide.
	self assert: board castlingWhiteKingSide.
	self assert: board castlingBlackQueenSide
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testFENEmptyBoard [

	| board |
	board := ChessPosition fromFEN: '8/8/8/8/8/8/8/8 w - - 0 1'.
	self assert: board pieces isEmpty
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testFENEnPassant [

	| board |
	board := ChessPosition fromFEN:
		         'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'.
	self assert: board enPassantTarget equals: 'e3'.
	self assert: board turn equals: #black
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testFENEnPassantDash [

	| board |
	board := ChessPosition fromFEN:
		         'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'.
	self assert: board enPassantTarget isNil
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testFENHalfMoveAndFullMove [

	| board |
	board := ChessPosition fromFEN:
		         'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 5 10'.
	self assert: board halfmoveClock equals: 5.
	self assert: board fullmoveNumber equals: 10
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testFENHoles [

	| board |
	board := ChessPosition fromFEN: '8/8/8/3p4/3P4/8/8/8 w - - 0 1'.
	self assert: (board pieceAt: 'd4') equals: 'P'.
	self assert: (board pieceAt: 'd5') equals: 'p'
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testFENNoCastling [

	| board |
	board := ChessPosition fromFEN:
		         'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - - 0 1'.
	self deny: board castlingWhiteKingSide.
	self deny: board castlingWhiteQueenSide.
	self deny: board castlingBlackKingSide.
	self deny: board castlingBlackQueenSide
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testFENPartialCastling [

	| board |
	board := ChessPosition fromFEN:
		         'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w Kq - 0 1'.
	self assert: board castlingWhiteKingSide.
	self deny: board castlingWhiteQueenSide.
	self deny: board castlingBlackKingSide.
	self assert: board castlingBlackQueenSide
]

{ #category : 'tests' }
ChessCoachIntegrationTest >> testFENStartingPosition [

	| board |
	board := ChessPosition fromFEN:
		         'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'.
	self assert: (board pieceAt: 'e2') equals: 'P'.
	self assert: (board pieceAt: 'e7') equals: 'p'.
	self assert: board turn equals: #white.
	self assert: board castlingWhiteKingSide.
	self assert: board castlingWhiteQueenSide.
	self assert: board castlingBlackKingSide.
	self assert: board castlingBlackQueenSide.
	self assert: board enPassantTarget isNil.
	self assert: board halfmoveClock equals: 0.
	self assert: board fullmoveNumber equals: 1
]

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
ChessCoachIntegrationTest >> testPGNParsing [

	| pgn game |
	pgn := '[Event "Test"]' , String crlf , String crlf , '1. e4 e5'.
	game := PGNParser new parse: pgn.
	self assert: (game metadata at: 'Event') equals: 'Test'.
	self assert: game moves size equals: 2.
	self assert: game moves first san equals: 'e4'
]
