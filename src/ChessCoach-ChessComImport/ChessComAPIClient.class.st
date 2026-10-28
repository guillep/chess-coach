"
Chess.com's public data API (no login): a player's monthly game archives and the games in each. Tests substitute ChessComAPIClientStub, which overrides #getJSON:.
"
Class {
	#name : 'ChessComAPIClient',
	#superclass : 'Object',
	#instVars : [
		'baseUrl'
	],
	#category : 'ChessCoach-ChessComImport',
	#package : 'ChessCoach-ChessComImport'
}

{ #category : 'fetching' }
ChessComAPIClient >> archivesOf: aUsername [
	"URLs of the player's monthly archives, newest first"

	^ ((self getJSON:
		    baseUrl , '/player/' , aUsername asLowercase , '/games/archives')
		   at: 'archives') reversed
]

{ #category : 'fetching' }
ChessComAPIClient >> gamesInArchive: anArchiveUrl [
	"The game dictionaries of one monthly archive (url, pgn, time_control, end_time, rules, white, black, …)"

	^ (self getJSON: anArchiveUrl) at: 'games'
]

{ #category : 'private' }
ChessComAPIClient >> getJSON: aUrl [
	"Chess.com asks API users to identify themselves with a User-Agent"

	^ STONJSON fromString: (ZnClient new
			   url: aUrl;
			   headerAt: 'User-Agent' put: 'chess-coach (Pharo)';
			   enforceHttpSuccess: true;
			   get)
]

{ #category : 'initialization' }
ChessComAPIClient >> initialize [

	super initialize.
	baseUrl := 'https://api.chess.com/pub'
]
