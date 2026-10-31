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

"The window is the app: closing it quits, and the Pharo world stays hidden"
ChessCoachAppElement open space
	addEventHandlerOn: BlSpaceClosedEvent
	do: [ :event | Smalltalk snapshot: false andQuit: true ].
self currentWorld worldState worldRenderer osWindow hide.
(Delay forSeconds: 1) wait.
BlSpace allInstances do: [ :space | space isOpened ifTrue: [ space maximize ] ].
