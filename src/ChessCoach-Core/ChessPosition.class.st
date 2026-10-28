"
Represents the current state of a chess board. Maintains position in Forsyth-Edwards Notation (FEN) and provides methods to play/unplay moves and compute legal moves.
"
Class {
	#name : 'ChessPosition',
	#superclass : 'Object',
	#instVars : [
		'halfMoveClock',
		'fullMoveNumber',
		'turn',
		'castlingWhiteKingSide',
		'castlingWhiteQueenSide',
		'castlingBlackKingSide',
		'castlingBlackQueenSide',
		'enPassantTarget',
		'pieces',
		'lastMoveUCI'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'instance creation' }
ChessPosition class >> fromFEN: aString [
	^ self new parseFEN: aString
]

{ #category : 'instance creation' }
ChessPosition class >> initial [

	^ self fromFEN:
		  'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
]

{ #category : 'private - moving' }
ChessPosition >> applyPieceMove: aCleanSAN san: aSAN [

	| body letter promotion target hint |
	body := aCleanSAN.
	promotion := nil.
	(body includes: $=) ifTrue: [
			promotion := body last asString.
			body := body copyUpTo: $= ].
	body ifEmpty: [ ChessIllegalMove signalSAN: aSAN position: self ].
	('KQRBN' includes: body first)
		ifTrue: [
				letter := body first asString.
				body := body allButFirst ]
		ifFalse: [ letter := 'P' ].
	body := body reject: [ :c | c = $x ].
	body size < 2 ifTrue: [
		ChessIllegalMove signalSAN: aSAN position: self ].
	target := body last: 2.
	hint := body allButLast: 2.
	(self isSquare: target) ifFalse: [
		ChessIllegalMove signalSAN: aSAN position: self ].
	self
		movePieceFrom: (self
				 originOf: letter
				 to: target
				 hint: hint
				 san: aSAN)
		to: target
		promotion: promotion
]

{ #category : 'private - moving' }
ChessPosition >> applySAN: aSAN [

	| san |
	san := aSAN reject: [ :c | '+#!?' includes: c ].
	(san = 'O-O' or: [ san = '0-0' ]) ifTrue: [
		^ self castleKingSide: true san: aSAN ].
	(san = 'O-O-O' or: [ san = '0-0-0' ]) ifTrue: [
		^ self castleKingSide: false san: aSAN ].
	self applyPieceMove: san san: aSAN
]

{ #category : 'private - moving' }
ChessPosition >> canCastleTo: aKingTarget [

	| rank kingSide allowed rookFile |
	rank := turn = #white
		        ifTrue: [ 1 ]
		        ifFalse: [ 8 ].
	kingSide := (self fileOf: aKingTarget) = 7.
	allowed := kingSide
		           ifTrue: [
				           turn = #white
					           ifTrue: [ castlingWhiteKingSide ]
					           ifFalse: [ castlingBlackKingSide ] ]
		           ifFalse: [
				           turn = #white
					           ifTrue: [ castlingWhiteQueenSide ]
					           ifFalse: [ castlingBlackQueenSide ] ].
	allowed ifFalse: [ ^ false ].
	rookFile := kingSide
		            ifTrue: [ 8 ]
		            ifFalse: [ 1 ].
	^ self
		  isPathClearFrom: (self squareAtFile: 5 rank: rank)
		  to: (self squareAtFile: rookFile rank: rank)
]

{ #category : 'private - moving' }
ChessPosition >> canMove: aLetter from: from to: to [

	(self pieceAt: to) ifNotNil: [ :captured |
		(self colorOf: captured) = turn ifTrue: [ ^ false ] ].
	aLetter = 'P' ifTrue: [ ^ self canPawnMoveFrom: from to: to ].
	^ self canPiece: aLetter from: from attack: to
]

{ #category : 'private - moving' }
ChessPosition >> canPawnMoveFrom: from to: to [

	| direction df dr |
	direction := turn = #white
		             ifTrue: [ 1 ]
		             ifFalse: [ -1 ].
	df := (self fileOf: to) - (self fileOf: from).
	dr := (self rankOf: to) - (self rankOf: from).
	df abs = 1 ifTrue: [
			^ dr = direction and: [
				  (self pieceAt: to) notNil or: [ to = enPassantTarget ] ] ].
	(df = 0 and: [ (self pieceAt: to) isNil ]) ifFalse: [ ^ false ].
	dr = direction ifTrue: [ ^ true ].
	^ dr = (2 * direction) and: [
			  (self rankOf: from) = (turn = #white
				   ifTrue: [ 2 ]
				   ifFalse: [ 7 ]) and: [
					  (self pieceAt: (self
							    squareAtFile: (self fileOf: from)
							    rank: (self rankOf: from) + direction)) isNil ] ]
]

{ #category : 'private - moving' }
ChessPosition >> canPiece: aLetter from: from attack: to [
	"Movement geometry of non-pawn pieces, including blockers on the path"

	| df dr |
	df := (self fileOf: to) - (self fileOf: from).
	dr := (self rankOf: to) - (self rankOf: from).
	(df = 0 and: [ dr = 0 ]) ifTrue: [ ^ false ].
	aLetter = 'N' ifTrue: [ ^ df abs * dr abs = 2 ].
	aLetter = 'K' ifTrue: [ ^ df abs <= 1 and: [ dr abs <= 1 ] ].
	aLetter = 'R' ifTrue: [
		^ (df = 0 or: [ dr = 0 ]) and: [ self isPathClearFrom: from to: to ] ].
	aLetter = 'B' ifTrue: [
		^ df abs = dr abs and: [ self isPathClearFrom: from to: to ] ].
	aLetter = 'Q' ifTrue: [
			^ (df = 0 or: [ dr = 0 or: [ df abs = dr abs ] ]) and: [
				  self isPathClearFrom: from to: to ] ].
	^ false
]

{ #category : 'private - moving' }
ChessPosition >> castleKingSide: isKingSide san: aSAN [

	| rank allowed rookFrom rookTo kingTo |
	rank := turn = #white
		        ifTrue: [ 1 ]
		        ifFalse: [ 8 ].
	isKingSide
		ifTrue: [
				allowed := turn = #white
					           ifTrue: [ castlingWhiteKingSide ]
					           ifFalse: [ castlingBlackKingSide ].
				rookFrom := 8.
				rookTo := 6.
				kingTo := 7 ]
		ifFalse: [
				allowed := turn = #white
					           ifTrue: [ castlingWhiteQueenSide ]
					           ifFalse: [ castlingBlackQueenSide ].
				rookFrom := 1.
				rookTo := 4.
				kingTo := 3 ].
	allowed ifFalse: [ ChessIllegalMove signalSAN: aSAN position: self ].
	pieces
		at: (self squareAtFile: rookTo rank: rank)
		put: (pieces removeKey: (self squareAtFile: rookFrom rank: rank)).
	self
		movePieceFrom: (self squareAtFile: 5 rank: rank)
		to: (self squareAtFile: kingTo rank: rank)
		promotion: nil
]

{ #category : 'accessing' }
ChessPosition >> castlingBlackKingSide [

	^ castlingBlackKingSide
]

{ #category : 'accessing' }
ChessPosition >> castlingBlackQueenSide [

	^ castlingBlackQueenSide
]

{ #category : 'private' }
ChessPosition >> castlingFEN [

	| stream |
	stream := WriteStream on: String new.
	castlingWhiteKingSide ifTrue: [ stream nextPut: $K ].
	castlingWhiteQueenSide ifTrue: [ stream nextPut: $Q ].
	castlingBlackKingSide ifTrue: [ stream nextPut: $k ].
	castlingBlackQueenSide ifTrue: [ stream nextPut: $q ].
	^ stream contents ifEmpty: [ '-' ]
]

{ #category : 'accessing' }
ChessPosition >> castlingWhiteKingSide [

	^ castlingWhiteKingSide
]

{ #category : 'accessing' }
ChessPosition >> castlingWhiteQueenSide [

	^ castlingWhiteQueenSide
]

{ #category : 'private - pieces' }
ChessPosition >> colorOf: aPiece [

	^ aPiece first isUppercase
		  ifTrue: [ #white ]
		  ifFalse: [ #black ]
]

{ #category : 'private - moving' }
ChessPosition >> disambiguationFor: aLetter from: from to: to [
	"File, rank or both of from, when another piece of the same kind could also legally move to to"

	| others |
	others := pieces keys select: [ :square |
			          square ~= from and: [
					          (pieces at: square)
					          = (self pieceLetter: aLetter color: turn) and: [
							          (self canMove: aLetter from: square to: to) and: [
								          (self moveLeavesKingInCheckFrom: square to: to) not ] ] ] ].
	others ifEmpty: [ ^ '' ].
	(others noneSatisfy: [ :each |
		 (self fileOf: each) = (self fileOf: from) ]) ifTrue: [
		^ from first: 1 ].
	(others noneSatisfy: [ :each |
		 (self rankOf: each) = (self rankOf: from) ]) ifTrue: [
		^ from last asString ].
	^ from
]

{ #category : 'accessing' }
ChessPosition >> enPassantTarget [

	^ enPassantTarget
]

{ #category : 'private - moving' }
ChessPosition >> endTurn [

	turn = #black ifTrue: [ fullMoveNumber := fullMoveNumber + 1 ].
	turn := self opposite: turn
]

{ #category : 'accessing' }
ChessPosition >> fen [

	| stream |
	stream := WriteStream on: String new.
	8 to: 1 by: -1 do: [ :rank |
			| empty |
			empty := 0.
			1 to: 8 do: [ :file |
					(self pieceAt: (self squareAtFile: file rank: rank))
						ifNil: [ empty := empty + 1 ]
						ifNotNil: [ :piece |
								empty > 0 ifTrue: [
										stream print: empty.
										empty := 0 ].
								stream nextPutAll: piece ] ].
			empty > 0 ifTrue: [ stream print: empty ].
			rank > 1 ifTrue: [ stream nextPut: $/ ] ].
	stream
		space;
		nextPut: (turn = #white
				 ifTrue: [ $w ]
				 ifFalse: [ $b ]);
		space;
		nextPutAll: self castlingFEN;
		space;
		nextPutAll: (enPassantTarget ifNil: [ '-' ]);
		space;
		print: halfMoveClock;
		space;
		print: fullMoveNumber.
	^ stream contents
]

{ #category : 'private - squares' }
ChessPosition >> fileOf: square [

	^ square first asInteger - 96
]

{ #category : 'accessing' }
ChessPosition >> fullmoveNumber [

	^ fullMoveNumber
]

{ #category : 'accessing' }
ChessPosition >> halfmoveClock [

	^ halfMoveClock
]

{ #category : 'testing' }
ChessPosition >> hasLegalMove [
	"Whether the side to move has any legal move (false on checkmate and stalemate)"

	| squares |
	squares := (1 to: 8) flatCollect: [ :file |
		           (1 to: 8) collect: [ :rank |
			           self squareAtFile: file rank: rank ] ].
	^ pieces keys anySatisfy: [ :from |
			  (self colorOf: (pieces at: from)) = turn and: [
				  squares anySatisfy: [ :to | self isLegalUCI: from , to ] ] ]
]

{ #category : 'initialization' }
ChessPosition >> initialize [

	super initialize.
	pieces := Dictionary new.
	turn := #white.
	castlingWhiteKingSide := false.
	castlingWhiteQueenSide := false.
	castlingBlackKingSide := false.
	castlingBlackQueenSide := false.
	enPassantTarget := nil.
	halfMoveClock := 0.
	fullMoveNumber := 1
]

{ #category : 'testing' }
ChessPosition >> isKingInCheck: aColor [

	| king |
	king := self pieceLetter: 'K' color: aColor.
	^ pieces keys anySatisfy: [ :square |
			  (pieces at: square) = king and: [
				  self isSquare: square attackedBy: (self opposite: aColor) ] ]
]

{ #category : 'testing' }
ChessPosition >> isLegalUCI: aString [
	"Whether the side to move may play aString (UCI) here. Castling only checks the right and empty squares between king and rook."

	| from to piece letter |
	(aString size between: 4 and: 5) ifFalse: [ ^ false ].
	from := aString first: 2.
	to := aString copyFrom: 3 to: 4.
	((self isSquare: from) and: [ self isSquare: to ]) ifFalse: [
		^ false ].
	piece := self pieceAt: from.
	(piece notNil and: [ (self colorOf: piece) = turn ]) ifFalse: [
		^ false ].
	letter := piece asUppercase.
	(letter = 'K' and: [
		 ((self fileOf: from) - (self fileOf: to)) abs = 2 ]) ifTrue: [
		^ self canCastleTo: to ].
	^ (self canMove: letter from: from to: to) and: [
		  (self moveLeavesKingInCheckFrom: from to: to) not ]
]

{ #category : 'private - moving' }
ChessPosition >> isPathClearFrom: from to: to [

	| df dr steps file rank |
	df := (self fileOf: to) - (self fileOf: from).
	dr := (self rankOf: to) - (self rankOf: from).
	steps := df abs max: dr abs.
	file := self fileOf: from.
	rank := self rankOf: from.
	1 to: steps - 1 do: [ :i |
			(self pieceAt:
				 (self
					  squareAtFile: file + (df sign * i)
					  rank: rank + (dr sign * i))) ifNotNil: [ ^ false ] ].
	^ true
]

{ #category : 'private - squares' }
ChessPosition >> isSquare: aString [

	^ aString size = 2 and: [
			  ((self fileOf: aString) between: 1 and: 8) and: [
					  aString second isDigit and: [
						  (self rankOf: aString) between: 1 and: 8 ] ] ]
]

{ #category : 'testing' }
ChessPosition >> isSquare: aSquare attackedBy: aColor [

	^ pieces keys anySatisfy: [ :from |
			  | piece letter |
			  piece := pieces at: from.
			  letter := piece asUppercase.
			  (self colorOf: piece) = aColor and: [
					  letter = 'P'
						  ifTrue: [ self pawnOf: aColor on: from attacks: aSquare ]
						  ifFalse: [ self canPiece: letter from: from attack: aSquare ] ] ]
]

{ #category : 'accessing' }
ChessPosition >> lastMoveUCI [
	"The move that produced this position, in UCI notation (e2e4, e1g1, e7e8q); nil for a starting position"

	^ lastMoveUCI
]

{ #category : 'moving' }
ChessPosition >> move: aSAN [

	^ self moves: { aSAN }
]

{ #category : 'private - moving' }
ChessPosition >> moveLeavesKingInCheckFrom: from to: to [

	| trial |
	trial := self copy.
	trial movePieceFrom: from to: to promotion: nil.
	^ trial isKingInCheck: turn
]

{ #category : 'private - moving' }
ChessPosition >> movePieceFrom: from to: to promotion: aLetterOrNil [

	| piece letter captured |
	piece := pieces at: from.
	letter := piece asUppercase.
	captured := pieces at: to ifAbsent: [ nil ].
	(letter = 'P' and: [ to = enPassantTarget ]) ifTrue: [
			captured := pieces removeKey:
				            (self
					             squareAtFile: (self fileOf: to)
					             rank: (self rankOf: from)) ].
	pieces removeKey: from.
	pieces at: to put: (aLetterOrNil
			 ifNil: [ piece ]
			 ifNotNil: [ self pieceLetter: aLetterOrNil color: turn ]).
	self updateCastlingRightsFrom: from to: to.
	enPassantTarget := (letter = 'P' and: [
		                    ((self rankOf: to) - (self rankOf: from)) abs
		                    = 2 ])
		                   ifTrue: [
				                   self
					                   squareAtFile: (self fileOf: from)
					                   rank:
					                   (self rankOf: from) + (self rankOf: to) / 2 ]
		                   ifFalse: [ nil ].
	halfMoveClock := (letter = 'P' or: [ captured notNil ])
		                 ifTrue: [ 0 ]
		                 ifFalse: [ halfMoveClock + 1 ].
	lastMoveUCI := from , to
	               ,
	               (aLetterOrNil
		                ifNil: [ '' ]
		                ifNotNil: [ aLetterOrNil asLowercase ]).
	self endTurn
]

{ #category : 'moving' }
ChessPosition >> moves: aCollectionOfSAN [
	"Answer the position reached by playing aCollectionOfSAN from the receiver. The receiver is not modified; all moves are applied to a single copy"

	| result |
	result := self copy.
	aCollectionOfSAN do: [ :san | result applySAN: san ].
	^ result
]

{ #category : 'private - pieces' }
ChessPosition >> opposite: aColor [

	^ aColor = #white
		  ifTrue: [ #black ]
		  ifFalse: [ #white ]
]

{ #category : 'private - moving' }
ChessPosition >> originOf: aLetter to: target hint: hint san: aSAN [
	"Answer the only square from which a piece of type aLetter of the side to move can reach target. SAN omits disambiguation when the other candidate is pinned, so pinned pieces are discarded when there is more than one candidate"

	| piece candidates |
	piece := self pieceLetter: aLetter color: turn.
	candidates := pieces keys select: [ :square |
			              (pieces at: square) = piece and: [
					              (self square: square matchesHint: hint) and: [
						              self canMove: aLetter from: square to: target ] ] ].
	candidates size > 1 ifTrue: [
			candidates := candidates reject: [ :square |
				              self moveLeavesKingInCheckFrom: square to: target ] ].
	candidates size = 1 ifFalse: [
		ChessIllegalMove signalSAN: aSAN position: self ].
	^ candidates first
]

{ #category : 'private' }
ChessPosition >> parseFEN: aString [

	| parts ranks idx filesCount |
	parts := aString trim substrings: ' '.
	pieces := Dictionary new.
	ranks := (parts at: 1 ifAbsent: [ '' ]) substrings: '/'.
	idx := 0.
	ranks do: [ :r |
			filesCount := 0.
			r do: [ :c |
					c isDigit
						ifTrue: [ filesCount := filesCount + c digitValue ]
						ifFalse: [
								pieces
									at: (self squareAtFile: filesCount + 1 rank: 8 - idx)
									put: c asString.
								filesCount := filesCount + 1 ] ].
			idx := idx + 1 ].
	parts size > 1 ifTrue: [
			turn := (parts at: 2) = 'w'
				        ifTrue: [ #white ]
				        ifFalse: [ #black ] ].
	parts size > 2 ifTrue: [
			| castling |
			castling := parts at: 3.
			castlingWhiteKingSide := castling includesSubstring: 'K'.
			castlingWhiteQueenSide := castling includesSubstring: 'Q'.
			castlingBlackKingSide := castling includesSubstring: 'k'.
			castlingBlackQueenSide := castling includesSubstring: 'q' ].
	parts size > 3 ifTrue: [
			enPassantTarget := (parts at: 4) = '-'
				                   ifTrue: [ nil ]
				                   ifFalse: [ parts at: 4 ] ].
	parts size > 4 ifTrue: [ halfMoveClock := (parts at: 5) asInteger ].
	parts size > 5 ifTrue: [ fullMoveNumber := (parts at: 6) asInteger ]
]

{ #category : 'private - moving' }
ChessPosition >> pawnOf: aColor on: from attacks: aSquare [

	^ ((self fileOf: aSquare) - (self fileOf: from)) abs = 1 and: [
			  (self rankOf: aSquare) - (self rankOf: from) = (aColor = #white
				   ifTrue: [ 1 ]
				   ifFalse: [ -1 ]) ]
]

{ #category : 'accessing' }
ChessPosition >> pieceAt: square [

	^ pieces at: square ifAbsent: [ nil ]
]

{ #category : 'private - pieces' }
ChessPosition >> pieceLetter: aLetter color: aColor [

	^ aColor = #white
		  ifTrue: [ aLetter asUppercase ]
		  ifFalse: [ aLetter asLowercase ]
]

{ #category : 'accessing' }
ChessPosition >> pieces [
	"Answer a copy of the square -> piece letter mapping, e.g. 'e4' -> 'P'"

	^ pieces copy
]

{ #category : 'copying' }
ChessPosition >> postCopy [

	super postCopy.
	pieces := pieces copy
]

{ #category : 'private - squares' }
ChessPosition >> rankOf: square [

	^ square second digitValue
]

{ #category : 'converting' }
ChessPosition >> sanForUCI: aString [
	"The SAN of the legal UCI move aString in this position, with + or # when it checks or mates"

	| from to letter target capture san after |
	(self isLegalUCI: aString) ifFalse: [
		^ Error signal: 'Illegal move ' , aString ].
	from := aString first: 2.
	to := aString copyFrom: 3 to: 4.
	letter := (self pieceAt: from) asUppercase.
	target := self pieceAt: to.
	(letter = 'K' and: [
		 ((self fileOf: from) - (self fileOf: to)) abs = 2 ])
		ifTrue: [
				san := (self fileOf: to) = 7
					       ifTrue: [ 'O-O' ]
					       ifFalse: [ 'O-O-O' ] ]
		ifFalse: [
				letter = 'P'
					ifTrue: [
							capture := (self fileOf: from) ~= (self fileOf: to).
							san := (capture
								        ifTrue: [ (from first: 1) , 'x' ]
								        ifFalse: [ '' ]) , to.
							((self rankOf: to) = 1 or: [ (self rankOf: to) = 8 ]) ifTrue: [
									san := san , '=' , (aString size = 5
										        ifTrue: [ aString last asUppercase asString ]
										        ifFalse: [ 'Q' ]) ] ]
					ifFalse: [
							san := letter
							       , (self disambiguationFor: letter from: from to: to)
							       , (target ifNil: [ '' ] ifNotNil: [ 'x' ]) , to ] ].
	after := self move: san.
	(after isKingInCheck: after turn) ifFalse: [ ^ san ].
	^ san , (after hasLegalMove
		   ifTrue: [ '+' ]
		   ifFalse: [ '#' ])
]

{ #category : 'private - moving' }
ChessPosition >> square: aSquare matchesHint: aHint [

	^ aHint allSatisfy: [ :c |
			  c isDigit
				  ifTrue: [ (self rankOf: aSquare) = c digitValue ]
				  ifFalse: [ (self fileOf: aSquare) = (c asInteger - 96) ] ]
]

{ #category : 'private - squares' }
ChessPosition >> squareAtFile: file rank: rank [

	^ (Character value: 96 + file) asString , rank printString
]

{ #category : 'accessing' }
ChessPosition >> turn [

	^ turn
]

{ #category : 'private - moving' }
ChessPosition >> updateCastlingRightsFrom: from to: to [

	(#( 'e1' 'h1' ) includes: from) | (to = 'h1') ifTrue: [
		castlingWhiteKingSide := false ].
	(#( 'e1' 'a1' ) includes: from) | (to = 'a1') ifTrue: [
		castlingWhiteQueenSide := false ].
	(#( 'e8' 'h8' ) includes: from) | (to = 'h8') ifTrue: [
		castlingBlackKingSide := false ].
	(#( 'e8' 'a8' ) includes: from) | (to = 'a8') ifTrue: [
		castlingBlackQueenSide := false ]
]
