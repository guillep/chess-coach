"
My preferences, kept in settings.json next to the games: piece set, games per Load more, Stockfish path, depth and MultiPV, Ollama URL and model, coach moments per round. Each change is saved at once and reported to changedBlock (the session applies it).
"
Class {
	#name : 'ChessCoachSettings',
	#superclass : 'MMSettings',
	#category : 'ChessCoach-App',
	#package : 'ChessCoach-App'
}

{ #category : 'defaults' }
ChessCoachSettings class >> defaults [

	^ super defaults
		  at: 'pieceSet' put: 'Meridian';
		  at: 'boardTheme' put: 'Chessmate';
		  at: 'evaluationUnit' put: 'pawns';
		  at: 'gamesPerLoad' put: 20;
		  at: 'gamesCheckMinutes' put: 30;
		  at: 'stockfishPath' put: '/opt/homebrew/bin/stockfish';
		  at: 'depth' put: 18;
		  at: 'multiPV' put: 3;
		  at: 'ollamaUrl' put: 'http://localhost:11434';
		  at: 'ollamaModel' put: 'qwen2.5:7b-instruct';
		  at: 'findEvaluationJumps' put: true;
		  at: 'findOnlyMoves' put: true;
		  at: 'findLongThinks' put: true;
		  at: 'findOpeningChoices' put: true;
		  at: 'openingDatabaseMinGames' put: 5;
		  at: 'coachDatabase' put: 'lichess';
		  at: 'coachEngineLines' put: 3;
		  addAll: MomentFinder defaultThresholds;
		  yourself
]

{ #category : 'constants' }
ChessCoachSettings class >> formatVersion [
	"2 added the moment thresholds, 3 the evaluation unit, 4 replaced the win-% drops by the evaluation zones (centipawns; the old drop keys are ignored), 5 the coach's database and engine lines"

	^ 5
]

{ #category : 'accessing' }
ChessCoachSettings >> boardTheme [
	"The name of the board's colour theme (see ChessBoardElement class>>themes)"

	^ self at: 'boardTheme'
]

{ #category : 'accessing' }
ChessCoachSettings >> depth [

	^ self at: 'depth'
]

{ #category : 'accessing' }
ChessCoachSettings >> evaluationFormat [
	"How every evaluation is shown: in pawns or as a win chance"

	^ EvaluationFormat unit: (self at: 'evaluationUnit')
]

{ #category : 'accessing' }
ChessCoachSettings >> gamesCheckMinutes [

	^ self at: 'gamesCheckMinutes'
]

{ #category : 'accessing' }
ChessCoachSettings >> gamesPerLoad [

	^ self at: 'gamesPerLoad'
]

{ #category : 'accessing' }
ChessCoachSettings >> momentThresholds [
	"The thresholds of the moment heuristics"

	^ MomentFinder defaultThresholds keys
		  inject: Dictionary new
		  into: [ :thresholds :key |
			  thresholds at: key put: (self at: key).
			  thresholds ]
]

{ #category : 'accessing' }
ChessCoachSettings >> multiPV [

	^ self at: 'multiPV'
]

{ #category : 'accessing' }
ChessCoachSettings >> ollamaModel [

	^ self at: 'ollamaModel'
]

{ #category : 'accessing' }
ChessCoachSettings >> ollamaUrl [

	^ self at: 'ollamaUrl'
]

{ #category : 'accessing' }
ChessCoachSettings >> pieceSet [
	"The name of the board's piece set (Meridian, Meridian shaded, Livius, Madware)"

	^ self at: 'pieceSet'
]

{ #category : 'accessing' }
ChessCoachSettings >> stockfishPath [

	^ (self at: 'stockfishPath') asFileReference
]
