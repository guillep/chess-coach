"
Manages OAuth2 authentication with Lichess. Handles authorization code flow, token exchange, and token refresh.
"
Class {
	#name : 'LichessOAuth2Client',
	#superclass : 'Object',
	#instVars : [
		'clientId',
		'clientSecret',
		'redirectUri',
		'accessToken',
		'tokenExpiresAt',
		'codeVerifier'
	],
	#category : 'ChessCoach-LichessImport',
	#package : 'ChessCoach-LichessImport'
}

{ #category : 'accessing' }
LichessOAuth2Client >> accessToken [

	^ accessToken
]

{ #category : 'oauth2' }
LichessOAuth2Client >> authenticate [
	"Authenticate and return the access token."

	| sem server authCode url |
	(accessToken isNotNil and: [ self hasValidToken ]) ifTrue: [
		^ accessToken ].
	[
		authCode := nil.
		sem := Semaphore new.
		server := ZnServer on: 8888.
		server onRequestRespond: [ :request |
				| code |
				code := [ request uri queryAt: #code ]
					        on: Error
					        do: [ nil ].
				code
					ifNotNil: [
							authCode := code.
							sem signal.
							ZnResponse ok: (ZnEntity html:
									 '<html><body><h1>Authentication successful!</h1><p>You can close this window.</p></body></html>') ]
					ifNil: [
							ZnResponse badRequest: (ZnEntity html:
									 '<html><body><h1>Error</h1><p>No authorization code received.</p></body></html>') ] ].
		server start.
		url := self requestAuthorizationURL.
		WebBrowser openOn: url.

		sem waitTimeoutSeconds: 300 ] ensure: [ server stop ].
	authCode ifNil: [ ^ nil ].
	^ self exchangeCodeForToken: authCode
]

{ #category : 'private' }
LichessOAuth2Client >> base64Encode: aString [
	"Encode string to Base64"

	^ ZnBase64Encoder new encode: aString asByteArray
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
LichessOAuth2Client >> buildQueryString: aDictionary [

	| stream |
	stream := WriteStream on: String new.
	aDictionary associations
		do: [ :assoc |
				stream
					nextPutAll: assoc key urlEncoded;
					nextPut: $=;
					nextPutAll: assoc value asString urlEncoded ]
		separatedBy: [ stream nextPut: $& ].
	^ stream contents
]

{ #category : 'oauth2' }
LichessOAuth2Client >> buildQueryStringNoEncodeScope: aDictionary [

	| stream |
	stream := WriteStream on: String new.
	aDictionary associations
		do: [ :assoc |
				stream
					nextPutAll: assoc key urlEncoded;
					nextPut: $=.
				assoc key = 'scope'
					ifTrue: [ stream nextPutAll: assoc value asString ]
					ifFalse: [ stream nextPutAll: assoc value asString urlEncoded ] ]
		separatedBy: [ stream nextPut: $& ].
	^ stream contents
]

{ #category : 'accessing' }
LichessOAuth2Client >> clientId [

	^ clientId
]

{ #category : 'accessing' }
LichessOAuth2Client >> clientSecret [

	^ clientSecret
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

	| client body data dict |

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
	data := client contents.
	dict := STONJSON fromString: data.
	accessToken := dict at: 'access_token' ifAbsent: [ nil ].

	dict
		at: 'expires_in'
		ifPresent: [ :secs |
			tokenExpiresAt := DateAndTime now + secs asInteger seconds ].

	accessToken ifNil: [
		self error: 'Token exchange failed: ' , data asString].
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
	clientSecret := ''.
	redirectUri := 'http://localhost:8888/'.
	self loadTokenFromFile.
	^ self
]

{ #category : 'persistence' }
LichessOAuth2Client >> loadTokenFromFile [
	"Load access token from disk"

	| tokenFile dict |
	tokenFile := FileLocator home / '.config' / 'chess-coach'
	             / 'lichess-token.json'.
	tokenFile exists ifFalse: [ ^ nil ].
	dict := STON fromString: tokenFile readStream upToEnd.
	accessToken := dict at: 'access_token' ifAbsent: [ nil ].
	(dict at: 'expires_at' ifAbsent: [ nil ]) ifNotNil: [ :exp |
		tokenExpiresAt := DateAndTime fromString: exp ].
	^ accessToken
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
	"Save access token to disk for reuse. Do nothing when there is no token."

	| tokenFile dict |
	accessToken ifNil: [ ^ self ].
	tokenFile := FileLocator home / '.config' / 'chess-coach'
	             / 'lichess-token.json'.
	tokenFile parent ensureCreateDirectory.
	dict := Dictionary new.
	dict at: 'access_token' put: accessToken.
	dict
		at: 'expires_at'
		put: (tokenExpiresAt ifNotNil: [ tokenExpiresAt asString ]).
	tokenFile writeStreamDo: [ :stream |
		stream nextPutAll: (STON toString: dict) ]
]

{ #category : 'private' }
LichessOAuth2Client >> urlEncode: aString [

	^ aString asString urlEncoded
]
