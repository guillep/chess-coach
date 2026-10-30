"Stop the build if the app's repository was not cloned and registered"
(IceRepository registry anySatisfy: [ :each |
	each name = 'chess-coach' and: [ each location notNil and: [ each location exists ] ] ])
		ifFalse: [
			Stdio stderr nextPutAll: 'chess-coach repository is missing'; lf; flush.
			Smalltalk exit: 1 ].
