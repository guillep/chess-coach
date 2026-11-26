"
I check the widgets `MMWidgets` builds, in an open space.
"
Class {
	#name : 'MMWidgetsTest',
	#superclass : 'MMSpaceTestCase',
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'tests' }
MMWidgetsTest >> testDropdownWithAPlaceholderIsOneSelect [

	| select |
	select := MMWidgets dropdown: { 'One' -> 1 } placeholder: 'Add one' do: [ :value | ].
	space root addChild: select.
	space settle.
	self assert: (space root allChildrenBreadthFirstSelect: [ :each | each isKindOf: ToSingleSelectElement ]) size equals: 1
]

{ #category : 'tests' }
MMWidgetsTest >> testDropdownWithAPlaceholderPassesEachPick [

	| picked select |
	picked := OrderedCollection new.
	select := MMWidgets
		          dropdown: { 'One' -> 1. 'Two' -> 2 }
		          placeholder: 'Add one'
		          do: [ :value | picked add: value ].
	space root addChild: select.
	space settle.
	self assert: select selectedDataItem isNil.
	select selecter selectIndex: 2.
	space settle.
	self assert: picked asArray equals: #( 2 )
]
