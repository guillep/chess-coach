Class {
	#name : 'MistakeTaxonomyTest',
	#superclass : 'TestCase',
	#category : 'ChessCoach-Tests',
	#package : 'ChessCoach-Tests'
}

{ #category : 'tests' }
MistakeTaxonomyTest >> testDefaultTaxonomy [

	| taxonomy |
	taxonomy := MistakeTaxonomy default.
	self
		assert: taxonomy categories
		equals:
		#( 'perception' 'calculation' 'evaluation' 'decision' 'knowledge' ).
	self assert: taxonomy tagIds asSet size equals: taxonomy tags size.
	self
		assert: (taxonomy tagAt: 'hope-chess') category
		equals: 'calculation'.
	self assert: (taxonomy tagsInCategory: 'knowledge') size equals: 3.
	self should: [ taxonomy tagAt: 'nonsense' ] raise: NotFound
]
