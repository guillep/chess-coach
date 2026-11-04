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

			spec baseline: 'ApplicationGenerator' with: [
					spec repository:
						'github://tesonep/PharoApplicationGenerator:v1.0.0/src' ].

			spec package: 'Mamotreto-Core'.

			spec
				package: 'Mamotreto-UI'
				with: [ spec requires: #( 'Mamotreto-Core' 'Bloc' 'Toplo' ) ].

			spec
				package: 'Mamotreto-Packaging'
				with: [ spec requires: #( 'Mamotreto-UI' 'ApplicationGenerator' ) ].

			spec
				package: 'Mamotreto-Example'
				with: [ spec requires: #( 'Mamotreto-Core' 'Mamotreto-UI' ) ].

			spec package: 'Mamotreto-Tests' with: [
					spec requires:
						#( 'Mamotreto-Core' 'Mamotreto-UI' 'Mamotreto-Packaging'
						   'Mamotreto-Example' ) ].

			spec package: 'ChessCoach-Core'.

			spec
				package: 'ChessCoach-FileStorage'
				with: [ spec requires: #( 'ChessCoach-Core' ) ].

			spec
				package: 'ChessCoach-LichessImport'
				with: [
				spec requires: #( 'ChessCoach-Core' 'ChessCoach-FileStorage' ) ].

			spec
				package: 'ChessCoach-ChessComImport'
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
					spec requires: #( 'Mamotreto-Core' 'ChessCoach-LichessImport'
						   'ChessCoach-ChessComImport' 'ChessCoach-Analysis'
						   'ChessCoach-Coach' ) ].

			spec package: 'ChessCoach-UI' with: [
					spec requires:
						#( 'ChessCoach-Core' 'ChessCoach-App' 'Mamotreto-UI'
						   'Bloc' 'Toplo' ) ].

			spec package: 'ChessCoach-Tests' with: [
					spec requires:
						#( 'ChessCoach-Core' 'ChessCoach-FileStorage'
						   'ChessCoach-LichessImport' 'ChessCoach-ChessComImport'
						   'ChessCoach-Engine' 'ChessCoach-LLM' 'ChessCoach-Analysis'
						   'ChessCoach-Coach' 'ChessCoach-App' 'ChessCoach-UI'
						   'Mamotreto-Tests' ) ] ]
]
