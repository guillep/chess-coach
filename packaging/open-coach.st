"The image was built elsewhere and copied: point its repositories at the clones next to it"
IceRepository registry do: [ :repository |
	repository location ifNotNil: [ :location |
		| segments index |
		segments := location absolutePath segments.
		index := segments indexOf: 'iceberg'.
		index > 0 ifTrue: [
			repository location: ((segments allButFirst: index)
				inject: FileLocator imageDirectory resolve / 'pharo-local' / 'iceberg'
				into: [ :directory :segment | directory / segment ]) ] ] ].

ChessCoachAppElement open.
