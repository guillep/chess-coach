"
I am one line of an engine analysis: the moves in UCI notation and the score, always from White's point of view.
centipawns is nil when the line is a forced mate; mate is then the number of moves to mate (positive when White mates, negative when Black mates, 0 when the side to move is already mated).
whiteWinPercent is White's winning chance (0-100) using Lichess's formula.
"
Class {
	#name : 'EngineLine',
	#superclass : 'Object',
	#instVars : [
		'moves',
		'centipawns',
		'mate',
		'whiteWinPercent'
	],
	#category : 'ChessCoach-Engine',
	#package : 'ChessCoach-Engine'
}

{ #category : 'instance creation' }
EngineLine class >> fromDictionary: aDictionary [

	^ self new
		  setMoves: (aDictionary at: 'moves')
		  centipawns: (aDictionary at: 'centipawns')
		  mate: (aDictionary at: 'mate')
		  whiteWinPercent: (aDictionary at: 'whiteWinPercent')
]

{ #category : 'instance creation' }
EngineLine class >> moves: aCollection centipawns: aNumber sideToMove: aColor [
	"A line scored by UCI 'score cp', which is from the side to move's point of view"

	| sign |
	sign := aColor = #white
		        ifTrue: [ 1 ]
		        ifFalse: [ -1 ].
	^ self new
		  setMoves: aCollection
		  centipawns: aNumber * sign
		  mate: nil
		  whiteWinPercent: (self winPercentForCentipawns: aNumber * sign)
]

{ #category : 'instance creation' }
EngineLine class >> moves: aCollection mate: aNumber sideToMove: aColor [
	"A line scored by UCI 'score mate'. aNumber > 0 means the side to move mates; 0 or less means it is mated."

	| sideToMoveWins whiteWins |
	sideToMoveWins := aNumber > 0.
	whiteWins := sideToMoveWins = (aColor = #white).
	^ self new
		  setMoves: aCollection
		  centipawns: nil
		  mate: (whiteWins
				   ifTrue: [ aNumber abs ]
				   ifFalse: [ aNumber abs negated ])
		  whiteWinPercent: (whiteWins
				   ifTrue: [ 100 ]
				   ifFalse: [ 0 ])
]

{ #category : 'win percent' }
EngineLine class >> winPercentForCentipawns: aNumber [
	"Lichess's winning chance (0-100) for the side the centipawns favour"

	^ 50 + (50 * (2 / (1 + (-0.00368208 * aNumber) exp) - 1))
]

{ #category : 'converting' }
EngineLine >> asDictionary [
	"A fresh dictionary for JSON; moves is copied because STON rejects shared references"

	^ Dictionary new
		  at: 'moves' put: moves copy;
		  at: 'centipawns' put: centipawns;
		  at: 'mate' put: mate;
		  at: 'whiteWinPercent' put: whiteWinPercent;
		  yourself
]

{ #category : 'accessing' }
EngineLine >> firstMove [

	^ moves ifEmpty: [ nil ] ifNotEmpty: [ moves first ]
]

{ #category : 'accessing' }
EngineLine >> isMateFor: aColor [
	"Whether aColor mates (or has already mated) in this line"

	^ mate notNil and: [ (self winPercentFor: aColor) = 100 ]
]

{ #category : 'accessing' }
EngineLine >> moves [
	"Moves in UCI notation (e2e4), starting from the analysed position"

	^ moves
]

{ #category : 'accessing' }
EngineLine >> scoreString [
	"The score as shown to people: +1.25, -0.40, #3, #-2"

	mate ifNotNil: [ ^ '#' , mate printString ].
	^ (centipawns >= 0
		   ifTrue: [ '+' ]
		   ifFalse: [ '' ])
	  , (centipawns / 100 printShowingDecimalPlaces: 2)
]

{ #category : 'initialization' }
EngineLine >> setMoves: aCollection centipawns: aCentipawnCount mate: aMateCount whiteWinPercent: aPercent [

	moves := aCollection asArray.
	centipawns := aCentipawnCount.
	mate := aMateCount.
	whiteWinPercent := aPercent
]

{ #category : 'accessing' }
EngineLine >> whiteWinPercent [

	^ whiteWinPercent
]

{ #category : 'accessing' }
EngineLine >> winPercentFor: aColor [
	"aColor's winning chance, 0-100"

	^ aColor = #white
		  ifTrue: [ whiteWinPercent ]
		  ifFalse: [ 100 - whiteWinPercent ]
]
