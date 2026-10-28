"
Manages OAuth2 authentication with Lichess. Handles authorization code flow, token exchange, and token refresh.
"
Class {
	#name : 'LichessOAuth2Client',
	#superclass : 'Object',
	#instVars : [
		'clientId',
		'redirectUri',
		'accessToken',
		'tokenExpiresAt',
		'codeVerifier',
		'tokenFile',
		'authorizationCodeReceived',
		'username'
	],
	#category : 'ChessCoach-LichessImport',
	#package : 'ChessCoach-LichessImport'
}

{ #category : 'instance creation' }
LichessOAuth2Client class >> onTokenFile: aFileReference [

	^ self new
		  initializeWithTokenFile: aFileReference;
		  yourself
]

{ #category : 'accessing' }
LichessOAuth2Client >> accessToken [

	^ accessToken
]

{ #category : 'oauth2' }
LichessOAuth2Client >> authenticate [
	"Run the browser PKCE flow and return the access token, saving it to the token file.
	Answer nil when the user cancels or nothing arrives within five minutes."

	| server authCode |
	self hasValidToken ifTrue: [ ^ accessToken ].
	authorizationCodeReceived := Semaphore new.
	server := ZnServer on: 8888.
	server onRequestRespond: [ :request |
			(request uri queryAt: #code ifAbsent: [ nil ])
				ifNil: [
						ZnResponse badRequest: (ZnEntity html:
								 '<html><body><h1>Error</h1><p>No authorization code received.</p></body></html>') ]
				ifNotNil: [ :code |
						authCode := code.
						authorizationCodeReceived signal.
						ZnResponse ok: (ZnEntity html:
								 '<html><body><h1>Authentication successful!</h1><p>You can close this window.</p></body></html>') ] ].
	[
		server start.
		WebBrowser openOn: self requestAuthorizationURL.
		authorizationCodeReceived waitTimeoutSeconds: 300 ] ensure: [
			server stop.
			authorizationCodeReceived := nil ].
	authCode ifNil: [ ^ nil ].
	self exchangeCodeForToken: authCode.
	self saveTokenToFile.
	^ accessToken
]

{ #category : 'oauth2 - pkce' }
LichessOAuth2Client >> base64UrlEncode: aByteArray [
	"Base64url encode without padding."

	| encoded |
	encoded := ZnBase64Encoder new encode: aByteArray.
	encoded := encoded reject: [ :c | c = $= ].
	^ encoded collect: [ :c |
			  c = $+
				  ifTrue: [ $- ]
				  ifFalse: [
						  c = $/
							  ifTrue: [ $_ ]
							  ifFalse: [ c ] ] ]
]

{ #category : 'oauth2' }
LichessOAuth2Client >> cancelAuthentication [
	"Stop waiting for the browser; a running authenticate answers nil"

	authorizationCodeReceived ifNotNil: [ :semaphore | semaphore signal ]
]

{ #category : 'accessing' }
LichessOAuth2Client >> clientId [

	^ clientId
]

{ #category : 'oauth2 - pkce' }
LichessOAuth2Client >> codeChallenge [
	"PKCE S256 challenge for the current code verifier."

	^ self base64UrlEncode:
		  (SHA256 new hashMessage: codeVerifier asByteArray)
]

{ #category : 'oauth2' }
LichessOAuth2Client >> exchangeCodeForToken: authCode [
	"Exchange authorization code for an access token using PKCE (public client)."

	| client body dict |
	client := ZnClient new.
	client url: 'https://lichess.org/api/token'.
	client method: #POST.
	body := 'grant_type=authorization_code' , '&code='
	        , authCode asString urlEncoded , '&redirect_uri='
	        , redirectUri urlEncoded , '&client_id='
	        , clientId urlEncoded , '&code_verifier='
	        , codeVerifier urlEncoded.
	client entity: (ZnEntity
			 with: body utf8Encoded
			 type: ZnMimeType applicationFormUrlEncoded).
	client execute.
	client isSuccess ifFalse: [
		^ LichessError signalForResponse: client response ].
	dict := STONJSON fromString: client contents.
	accessToken := dict at: 'access_token'.
	dict
		at: 'expires_in'
		ifPresent: [ :secs |
		tokenExpiresAt := DateAndTime now + secs asInteger seconds ].
	^ accessToken
]

{ #category : 'oauth2 - pkce' }
LichessOAuth2Client >> generateCodeVerifier [
	"Generate a PKCE code verifier (64 unreserved characters)."

	| chars random stream |
	chars := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~'.
	random := Random new.
	stream := WriteStream on: String new.
	64 timesRepeat: [
		stream nextPut: (chars at: (random nextInteger: chars size)) ].
	^ stream contents
]

{ #category : 'testing' }
LichessOAuth2Client >> hasValidToken [

	^ accessToken isNotNil and: [
		  tokenExpiresAt isNil or: [ tokenExpiresAt > DateAndTime now ] ]
]

{ #category : 'initialization' }
LichessOAuth2Client >> initialize [

	clientId := 'chess-coach-mvp'.
	redirectUri := 'http://localhost:8888/'
]

{ #category : 'initialization' }
LichessOAuth2Client >> initializeWithTokenFile: aFileReference [

	tokenFile := aFileReference.
	self loadTokenFromFile
]

{ #category : 'persistence' }
LichessOAuth2Client >> loadTokenFromFile [
	"Load the access token and username from the token file, if there is one"

	| dict |
	tokenFile exists ifFalse: [ ^ nil ].
	dict := STON fromString: tokenFile contents.
	accessToken := dict at: 'access_token' ifAbsent: [ nil ].
	username := dict at: 'username' ifAbsent: [ nil ].
	dict at: 'expires_at' ifPresent: [ :exp |
		exp ifNotNil: [ tokenExpiresAt := DateAndTime fromString: exp ] ].
	^ accessToken
]

{ #category : 'persistence' }
LichessOAuth2Client >> logout [
	"Forget the access token and username and delete the token file"

	accessToken := nil.
	tokenExpiresAt := nil.
	username := nil.
	tokenFile ensureDelete
]

{ #category : 'oauth2' }
LichessOAuth2Client >> requestAuthorizationURL [
	"Build the OAuth2 authorization URL with PKCE."

	| parts |
	codeVerifier := self generateCodeVerifier.
	parts := OrderedCollection new.
	parts add: 'client_id=' , clientId urlEncoded.
	parts add: 'redirect_uri=' , redirectUri urlEncoded.
	parts add: 'response_type=code'.
	parts add: 'code_challenge=' , self codeChallenge urlEncoded.
	parts add: 'code_challenge_method=S256'.
	^'https://lichess.org/oauth?' , (parts joinUsing: '&')
]

{ #category : 'persistence' }
LichessOAuth2Client >> saveTokenToFile [
	"Save the access token and username for reuse. Do nothing when there is no token."

	| dict |
	accessToken ifNil: [ ^ self ].
	tokenFile parent ensureCreateDirectory.
	dict := Dictionary new.
	dict at: 'access_token' put: accessToken.
	dict at: 'username' put: username.
	dict
		at: 'expires_at'
		put: (tokenExpiresAt ifNotNil: [ tokenExpiresAt asString ]).
	tokenFile
		ensureDelete;
		writeStreamDo: [ :stream | STON put: dict onStream: stream ]
]

{ #category : 'accessing' }
LichessOAuth2Client >> tokenFile [

	^ tokenFile
]

{ #category : 'accessing' }
LichessOAuth2Client >> username [
	"The Lichess account the token belongs to, saved with the token"

	^ username
]

{ #category : 'accessing' }
LichessOAuth2Client >> username: aString [
	"Remember the account the token belongs to and save it with the token"

	username := aString.
	self saveTokenToFile
]
