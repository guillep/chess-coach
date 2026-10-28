"
I drive a Stockfish process through UCI, started lazily on the first analysis.
	(StockfishEngine default analyse: aFEN multiPV: 3 depth: 18) answers EngineLines, best first.
Send #stop when done to quit the process.
"
Class {
	#name : 'StockfishEngine',
	#superclass : 'Object',
	#instVars : [
		'path',
		'process',
		'pending'
	],
	#category : 'ChessCoach-Engine',
	#package : 'ChessCoach-Engine'
}

{ #category : 'instance creation' }
StockfishEngine class >> default [
	"Stockfish as installed by `brew install stockfish` on Apple Silicon"

	^ self path: '/opt/homebrew/bin/stockfish' asFileReference
]

{ #category : 'instance creation' }
StockfishEngine class >> path: aFileReference [

	^ self new
		  setPath: aFileReference;
		  yourself
]

{ #category : 'analysing' }
StockfishEngine >> analyse: aFEN multiPV: lineCount depth: aDepth [
	"Answer up to lineCount EngineLines for the position, best first."

	^ self
		  analyse: aFEN
		  multiPV: lineCount
		  depth: aDepth
		  searchMoves: #(  )
]

{ #category : 'analysing' }
StockfishEngine >> analyse: aFEN multiPV: lineCount depth: aDepth searchMoves: someUCIMoves [
	"Answer up to lineCount EngineLines for the position, best first, considering only someUCIMoves (all moves when empty).
	A checkmated or stalemated position gets a single line without moves."

	| sideToMove linesByRank |
	self ensureStarted.
	sideToMove := (aFEN substrings at: 2) = 'w'
		              ifTrue: [ #white ]
		              ifFalse: [ #black ].
	self send: 'setoption name MultiPV value ' , lineCount printString.
	self send: 'position fen ' , aFEN.
	self send: 'go depth ' , aDepth printString , (someUCIMoves
			 ifEmpty: [ '' ]
			 ifNotEmpty: [ ' searchmoves ' , (' ' join: someUCIMoves) ]).
	linesByRank := Dictionary new.
	(self readLinesUntil: 'bestmove') do: [ :line |
		self parseInfo: line sideToMove: sideToMove into: linesByRank ].
	^ (linesByRank keys asSortedCollection collect: [ :rank |
		   linesByRank at: rank ]) asArray
]

{ #category : 'running' }
StockfishEngine >> ensureStarted [

	(process notNil and: [ process isRunning ]) ifTrue: [ ^ self ].
	path exists ifFalse: [
			^ self error: 'Stockfish not found at ' , path fullName
				  , '. Install it with: brew install stockfish' ].
	process := OSSUnixSubprocess new
		           command: path fullName;
		           redirectStdin;
		           redirectStdout;
		           yourself.
	process run.
	pending := ''.
	self send: 'uci'.
	self readLinesUntil: 'uciok'
]

{ #category : 'private - io' }
StockfishEngine >> nextLine [
	"OSSubprocess pipes are non-blocking, so poll stdout until a whole line has arrived"

	| chunk line |
	[ pending includes: Character lf ] whileFalse: [
			chunk := process stdoutStream upToEnd.
			chunk isEmpty
				ifTrue: [
						process isRunning ifFalse: [
							^ self error: 'Stockfish exited unexpectedly' ].
						(Delay forMilliseconds: 5) wait ]
				ifFalse: [ pending := pending , chunk ] ].
	line := pending copyUpTo: Character lf.
	pending := pending copyAfter: Character lf.
	^ line
]

{ #category : 'private - parsing' }
StockfishEngine >> parseInfo: aString sideToMove: aColor into: linesByRank [
	"Keep the latest scored line for each multipv rank.
	Example: info depth 18 seldepth 25 multipv 2 score cp -31 nodes 1 pv e7e5 g1f3"

	| tokens rank scoreIndex scoreKind scoreValue pvIndex moves |
	tokens := aString substrings.
	(tokens notEmpty and: [ tokens first = 'info' ]) ifFalse: [ ^ self ].
	scoreIndex := tokens indexOf: 'score'.
	scoreIndex = 0 ifTrue: [ ^ self ].
	scoreKind := tokens at: scoreIndex + 1.
	scoreValue := (tokens at: scoreIndex + 2) asInteger.
	rank := (tokens indexOf: 'multipv') in: [ :index |
			        index = 0
				        ifTrue: [ 1 ]
				        ifFalse: [ (tokens at: index + 1) asInteger ] ].
	pvIndex := tokens indexOf: 'pv'.
	moves := pvIndex = 0
		         ifTrue: [ #(  ) ]
		         ifFalse: [ tokens allButFirst: pvIndex ].
	linesByRank at: rank put: (scoreKind = 'mate'
			 ifTrue: [
			 EngineLine moves: moves mate: scoreValue sideToMove: aColor ]
			 ifFalse: [
			 EngineLine moves: moves centipawns: scoreValue sideToMove: aColor ])
]

{ #category : 'private - io' }
StockfishEngine >> readLinesUntil: aPrefix [
	"Answer Stockfish's output lines up to and including the first one starting with aPrefix"

	| lines line |
	lines := OrderedCollection new.
	[
		line := self nextLine.
		lines add: line.
		line beginsWith: aPrefix ] whileFalse.
	^ lines
]

{ #category : 'private - io' }
StockfishEngine >> send: aString [

	process stdinStream
		nextPutAll: aString;
		nextPut: Character lf;
		flush
]

{ #category : 'initialization' }
StockfishEngine >> setPath: aFileReference [

	path := aFileReference
]

{ #category : 'running' }
StockfishEngine >> stop [
	"Quit the Stockfish process; the next analysis starts a new one"

	process ifNil: [ ^ self ].
	process isRunning ifTrue: [ self send: 'quit' ].
	process
		waitForExit;
		closeAndCleanStreams.
	process := nil
]
