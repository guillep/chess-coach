"
The Home's widgets and their file, home.json. Adding a field means bumping formatVersion: older files still load, a missing field gets its default. A corrupt or newer file gives the default Home and is kept as home.json.bad.
"
Class {
	#name : 'HomeConfiguration',
	#superclass : 'Object',
	#instVars : [
		'file',
		'grid',
		'reportBlock'
	],
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'accessing' }
HomeConfiguration class >> formatVersion [

	^ 1
]

{ #category : 'instance creation' }
HomeConfiguration class >> onFile: aFileReference report: aBlock [

	^ self new
		  setFile: aFileReference report: aBlock;
		  yourself
]

{ #category : 'accessing' }
HomeConfiguration >> grid [

	^ grid
]

{ #category : 'actions' }
HomeConfiguration >> reload [
	"What is saved, or the default Home"

	| contents |
	file exists ifFalse: [ ^ self resetToDefault ].
	contents := [ STONJSON fromString: file contents ]
		            on: Error
		            do: [ :error | ^ self setAside: 'It could not be read' ].
	(contents isDictionary and: [
			 (contents at: 'version' ifAbsent: [ nil ]) isInteger and: [
				 (contents at: 'version') <= self class formatVersion ] ])
		ifFalse: [ ^ self setAside: 'It comes from a newer version' ].
	grid := HomeGrid withWidgets:
		        (self widgetsFrom:
			         (contents at: 'widgets' ifAbsent: [ #(  ) ]))
]

{ #category : 'actions' }
HomeConfiguration >> resetToDefault [

	grid := HomeGrid withWidgets: HomeWidget defaultWidgets
]

{ #category : 'actions' }
HomeConfiguration >> save [
	"Through a temporary file, so a failure can't leave half a file"

	| temporary |
	file parent ensureCreateDirectory.
	temporary := file parent / (file basename , '.tmp').
	temporary
		ensureDelete;
		writeStreamDo: [ :stream |
				stream nextPutAll: (STONJSON toStringPretty: (Dictionary new
									  at: 'version' put: self class formatVersion;
									  at: 'widgets'
									  put:
										  (grid widgets collect: [ :each | each asDictionary ])
											  asArray;
									  yourself)) ].
	file ensureDelete.
	temporary renameTo: file basename
]

{ #category : 'private' }
HomeConfiguration >> setAside: aString [
	"Keep the file to not lose it, and start from the default Home"

	| bad |
	bad := file parent / (file basename , '.bad').
	bad ensureDelete.
	file renameTo: bad basename.
	reportBlock value: aString , '; it was kept as ' , bad basename.
	self resetToDefault
]

{ #category : 'initialization' }
HomeConfiguration >> setFile: aFileReference report: aBlock [

	file := aFileReference.
	reportBlock := aBlock.
	self reload
]

{ #category : 'private' }
HomeConfiguration >> widgetsFrom: someDictionaries [
	"Unknown types are skipped and reported; the others still work"

	| widgets |
	widgets := OrderedCollection new.
	someDictionaries do: [ :each |
			(HomeWidget classForType: (each at: 'type' ifAbsent: [ nil ]))
				ifNil: [
						reportBlock value: 'Unknown widget skipped: '
							, (each at: 'type' ifAbsent: [ '?' ]) asString ]
				ifNotNil: [ :class | widgets add: (class fromDictionary: each) ] ].
	^ widgets
]
