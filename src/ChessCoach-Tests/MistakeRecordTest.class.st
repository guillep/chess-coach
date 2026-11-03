Class {
	#name : 'MistakeRecordTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
MistakeRecordTest >> testJSONRoundTrip [

	| record copy |
	record := MistakeRecord new
		          gameId: 'abcd1234';
		          ply: 23;
		          date: (Date year: 2026 month: 10 day: 28);
		          phase: 'middlegame';
		          kinds: #( #blunder #onlyMove );
		          playedMove: 'e1g1';
		          bestMove: 'd4e5';
		          winDrop: 31.5;
		          explanation: 'I did not see the knight fork';
		          labels:
			          { ((MistakeLabel
				            tagId: 'missed-opponent-threat'
				            confidence: 0.8)
				           confirm;
				           yourself) };
		          yourself.
	copy := MistakeRecord fromDictionary:
		        (STONJSON fromString:
			         (STONJSON toString: record asDictionary)).
	self assert: copy asDictionary equals: record asDictionary.
	self assert: copy date equals: record date.
	self assert: (copy hasTag: 'missed-opponent-threat').
	self assert: copy labels first isConfirmed.
	self deny: (copy hasTag: 'hope-chess')
]

{ #category : 'tests' }
MistakeRecordTest >> testReadingSignalsNoDeprecation [
	"A Deprecation signalled inside a Bloc pulse starts a second UI loop"

	| dictionary |
	dictionary := (MistakeRecord new
		               gameId: 'abcd1234';
		               ply: 23;
		               date: (Date year: 2026 month: 10 day: 28);
		               phase: 'middlegame';
		               kinds: #( #blunder );
		               playedMove: 'e1g1';
		               bestMove: 'd4e5';
		               winDrop: 31.5;
		               explanation: '';
		               labels: #(  );
		               yourself) asDictionary.
	self
		shouldnt: [ MistakeRecord fromDictionary: dictionary ]
		raise: Deprecation
]

{ #category : 'tests' }
MistakeRecordTest >> testTentativeLabelsCountOnlyOnceConfirmed [

	| moment |
	moment := CoachMomentReview ply: 7 color: #white kinds: #( #mistake ).
	moment proposeLabels: {
			(MistakeLabel tagId: 'hope-chess' confidence: 0.9).
			(MistakeLabel tagId: 'no-blunder-check' confidence: 0.5) }.
	self
		assert:
		(moment countedLabels collect: [ :each | each tagId ]) asArray
		equals: #( 'hope-chess' ).
	moment toggleTag: 'no-blunder-check'.
	self assert: moment countedLabels size equals: 2.
	moment toggleTag: 'no-blunder-check'.
	self assert: moment countedLabels size equals: 1
]
