Class {
	#name : 'ChessComImportTest',
	#superclass : 'TestCase',
	#instVars : [
		'session',
		'api'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
ChessComImportTest >> game: anId white: aWhite black: aBlack winner: aColorOrNil timeControl: aTimeControl endTime: seconds rules: aRules [

	| result |
	result := [ :color |
		          aColorOrNil = color
			          ifTrue: [ 'win' ]
			          ifFalse: [
			          aColorOrNil ifNil: [ 'agreed' ] ifNotNil: [ 'resigned' ] ] ].
	^ Dictionary new
		  at: 'url' put: 'https://www.chess.com/game/live/' , anId;
		  at: 'pgn' put: ('[Event "Live Chess"]
[White "{1}"]
[Black "{2}"]
[TimeControl "{3}"]
[UTCDate "2026.10.01"]

1. e4 \{[%clk 0:02:59.9]\} 1... e5 \{[%clk 0:02:58]\} *' format: {
						   aWhite.
						   aBlack.
						   aTimeControl });
		  at: 'time_control' put: aTimeControl;
		  at: 'end_time' put: seconds;
		  at: 'rules' put: aRules;
		  at: 'white' put: (Dictionary new
				   at: 'username' put: aWhite;
				   at: 'result' put: (result value: #white);
				   yourself);
		  at: 'black' put: (Dictionary new
			   at: 'username' put: aBlack;
			   at: 'result' put: (result value: #black);
			   yourself);
		  yourself
]

{ #category : 'running' }
ChessComImportTest >> setUp [

	| base |
	super setUp.
	session := (LichessAPIClientStub withGames: 0) newSessionOn:
		           FileSystem memory root.
	session settings at: 'gamesPerLoad' put: 2.
	api := ChessComAPIClientStub new.
	base := 'https://api.chess.com/pub/player/bob/games/'.
	api at: base , 'archives' answer: (Dictionary new
			 at: 'archives' put: {
					 (base , '2026/09').
					 (base , '2026/10') };
			 yourself).
	api at: base , '2026/10' answer: (Dictionary new
			 at: 'games' put: {
					 (self
						  game: '101'
						  white: 'Bob'
						  black: 'carol'
						  winner: #white
						  timeControl: '180+2'
						  endTime: 1790000000
						  rules: 'chess').
					 (self
						  game: '102'
						  white: 'dave'
						  black: 'Bob'
						  winner: nil
						  timeControl: '600'
						  endTime: 1790100000
						  rules: 'chess').
					 (self
						  game: '103'
						  white: 'Bob'
						  black: 'erin'
						  winner: #black
						  timeControl: '180'
						  endTime: 1790200000
						  rules: 'chess960') };
			 yourself).
	api at: base , '2026/09' answer: (Dictionary new
			 at: 'games' put: { (self
					  game: '90'
					  white: 'fay'
					  black: 'Bob'
					  winner: #black
					  timeControl: '1/259200'
					  endTime: 1788000000
					  rules: 'chess') };
			 yourself).
	session chessComAPIClient: api.
	session chessComUsername: 'Bob'
]

{ #category : 'tests' }
ChessComImportTest >> testAppFiltersTheListBySpeed [

	| app scripter ids |
	session
		loadMoreGames;
		loadMoreGames.
	app := ChessCoachAppElement new
		       backgroundRunner: [ :work | work value ];
		       session: session;
		       yourself.
	scripter := BlDevScripter new.
	scripter element: app.
	scripter space extent: 1200 @ 700.
	scripter pulse.
	ids := [
	       app gameList dataAccessor asArray collect: [ :each |
		       each gameId ] ].
	self assert: ids value size equals: 3.
	scripter testClick onChildFromBlock: [ :root |
		app speedButtonFor: 'blitz' ].
	scripter
		syncContinue;
		pulse.
	self assert: ids value equals: #( 'chesscom-101' ).
	scripter testClick onChildFromBlock: [ :root |
		app speedButtonFor: nil ].
	scripter
		syncContinue;
		pulse.
	self assert: ids value size equals: 3
]

{ #category : 'tests' }
ChessComImportTest >> testFilterBySpeed [

	session
		loadMoreGames;
		loadMoreGames.
	self
		assert:
			((session gamesWithSpeed: 'blitz') collect: [ :each | each gameId ])
				asArray
		equals: #( 'chesscom-101' ).
	self
		assert:
			((session gamesWithSpeed: 'correspondence') collect: [ :each |
				 each gameId ]) asArray
		equals: #( 'chesscom-90' ).
	self assert: (session gamesWithSpeed: 'bullet') isEmpty.
	self assert: (session gamesWithSpeed: nil) size equals: 3
]

{ #category : 'tests' }
ChessComImportTest >> testImportsMonthByMonthNewestFirst [

	| games |
	self assert: session canImport.
	session loadMoreGames.
	games := session games.
	self
		assert: (games collect: [ :each | each gameId ]) asArray
		equals: #( 'chesscom-102' 'chesscom-101' ).
	self assert: games first source equals: 'chess.com'.
	self assert: games first result equals: '1/2-1/2'.
	self assert: games second result equals: '1-0'.
	self
		assert: (games collect: [ :each | each speed ]) asArray
		equals: #( 'rapid' 'blitz' ).
	self assert: games first players asArray equals: #( 'dave' 'Bob' ).
	self
		assert: (session gameFor: games second) moves first timestamp
		equals: (Duration milliSeconds: 179900).
	session loadMoreGames.
	self assert: session games last gameId equals: 'chesscom-90'.
	self assert: session games last speed equals: 'correspondence'.
	self assert: session games last result equals: '0-1'.
	session loadMoreGames.
	self assert: session games size equals: 3
]

{ #category : 'tests' }
ChessComImportTest >> testRefreshWalksBackUntilAKnownGame [

	| base |
	session loadMoreGames.
	session loadMoreGames.
	self assert: session games size equals: 3.
	base := 'https://api.chess.com/pub/player/bob/games/'.
	api at: base , 'archives' answer: (Dictionary new
			 at: 'archives' put: {
					 (base , '2026/09').
					 (base , '2026/10').
					 (base , '2026/11').
					 (base , '2026/12') };
			 yourself).
	api at: base , '2026/12' answer: (Dictionary new
			 at: 'games' put: { (self
					  game: '121'
					  white: 'Bob'
					  black: 'gus'
					  winner: #white
					  timeControl: '600'
					  endTime: 1796000000
					  rules: 'chess') };
			 yourself).
	api at: base , '2026/11' answer: (Dictionary new
			 at: 'games' put: { (self
					  game: '111'
					  white: 'hal'
					  black: 'Bob'
					  winner: #white
					  timeControl: '600'
					  endTime: 1793000000
					  rules: 'chess') };
			 yourself).
	session refresh.
	self assert: session games size equals: 5.
	self assert: session games first gameId equals: 'chesscom-121'.
	self
		assert: (api requests count: [ :url | url endsWith: '2026/09' ])
		equals: 1
]

{ #category : 'tests' }
ChessComImportTest >> testUsernameDecidesMyColorsAndIsRemembered [

	session loadMoreGames.
	self
		assert:
		(session myColorsIn: (session gameFor: session games first)) asArray
		equals: #( #black ).
	self
		assert:
		(session myColorsIn: (session gameFor: session games second))
			asArray
		equals: #( #white ).
	self assert: session chessComUsername equals: 'Bob'.
	session chessComUsername: nil.
	self assert: session chessComUsername isNil.
	self deny: session canImport.
	self assert: session games size equals: 2
]
