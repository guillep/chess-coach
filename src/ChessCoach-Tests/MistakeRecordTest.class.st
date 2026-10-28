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
