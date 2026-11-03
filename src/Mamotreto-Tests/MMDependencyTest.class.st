"
Mamotreto is the shell, Chessmate one app on it: nothing in a Mamotreto-* package may name a ChessCoach* or Chessmate* class, as a superclass or from a method.
"
Class {
	#name : 'MMDependencyTest',
	#superclass : 'TestCase',
	#category : 'Mamotreto-Tests',
	#package : 'Mamotreto-Tests'
}

{ #category : 'private' }
MMDependencyTest >> appReferencesIn: aPackage [
	"Each place in aPackage that names a Chessmate class, as place -> name"

	| found |
	found := OrderedCollection new.
	aPackage definedClasses do: [ :each |
			(each superclass notNil and: [
				 self isAppName: each superclass name ]) ifTrue: [
				found add: each name -> each superclass name ] ].
	aPackage methods do: [ :method |
			method literals do: [ :literal |
					(literal isVariableBinding and: [ self isAppName: literal key ])
						ifTrue: [ found add: method printString -> literal key ] ] ].
	^ found
]

{ #category : 'private' }
MMDependencyTest >> isAppName: aName [
	"Whether aName is one of Chessmate's, which the shell must not know"

	^ (aName beginsWith: 'ChessCoach') or: [
		  aName beginsWith: 'Chessmate' ]
]

{ #category : 'tests' }
MMDependencyTest >> testAppNames [

	self assert: (self isAppName: 'ChessCoachSession').
	self assert: (self isAppName: 'ChessmateTheme').
	self deny: (self isAppName: 'MMWidgets').
	self deny: (self isAppName: 'ChessBoardElement')
]

{ #category : 'tests' }
MMDependencyTest >> testShellDoesNotReferenceTheApp [

	| packages found |
	packages := self packageOrganizer packages select: [ :each |
		            each name beginsWith: 'Mamotreto-' ].
	self deny: packages isEmpty.
	found := packages flatCollect: [ :each | self appReferencesIn: each ].
	self assert: found isEmpty description: [ found printString ]
]
