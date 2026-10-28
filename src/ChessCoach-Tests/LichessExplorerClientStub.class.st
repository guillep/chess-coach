"
I answer canned explorer data per FEN (no games for unknown positions) and record the requests made.
"
Class {
	#name : 'LichessExplorerClientStub',
	#superclass : 'LichessExplorerClient',
	#instVars : [
		'responses',
		'requests'
	],
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'accessing' }
LichessExplorerClientStub >> at: aFEN moves: moveStats [
	"moveStats: an array of { san. whiteWins. draws. blackWins }; the position's totals are their sums"

	| moves |
	moves := moveStats collect: [ :each |
			         Dictionary new
				         at: 'san' put: each first;
				         at: 'white' put: each second;
				         at: 'draws' put: each third;
				         at: 'black' put: each fourth;
				         yourself ].
	responses at: aFEN put: (Dictionary new
			 at: 'white'
			 put:
				 (moves inject: 0 into: [ :sum :each | sum + (each at: 'white') ]);
			 at: 'draws'
			 put:
				 (moves inject: 0 into: [ :sum :each | sum + (each at: 'draws') ]);
			 at: 'black'
			 put:
				 (moves inject: 0 into: [ :sum :each | sum + (each at: 'black') ]);
			 at: 'moves' put: moves;
			 yourself)
]

{ #category : 'initialization' }
LichessExplorerClientStub >> initialize [

	super initialize.
	responses := Dictionary new.
	requests := OrderedCollection new
]

{ #category : 'querying' }
LichessExplorerClientStub >> lichessMovesFor: aFEN speed: aSpeed ratings: someRatings [

	requests add: {
			aFEN.
			aSpeed.
			someRatings }.
	^ responses at: aFEN ifAbsent: [
			  Dictionary new
				  at: 'white' put: 0;
				  at: 'draws' put: 0;
				  at: 'black' put: 0;
				  at: 'moves' put: #(  );
				  yourself ]
]

{ #category : 'accessing' }
LichessExplorerClientStub >> requests [
	"Each request as { fen. speed. ratings }"

	^ requests
]
