Class {
	#name : 'EvaluationZonesTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
EvaluationZonesTest >> testTheAgreedExamples [
	"The examples of the grilling of 2026-11-03"

	| zones |
	zones := EvaluationZones default.
	{
		(8 -> 6 -> nil).
		(1.5 -> 0.8 -> nil).
		(8 -> 3 -> #inaccuracy).
		(-3 -> -6 -> #inaccuracy).
		(2.5 -> 1.5 -> #mistake).
		(0 -> -1 -> #mistake).
		(0.9 -> 0.2 -> #mistake).
		(1 -> -1 -> #blunder).
		(0 -> -3 -> #blunder).
		(0.7 -> 0.5 -> nil).
		(2.2 -> 1.8 -> nil).
		(1.9 -> 0.7 -> #inaccuracy).
		(4.9 -> 2.1 -> #inaccuracy).
		(12 -> 6 -> nil).
		(0 -> 1 -> nil).
		(100 -> -100 -> #blunder) } do: [ :each |
			self
				assert: (zones kindFrom: each key key to: each key value)
				equals: each value ]
]
