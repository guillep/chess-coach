"
Baseline for the Chess Coach project. Defines the package structure and dependencies for importing games, implementing Socratic coaching, and providing a Bloc-based UI.
"
Class {
	#name : 'BaselineOfChessCoach',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfChessCoach',
	#package : 'BaselineOfChessCoach'
}

{ #category : 'baseline' }
BaselineOfChessCoach >> baseline: spec [

	<baseline>
	spec for: #common do: [ "Core domain models"
			spec package: 'ChessCoach-Core'.

			"File storage and PGN parsing"
			spec
				package: 'ChessCoach-FileStorage'
				dependsOn: #( 'ChessCoach-Core' ).

			"Lichess import (OAuth2, API client)"
			spec
				package: 'ChessCoach-LichessImport'
				dependsOn: #( 'ChessCoach-Core' 'ChessCoach-FileStorage' ).

			"Coach logic (Socratic prompts, review sequencing)"
			spec package: 'ChessCoach-Coach' dependsOn: #( 'ChessCoach-Core' ).

			"Bloc dependencies"
			spec
				baseline: 'Bloc'
				with: [
				spec repository: 'github://pharo-graphics/Bloc:dev-1.0/src' ].

			"Bloc-based UI"
			spec
				package: 'ChessCoach-UI-Bloc'
				dependsOn: #( 'ChessCoach-Core' 'ChessCoach-Coach'
				   'Bloc' ).

			"Tests"
			spec
				package: 'ChessCoach-Tests'
				dependsOn:
					#( 'ChessCoach-Core' 'ChessCoach-FileStorage'
					   'ChessCoach-Coach' 'ChessCoach-UI-Bloc' ) ]
]
