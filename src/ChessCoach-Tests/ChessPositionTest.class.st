Class {
	#name : 'ChessPositionTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
ChessPositionTest >> testCastling [

	| position |
	position := (ChessPosition fromFEN:
		             'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1') moves:
		            #( 'O-O' 'O-O-O' ).
	self assert: position fen equals: '2kr3r/8/8/8/8/8/8/R4RK1 w - - 2 2'
]

{ #category : 'tests' }
ChessPositionTest >> testDisambiguationByFile [

	| position |
	position := (ChessPosition fromFEN:
		             '8/8/8/8/8/8/8/1N1K1N1k w - - 0 1') move: 'Nbd2'.
	self assert: position fen equals: '8/8/8/8/8/8/3N4/3K1N1k b - - 1 1'
]

{ #category : 'tests' }
ChessPositionTest >> testEnPassant [

	| position |
	position := (ChessPosition fromFEN:
		             'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3')
		            move: 'exd6'.
	self
		assert: position fen
		equals: 'rnbqkbnr/ppp1pppp/3P4/8/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 3'
]

{ #category : 'tests' }
ChessPositionTest >> testInitialPosition [

	self
		assert: ChessPosition initial fen
		equals: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
]

{ #category : 'tests' }
ChessPositionTest >> testMoveAnswersNewPosition [

	| initial next |
	initial := ChessPosition initial.
	next := initial move: 'e4'.
	self
		assert: initial fen
		equals: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'.
	self
		assert: next fen
		equals:
		'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'
]

{ #category : 'tests' }
ChessPositionTest >> testMovesOperaGame [
	"Morphy vs Duke of Brunswick and Count Isouard, Paris 1858"

	| position |
	position := ChessPosition initial moves:
		            #( 'e4' 'e5' 'Nf3' 'd6' 'd4' 'Bg4' 'dxe5' 'Bxf3' 'Qxf3'
		               'dxe5' 'Bc4' 'Nf6' 'Qb3' 'Qe7' 'Nc3' 'c6' 'Bg5' 'b5'
		               'Nxb5' 'cxb5' 'Bxb5+' 'Nbd7' 'O-O-O' 'Rd8' 'Rxd7'
		               'Rxd7' 'Rd1' 'Qe6' 'Bxd7+' 'Nxd7' 'Qb8+' 'Nxb8'
		               'Rd8#' ).
	self
		assert: position fen
		equals: '1n1Rkb1r/p4ppp/4q3/4p1B1/4P3/8/PPP2PPP/2K5 b k - 1 17'
]

{ #category : 'tests' }
ChessPositionTest >> testMovesRuyLopez [

	| position |
	position := ChessPosition initial moves:
		            #( 'e4' 'e5' 'Nf3' 'Nc6' 'Bb5' 'a6' ).
	self
		assert: position fen
		equals:
		'r1bqkbnr/1ppp1ppp/p1n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 4'
]

{ #category : 'tests' }
ChessPositionTest >> testPinnedPieceIsNotACandidate [

	| position |
	position := (ChessPosition fromFEN:
		             '8/8/8/b7/8/2N5/8/4K1Nk w - - 0 1') move: 'Ne2'.
	self assert: position fen equals: '8/8/8/b7/8/2N5/4N3/4K2k b - - 1 1'
]

{ #category : 'tests' }
ChessPositionTest >> testPromotion [

	| position |
	position := (ChessPosition fromFEN: '8/P7/8/8/8/8/8/k6K w - - 0 1')
		            move: 'a8=Q+'.
	self assert: position fen equals: 'Q7/8/8/8/8/8/8/k6K b - - 0 1'
]

{ #category : 'tests' }
ChessPositionTest >> testUnplayableMoveSignalsIllegalMove [

	self
		should: [ ChessPosition initial move: 'Nd4' ]
		raise: ChessIllegalMove
]
