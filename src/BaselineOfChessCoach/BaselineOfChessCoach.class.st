"
Baseline for the Chess Coach project. Defines the package structure and dependencies for importing games, implementing Socratic coaching, and providing a Bloc-based UI.
"
Class {
	#name : 'BaselineOfChessCoach',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfChessCoach',
	#package : 'BaselineOfChessCoach'
}

{ #category : 'baselines' }
BaselineOfChessCoach >> baseline: spec [

	<baseline>
	spec for: #common do: [
			spec
				baseline: 'Bloc'
				with: [
				spec repository: 'github://pharo-graphics/Bloc:v2.9.0/src' ].

			spec package: 'ChessCoach-Core'.

			spec
				package: 'ChessCoach-FileStorage'
				with: [ spec requires: #( 'ChessCoach-Core' ) ].

			spec
				package: 'ChessCoach-LichessImport'
				with: [
				spec requires: #( 'ChessCoach-Core' 'ChessCoach-FileStorage' ) ].

			spec
				package: 'ChessCoach-UI'
				with: [ spec requires: #( 'ChessCoach-Core' 'Bloc' ) ].

			spec package: 'ChessCoach-Tests' with: [
					spec requires:
						#( 'ChessCoach-Core' 'ChessCoach-FileStorage'
						   'ChessCoach-UI' ) ] ]
]
