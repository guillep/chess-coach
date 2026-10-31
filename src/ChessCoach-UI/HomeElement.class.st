"
I am the landing page: a game to review, usage numbers, the latest games and the notifications. I refresh each time I am shown.
"
Class {
	#name : 'HomeElement',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'gameBlock',
		'zone'
	],
	#category : 'ChessCoach-UI-App',
	#package : 'ChessCoach-UI',
	#tag : 'App'
}

{ #category : 'building' }
HomeElement >> gameButton: anEntry [

	^ ToButton new
		  labelText: ('{1} – {2} · {3} · {4}' format: {
						   anEntry players first.
						   anEntry players second.
						   anEntry result.
						   anEntry date });
		  clickAction: [ gameBlock value: anEntry ];
		  yourself
]

{ #category : 'initialization' }
HomeElement >> initialize [

	super initialize.
	gameBlock := [ :entry |  ].
	self layout: BlFrameLayout new.
	self matchParent.
	zone := ToElement new
		        layout: (BlLinearLayout vertical cellSpacing: 12);
		        hMatchParent;
		        vFitContent;
		        padding: (BlInsets right: 16);
		        yourself.
	self addChild: (ChessCoachWidgets
			 page: 'Home'
			 subtitle: 'Pour a mate. Here is what is going on.'
			 body: (ChessCoachWidgets scrollable: zone)).
	self
		addEventHandlerOn: BlElementAddedToSceneGraphEvent
		do: [ :event | session ifNotNil: [ self update ] ]
]

{ #category : 'accessing' }
HomeElement >> session: aChessCoachSession [

	session := aChessCoachSession.
	self update
]

{ #category : 'updating' }
HomeElement >> update [
	"The suggestion, the numbers, the latest games and the notifications"

	| games records notifications |
	zone removeChildren.
	games := session games.
	records := session mistakeDatabase.
	session suggestedGame ifNotNil: [ :entry |
			zone addChild: (ChessCoachWidgets
					 section: 'Do you want to review this game?'
					 help:
					 'Your latest lost game without a review, or the latest game without one.'
					 rows: { (self gameButton: entry) }) ].
	zone addChild:
		(ChessCoachWidgets section: 'Your numbers' help: nil rows: {
				 (ToLabel text: ('{1} games · {2} reviewed' format: {
							   games size.
							   session reviewedGameIds size })).
				 (ToLabel text: (records tagFrequencies
						   ifEmpty: [ 'No mistakes tagged yet' ]
						   ifNotEmpty: [ :frequencies |
								   'Most frequent mistake: '
								   ,
								   (MistakeTaxonomy default tagAt: frequencies keys first)
									   name ])) }).
	zone addChild: (ChessCoachWidgets
			 section: 'Latest games'
			 help: nil
			 rows: ((games first: (games size min: 5)) collect: [ :each |
					  self gameButton: each ])).
	notifications := session notifications visible.
	notifications ifNotEmpty: [
			zone addChild: (ChessCoachWidgets
					 section: 'Notifications'
					 help: nil
					 rows: (notifications collect: [ :each |
								  ChessCoachWidgets paragraph: each title
									  ,
									  (each text
										   ifEmpty: [ '' ]
										   ifNotEmpty: [ :text | ': ' , text ]) ])) ]
]

{ #category : 'accessing' }
HomeElement >> whenGameChosenDo: aBlock [
	"aBlock receives the index entry of a game to open"

	gameBlock := aBlock
]
