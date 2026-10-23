"
Represents a single move in a chess game. Stores both SAN (Standard Algebraic Notation) and UCI formats, along with metadata like move number and time taken.
"
Class {
	#name : 'ChessMove',
	#superclass : 'Object',
	#instVars : [
		'moveNumber',
		'color',
		'san',
		'uci',
		'timestamp'
	],
	#category : 'ChessCoach-Core',
	#package : 'ChessCoach-Core'
}

{ #category : 'accessing' }
ChessMove >> color [

	^ color
]

{ #category : 'accessing' }
ChessMove >> moveNumber [

	^ moveNumber
]

{ #category : 'initialization' }
ChessMove >> moveNumber: aNumber color: aColor san: aSAN uci: aUCI timestamp: aDuration [

	moveNumber := aNumber.
	color := aColor.
	san := aSAN.
	uci := aUCI.
	timestamp := aDuration.
	^ self
]

{ #category : 'accessing' }
ChessMove >> san [

	^ san
]

{ #category : 'accessing' }
ChessMove >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
ChessMove >> uci [

	^ uci
]
