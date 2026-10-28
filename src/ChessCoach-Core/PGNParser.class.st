"
Parses PGN (Portable Game Notation) text into a PGNGame. Extracts header tags into the game's metadata dictionary (including Result) and converts move notation into ChessMove objects. Ignores comments, variations, NAGs, and line comments. Does not interpret moves on a board.
"
Class {
	#name : 'PGNParser',
	#superclass : 'Object',
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'parsing' }
PGNParser >> addMove: aToken number: aMoveNumber color: aColor to: aGame [
	"Add the move, turning trailing !/? suffixes into NAGs"

	| san suffix move |
	san := aToken copyWithoutAll: '!?'.
	suffix := aToken copyFrom: san size + 1 to: aToken size.
	move := ChessMove new
		        moveNumber: aMoveNumber
		        color: aColor
		        san: san
		        timestamp: nil.
	(self nagForSuffix: suffix) ifNotNil: [ :nag | move addNag: nag ].
	aGame moves add: move.
	^ move
]

{ #category : 'parsing' }
PGNParser >> comment: aString to: aChessMoveOrNil [
	"Attach a comment to the preceding move: [%clk h:mm:ss] sets its clock, other [%...] commands are dropped, the rest is its text. Comments before the first move are ignored."

	| text |
	aChessMoveOrNil ifNil: [ ^ self ].
	text := String new writeStream.
	(aString splitOn: $[) withIndexDo: [ :part :index |
			index = 1
				ifTrue: [ text nextPutAll: part ]
				ifFalse: [
						| command |
						command := part copyUpTo: $].
						(command beginsWith: '%clk ') ifTrue: [
								aChessMoveOrNil timestamp:
									(self durationFrom: (command allButFirst: 5) trimBoth) ].
						(command beginsWith: '%') ifFalse: [
								text
									nextPut: $[;
									nextPutAll: command;
									nextPut: $] ].
						text nextPutAll: (part copyAfter: $]) ] ].
	aChessMoveOrNil addComment: (text contents substrings joinUsing: ' ')
]

