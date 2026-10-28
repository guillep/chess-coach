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

			spec
				baseline: 'Toplo'
				with: [
				spec repository: 'github://pharo-graphics/Toplo:v0.10.0/src' ].

			spec baseline: 'OSSubprocess' with: [
					spec repository:
						'github://pharo-contributions/OSSubprocess:v2.0.1/repository' ].

			spec package: 'ChessCoach-Core'.

			spec
				package: 'ChessCoach-FileStorage'
				with: [ spec requires: #( 'ChessCoach-Core' ) ].

			spec
				package: 'ChessCoach-LichessImport'
				with: [
				spec requires: #( 'ChessCoach-Core' 'ChessCoach-FileStorage' ) ].

			spec
				package: 'ChessCoach-Engine'
				with: [ spec requires: #( 'OSSubprocess' ) ].

			spec
				package: 'ChessCoach-LLM'
				with: [ spec requires: #( 'ChessCoach-Core' ) ].

			spec package: 'ChessCoach-Analysis' with: [
					spec requires:
						#( 'ChessCoach-Core' 'ChessCoach-Engine' 'ChessCoach-LichessImport' ) ].

			spec
				package: 'ChessCoach-Coach'
				with: [
				spec requires: #( 'ChessCoach-Analysis' 'ChessCoach-LLM' ) ].

			spec package: 'ChessCoach-App' with: [
					spec requires:
						#( 'ChessCoach-LichessImport' 'ChessCoach-Analysis'
						   'ChessCoach-Coach' ) ].

			spec package: 'ChessCoach-UI' with: [
				spec requires:
					#( 'ChessCoach-Core' 'ChessCoach-App' 'Bloc' 'Toplo' ) ].

			spec package: 'ChessCoach-Tests' with: [
					spec requires:
						#( 'ChessCoach-Core' 'ChessCoach-FileStorage'
						   'ChessCoach-LichessImport' 'ChessCoach-Engine'
						   'ChessCoach-LLM' 'ChessCoach-Analysis' 'ChessCoach-Coach'
						   'ChessCoach-App' 'ChessCoach-UI' ) ] ]
]
