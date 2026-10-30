Class {
	#name : 'MistakesDashboardElementTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'helpers' }
MistakesDashboardElementTest >> database [

	| record |
	record := [ :gameId :phase :tags |
		          MistakeRecord new
			          gameId: gameId;
			          ply: 21;
			          date: (Date year: 2026 month: 10 day: 1);
			          phase: phase;
			          playedMove: 'e2e4';
			          bestMove: 'd2d4';
			          winDrop: 25;
			          explanation: 'too fast';
			          labels: (tags collect: [ :each |
							           (MistakeLabel tagId: each confidence: 1)
								           confirm;
								           yourself ]);
			          yourself ].
	^ MistakeDatabase withRecords: {
			  (record
				   value: 'g1'
				   value: 'opening'
				   value: #( 'no-blunder-check' 'hope-chess' )).
			  (record
				   value: 'g2'
				   value: 'endgame'
				   value: #( 'no-blunder-check' )) }
]

{ #category : 'tests' }
MistakesDashboardElementTest >> testEmptyState [

	| dashboard started |
	dashboard := MistakesDashboardElement new.
	started := false.
	dashboard whenStartRequestedDo: [ started := true ].
	self assert: (dashboard texts includes: 'Nothing to talk about yet').
	BlSpace simulateClickOn: dashboard content children last.
	self assert: started
]

{ #category : 'tests' }
MistakesDashboardElementTest >> testShowsFrequenciesPhasesTrendAndDetail [

	| dashboard selected |
	dashboard := MistakesDashboardElement new.
	dashboard database: self database.
	dashboard whenRecordSelectedDo: [ :record | selected := record ].
	self assert: (dashboard texts includes: 'No blunder check').
	self assert: (dashboard texts includes:
			 'Opening: No blunder check ×1, Hope chess ×1').
	self assert:
		(dashboard texts includes: 'Endgame: No blunder check ×1').
	dashboard selectTag: 'hope-chess'.
	self assert:
		(dashboard texts includes: '2026-10-01 · game g1, move 11: too fast').
	BlSpace simulateClickOn: dashboard detail children last.
	self assert: selected gameId equals: 'g1'
]