{ #category : 'parsing' }
PGNParser >> digitsIn: aStream [

	^ String streamContents: [ :out |
			  [ aStream atEnd not and: [ aStream peek isDigit ] ] whileTrue: [
				  out nextPut: aStream next ] ]
]

{ #category : 'parsing' }
PGNParser >> durationFrom: aClockString [
	"h:mm:ss or h:mm:ss.f as in [%clk 0:02:59.4]"

	| parts seconds |
	parts := aClockString substrings: ':'.
	seconds := parts
		           inject: 0
		           into: [ :total :each | total * 60 + each asNumber ].
	^ Duration milliSeconds: (seconds * 1000) rounded
]

{ #category : 'parsing' }
PGNParser >> isResult: aToken [

	^ #( '1-0' '0-1' '1/2-1/2' '*' ) includes: aToken
]

{ #category : 'parsing' }
PGNParser >> nagForSuffix: aString [
	"The standard NAG of a move suffix, or nil when there is none"

	^ #( '!' '?' '!!' '??' '!?' '?!' ) indexOf: aString ifAbsent: [ nil ]
]

{ #category : 'parsing' }
PGNParser >> parse: aStringOrStream [

	| input pgnGame headerDone movesText |
	input := aStringOrStream isStream
		         ifTrue: [ aStringOrStream upToEnd ]
		         ifFalse: [ aStringOrStream asString ].
	pgnGame := Game new.
	headerDone := false.
	movesText := String new writeStream.
	input lines do: [ :line |
			| trimmed |
			trimmed := line trimBoth.
			(headerDone not and: [
				 trimmed notEmpty and: [ trimmed first = $[ ] ])
				ifTrue: [ self parseHeaderLine: trimmed into: pgnGame ]
				ifFalse: [
						trimmed ifNotEmpty: [ headerDone := true ].
						movesText
							nextPutAll: line;
							nextPut: Character lf ] ].
	self parseMoveText: movesText contents into: pgnGame.
	^ pgnGame
]

{ #category : 'parsing' }
PGNParser >> parseHeaderLine: trimmed into: pgnGame [

	| key startQuote endQuote spaceIdx |
	startQuote := trimmed indexOf: $".
	endQuote := trimmed lastIndexOf: $".
	spaceIdx := trimmed indexOf: Character space.
	(startQuote > 0 and: [ endQuote > startQuote and: [ spaceIdx > 0 ] ])
		ifTrue: [
				key := (trimmed copyFrom: 2 to: spaceIdx - 1) trimBoth.
				pgnGame metadata
					at: key
					put: (trimmed copyFrom: startQuote + 1 to: endQuote - 1) ]
]

{ #category : 'parsing' }
PGNParser >> parseMoveText: aString into: aGame [
	"One pass over the movetext. Comments ({...} and ; to end of line), [%clk] clocks and NAGs ($n, !, ?) go to the move before them; variations (...) are skipped."

	| stream moveNumber color last |
	stream := ReadStream on: aString.
	moveNumber := 1.
	color := 'w'.
	last := nil.
	[ stream atEnd ] whileFalse: [
			| ch |
			ch := stream peek.
			ch isSeparator
				ifTrue: [ stream next ]
				ifFalse: [
						ch = ${
							ifTrue: [
									stream next.
									self comment: (stream upTo: $}) to: last ]
							ifFalse: [
									ch = $;
										ifTrue: [
												stream next.
												self comment: (stream upTo: Character lf) to: last ]
										ifFalse: [
												ch = $(
													ifTrue: [ self skipVariationIn: stream ]
													ifFalse: [
															ch = $$
																ifTrue: [
																		stream next.
																		last ifNotNil: [
																			last addNag: (self digitsIn: stream) asInteger ] ]
																ifFalse: [
																		| token |
																		token := self tokenIn: stream.
																		(self isResult: token)
																			ifTrue: [
																					(aGame metadata includesKey: 'Result') ifFalse: [
																						aGame metadata at: 'Result' put: token ] ]
																			ifFalse: [
																					| san |
																					san := token.
																					(token notEmpty and: [ token first isDigit ])
																						ifTrue: [
																								moveNumber := (token copyUpTo: $.) asInteger
																									              ifNil: [ moveNumber ].
																								(token includes: $.) ifTrue: [
																										color := (token includesSubstring: '...')
																											         ifTrue: [ 'b' ]
																											         ifFalse: [ 'w' ] ].
																								san := token copyWithoutAll: '0123456789.'.
																								(token beginsWith: 'O-O') ifTrue: [
																									san := token ] ].
																					san ifNotEmpty: [
																							last := self
																								        addMove: san
																								        number: moveNumber
																								        color: color
																								        to: aGame.
																							color = 'b' ifTrue: [
																								moveNumber := moveNumber + 1 ].
																							color := color = 'w'
																								         ifTrue: [ 'b' ]
																								         ifFalse: [ 'w' ] ] ] ] ] ] ] ] ]
]

{ #category : 'parsing' }
PGNParser >> skipVariationIn: aStream [
	"Skip a (possibly nested) variation, including the comments inside it"

	| depth |
	depth := 0.
	[ aStream atEnd ] whileFalse: [
			| ch |
			ch := aStream next.
			ch = ${ ifTrue: [ aStream upTo: $} ].
			ch = $( ifTrue: [ depth := depth + 1 ].
			ch = $) ifTrue: [
					depth := depth - 1.
					depth = 0 ifTrue: [ ^ self ] ] ]
]

{ #category : 'parsing' }
PGNParser >> tokenIn: aStream [
	"A move, move number or result: up to a separator or the start of a comment, variation or NAG"

	^ String streamContents: [ :out |
			  [
				  aStream atEnd or: [
					  aStream peek isSeparator or: [ '{(;$)' includes: aStream peek ] ] ]
				  whileFalse: [ out nextPut: aStream next ].
			  (out contents isEmpty and: [ aStream atEnd not ]) ifTrue: [
				  aStream next ] ]
]
