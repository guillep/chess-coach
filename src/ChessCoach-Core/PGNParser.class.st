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
PGNParser >> braceDeltaFor: ch [

	ch = ${ ifTrue: [ ^ 1 ].
	ch = $} ifTrue: [ ^ -1 ].
	^ 0
]

{ #category : 'parsing' }
PGNParser >> parenDeltaFor: ch [

	ch = $( ifTrue: [ ^ 1 ].
	ch = $) ifTrue: [ ^ -1 ].
	^ 0
]

{ #category : 'parsing' }
PGNParser >> parse: aStringOrStream [

	| input pgnGame lines headerDone movesText |
	input := aStringOrStream isStream
		         ifTrue: [ aStringOrStream upToEnd ]
		         ifFalse: [ aStringOrStream asString ].
	pgnGame := PGNGame new.
	lines := input lines.
	headerDone := false.
	movesText := String new writeStream.
	lines do: [ :line |
			| trimmed |
			trimmed := line trimBoth.
			headerDone
				ifFalse: [
						(trimmed notEmpty and: [ trimmed first = $[ ])
							ifTrue: [ self parseHeaderLine: trimmed into: pgnGame ]
							ifFalse: [
									headerDone := true.
									movesText nextPutAll: line ] ]
				ifTrue: [
						movesText
							nextPutAll: String lf;
							nextPutAll: line ] ].
	self
		tokenizeText: (self stripAnnotations: movesText contents)
		into: pgnGame.
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
PGNParser >> skipNagIn: aString from: anIndex [

	| j |
	j := anIndex.
	[ j + 1 <= aString size and: [ (aString at: j + 1) isDigit ] ]
		whileTrue: [ j := j + 1 ].
	^ j
]

{ #category : 'parsing' }
PGNParser >> skipToLineEndIn: aString from: anIndex [

	| j |
	j := anIndex.
	[ j <= aString size and: [ (aString at: j) ~= Character lf ] ]
		whileTrue: [ j := j + 1 ].
	^ j
]

{ #category : 'parsing' }
PGNParser >> stripAnnotations: aString [

	| out braceDepth parenDepth i |
	out := String new writeStream.
	braceDepth := 0.
	parenDepth := 0.
	i := 1.
	[ i <= aString size ] whileTrue: [
			| ch isStart |
			ch := aString at: i.
			braceDepth > 0
				ifTrue: [ braceDepth := braceDepth + (self braceDeltaFor: ch) ]
				ifFalse: [
						parenDepth > 0
							ifTrue: [ parenDepth := parenDepth + (self parenDeltaFor: ch) ]
							ifFalse: [
									ch = ${ ifTrue: [ braceDepth := 1 ].
									ch = $( ifTrue: [ parenDepth := 1 ].
									ch = $; ifTrue: [ i := self skipToLineEndIn: aString from: i ].
									ch = $$ ifTrue: [ i := self skipNagIn: aString from: i ].
									isStart := ch = ${ or: [
										           ch = $( or: [ ch = $; or: [ ch = $$ ] ] ].
									isStart ifFalse: [ out nextPut: ch ] ] ].
			i := i + 1 ].
	^ out contents
]

{ #category : 'parsing' }
PGNParser >> tokenizeText: text into: pgnGame [

	| moveNum seenW seenB |
	moveNum := 0.
	seenW := false.
	seenB := false.
	text lines do: [ :line |
			| tokens |
			tokens := line substrings.
			tokens do: [ :t |
					| token r |
					token := t asString trimBoth.
					token isEmpty ifFalse: [
							r := self
								     tokenizeToken: token
								     into: pgnGame
								     moveNumber: moveNum
								     seenWhite: seenW
								     seenBlack: seenB.
							moveNum := r first.
							seenW := r second.
							seenB := r third ] ] ]
]

{ #category : 'parsing' }
PGNParser >> tokenizeToken: token into: pgnGame moveNumber: moveNum seenWhite: seenWhite seenBlack: seenBlack [

	| isResult numStr isBlackMove num w b |
	w := seenWhite.
	b := seenBlack.
	isResult := token = '1-0' or: [
		            token = '0-1' or: [
			            token = '1/2-1/2' or: [ token = '*' ] ] ].
	isResult ifTrue: [
			(pgnGame metadata includesKey: 'Result') ifFalse: [
				pgnGame metadata at: 'Result' put: token ].
			^ {
				  moveNum.
				  w.
				  b } ].
	(token includes: $.) ifTrue: [
			numStr := token copyUpTo: $..
			(numStr notEmpty and: [ numStr allSatisfy: [ :c | c isDigit ] ])
				ifTrue: [
						num := numStr asNumber.
						isBlackMove := token includesSubstring: '...'.
						^ {
							  num.
							  isBlackMove.
							  false } ] ].
	num := moveNum = 0
		       ifTrue: [ 1 ]
		       ifFalse: [ moveNum ].
	(w and: [ b ]) ifTrue: [
			num := num + 1.
			w := false.
			b := false ].
	w
		ifTrue: [
				pgnGame moves add: (ChessMove new
						 moveNumber: num
						 color: 'b'
						 san: token
						 uci: token
						 timestamp: nil).
				b := true ]
		ifFalse: [
				pgnGame moves add: (ChessMove new
						 moveNumber: num
						 color: 'w'
						 san: token
						 uci: token
						 timestamp: nil).
				w := true ].
	^ {
		  num.
		  w.
		  b }
]
