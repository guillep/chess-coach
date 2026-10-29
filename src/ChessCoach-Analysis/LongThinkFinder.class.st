"
Finds the moves a player thought about much longer than usual, from the [%clk] clocks of the PGN: at least 3 times that player's average time per move in the game, and at least 10 seconds. The time of a move is the clock before it minus the clock after it, plus the increment of the TimeControl tag. Games without clocks have no such moments.
"
Class {
	#name : 'LongThinkFinder',
	#superclass : 'Object',
	#instVars : [
		'game'
	],
	#category : 'ChessCoach-Analysis',
	#package : 'ChessCoach-Analysis'
}

{ #category : 'instance creation' }
LongThinkFinder class >> on: aGame [

	^ self new
		  setGame: aGame;
		  yourself
]

{ #category : 'finding' }
LongThinkFinder >> moments [

	| seconds averages |
	seconds := self secondsPerPly.
	averages := Dictionary new.
	#( 1 0 ) do: [ :parity |
			| own |
			own := (seconds keys select: [ :ply | ply \\ 2 = parity ])
				       collect: [ :ply | seconds at: ply ].
			averages at: parity put: (own
					 ifEmpty: [ 0 ]
					 ifNotEmpty: [
					 (own inject: 0 into: [ :sum :each | sum + each ]) / own size ]) ].
	^ (seconds keys asArray sort select: [ :ply |
			   | used |
			   used := seconds at: ply.
			   used >= 10 and: [ used >= (3 * (averages at: ply \\ 2)) ] ])
		  collect: [ :ply |
				  ChessMoment
					  ply: ply
					  color: (ply odd
							   ifTrue: [ #white ]
							   ifFalse: [ #black ])
					  kind: #longThink
					  source: #clock
					  note:
						  ('You spent {1} s on this move (your average: {2} s)' format:
							   {
								   (seconds at: ply) rounded.
								   (averages at: ply \\ 2) rounded }) ]
]

{ #category : 'finding' }
LongThinkFinder >> secondsPerPly [
	"Ply -> seconds the mover spent on it, for the plies with a clock"

	| control moves seconds |
	control := self timeControl ifNil: [ ^ Dictionary new ].
	moves := game moves.
	seconds := Dictionary new.
	moves withIndexDo: [ :move :ply |
			| before |
			before := ply <= 2
				          ifTrue: [ control key ]
				          ifFalse: [
						          (moves at: ply - 2) timestamp ifNotNil: [ :clock |
							          clock asMilliSeconds / 1000 ] ].
			(before notNil and: [ move timestamp notNil ]) ifTrue: [
					seconds
						at: ply
						put:
						before - (move timestamp asMilliSeconds / 1000) + control value ] ].
	^ seconds
]

{ #category : 'initialization' }
LongThinkFinder >> setGame: aGame [

	game := aGame
]

{ #category : 'private' }
LongThinkFinder >> timeControl [
	"Base and increment in seconds from the TimeControl tag ('600+5', '180'); nil when unknown or daily"

	| parts |
	parts := (game metadata at: 'TimeControl' ifAbsent: [ '' ])
		         substrings: '+'.
	(parts isEmpty or: [
		 parts anySatisfy: [ :each | each isAllDigits not ] ]) ifTrue: [
		^ nil ].
	^ parts first asInteger -> (parts size > 1
		   ifTrue: [ parts second asInteger ]
		   ifFalse: [ 0 ])
]
