Class {
	#name : 'MMErrorLogTest',
	#superclass : 'TestCase',
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'tests' }
MMErrorLogTest >> testErrorsAreAppendedWithTheirStack [

	| file log |
	file := FileSystem memory root / 'data' / 'errors.log'.
	log := MMErrorLog onFile: file.
	[ 1 / 0 ]
		on: ZeroDivide
		do: [ :error | log log: error ].
	[ Error signal: 'second' ]
		on: Error
		do: [ :error | log log: error ].
	self
		assert:
		(file contents lines count: [ :each | each beginsWith: '--- ' ])
		equals: 2.
	self assert: (file contents includesSubstring: 'ZeroDivide').
	self assert: (file contents includesSubstring: 'Error: second').
	self assert: (file contents includesSubstring:
			 'testErrorsAreAppendedWithTheirStack')
]
