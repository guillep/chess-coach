"
I am the window of a Mamotreto app: a title bar (the name, Update, help with the version, the notification bell), the pages in a rail of fixed-width tabs on the left, closable pages after them, and a status bar with background work, errors and the credits. Lines separate the bars, with no gaps and no app margin.
I listen to my MMSession; I never poll it. Work off the UI thread goes through runInBackground:, which reports in the status bar.
An app subclasses me: it answers appName and newNavigation (its pages), and may add to the status bar, react to settings, say which notifications have a Show action and what to do when the window opens.
"
Class {
	#name : 'MMWindow',
	#superclass : 'ToElement',
	#instVars : [
		'session',
		'navigation',
		'statusLabel',
		'bell',
		'bellBadge',
		'notificationsWindow',
		'updateButton',
		'backgroundRunner',
		'app',
		'updatesButton',
		'refreshBlock'
	],
	#category : 'Mamotreto-UI-Window',
	#package : 'Mamotreto-UI',
	#tag : 'Window'
}

{ #category : 'instance creation' }
MMWindow class >> app: anApp [
	"A window for anApp; the app is set before initialize, which builds its pages"

	^ self basicNew
		  setApp: anApp;
		  initialize;
		  yourself
]

{ #category : 'instance creation' }
MMWindow class >> defaultApp [
	"The app of a window made with new; subclasses for one app answer it"

	^ self subclassResponsibility
]

{ #category : 'instance creation' }
MMWindow class >> new [

	^ self app: self defaultApp
]

{ #category : 'opening' }
MMWindow class >> openApp: anApp on: aSession [
	"Open maximized on aSession; closing the window asks first while background jobs run, then shuts the session down"

	| window space |
	window := (self app: anApp)
		          session: aSession;
		          yourself.
	space := MMSpace new.
	space title: anApp name.
	space extent: 1200 @ 760.
	space root addChild: window.
	space whenCloseRequestedDo: [ window closeRequestedIn: space ].
	space
		addEventHandlerOn: BlSpaceClosedEvent
		do: [ :event | aSession shutDown ].
	space show.
	space maximize.
	window opened.
	aSession startScheduledChecks.
	^ window
]

{ #category : 'opening' }
MMWindow class >> openOn: aSession [
	"Open the default app's window on aSession"

	^ self openApp: self defaultApp on: aSession
]

{ #category : 'instance creation' }
MMWindow class >> session: aSession [

	^ self new
		  session: aSession;
		  yourself
]

{ #category : 'updating' }
MMWindow class >> updateOpenAppTo: aTagName [
	"For testing updates of a packaged app: <the app's window class> updateOpenAppTo: 'v1.2.3'"

	(self allInstances detect: [ :each | each isAttachedToSceneGraph ])
		updateAppTo: aTagName
]

{ #category : 'accessing' }
MMWindow >> app [

	^ app
]

{ #category : 'app' }
MMWindow >> appName [
	"The name in the title bar"

	^ app name
]

{ #category : 'theme' }
MMWindow >> applyAppTheme [
	"The background and the tint of the icons outside buttons from the app's palette, light or dark as the settings say, also for hidden pages and icons built later"

	| dark palette tint |
	dark := session settings appTheme = 'Dark'.
	palette := app palette.
	self background: (palette at: (dark
				  ifTrue: [ #darkBackground ]
				  ifFalse: [ #lightBackground ])).
	tint := palette at: (dark
			         ifTrue: [ #darkText ]
			         ifFalse: [ #lightText ]).
	MMWidgets iconColor: tint.
	self pageRoots do: [ :root |
			root allChildrenBreadthFirstDo: [ :each |
					((each isKindOf: ToImage) and: [
							 (each anyInParentsSatisfy: [ :ancestor |
								  ancestor isKindOf: ToButton ]) not ]) ifTrue: [
						each innerImageColor: tint ] ] ]
]

{ #category : 'background work' }
MMWindow >> backgroundRunner [
	"The guarded runner the pages use"

	^ backgroundRunner
]

{ #category : 'background work' }
MMWindow >> backgroundRunner: aBlock [
	"aBlock receives the work block to run; tests pass [ :work | work value ]. Every page gets this runner, and every block it runs is guarded (see runGuarded:), so that no page can leave an error unhandled in a background process."

	backgroundRunner := [ :work |
	                    aBlock value: [ self runGuarded: work ] ]
]

{ #category : 'accessing' }
MMWindow >> bell [

	^ bell
]

{ #category : 'accessing' }
MMWindow >> bellBadge [

	^ bellBadge
]

{ #category : 'navigation' }
MMWindow >> closeButtonDo: aBlock [
	"The close button at the top right of a closable page's title"

	^ ToButton new
		  icon: ((ToMaterialDesignIconProvider iconNamed: 'outlined_close')
				   extent: 18 @ 18;
				   yourself);
		  tooltipString: 'Close this page';
		  clickAction: aBlock;
		  yourself
]

{ #category : 'closing' }
MMWindow >> closeRequestedIn: aSpace [
	"The user closed the window: close it, unless background jobs would be stopped; then ask first, in a banner below the title bar. Stopping them cannot be taken back, so that button is red."

	| count |
	count := session unfinishedTaskCount.
	count = 0 ifTrue: [ ^ aSpace close ].
	(self childWithId: #closeBanner ifNone: [ nil ]) ifNotNil: [ ^ self ].
	self
		addChild: (ToElement new
				 id: #closeBanner;
				 layout:
					 (BlLinearLayout horizontal alignCenterLeft cellSpacing: 8);
				 hMatchParent;
				 vFitContent;
				 padding: MMWidgets titleBarPadding;
				 background: (Color fromHexString: '#fff8c5');
				 addChild: (ToLabel text: (count = 1
								   ifTrue: [ '1 task is still running.' ]
								   ifFalse: [ count printString , ' tasks are still running.' ])
							  , ' Close anyway?');
				 addChild: (ToButton new
						  labelText: 'Wait';
						  clickAction: [
							  (self childWithId: #closeBanner) removeFromParent ];
						  yourself);
				 addChild: (MMWidgets
						  dangerButton: 'Close and stop them'
						  icon: 'outlined_close'
						  do: [ aSpace close ]);
				 yourself)
		at: 2
]

{ #category : 'navigation' }
MMWindow >> closeTab: aTabButton [

	aTabButton ifNil: [ ^ self ].
	navigation removeItem: aTabButton
]

{ #category : 'testing' }
MMWindow >> hasUpdatesAvailable [

	^ updatesButton visibility isVisible
]

{ #category : 'background work' }
MMWindow >> inUIDo: aBlock [

	self enqueueTask: (BlTaskAction new action: aBlock)
]

{ #category : 'initialization' }
MMWindow >> initialize [
	"A title bar with the bell, and left of it Updates available while the shown page is outdated; below it the pages in a tab pane with the tabs in a left column, and a status line, set apart by lines. I have no margin: the pages have their own."

	super initialize.
	backgroundRunner := [ :work |
	                    [ self runGuarded: work ] forkAt:
		                    Processor userBackgroundPriority ].
	refreshBlock := [ ].
	self layout: BlLinearLayout vertical.
	self matchParent.
	navigation := self newNavigation.
	self
		addChild: (ToElement new
				 id: #topBar;
				 layout:
					 (BlLinearLayout horizontal alignCenterLeft cellSpacing: 8);
				 hMatchParent;
				 vFitContent;
				 padding: MMWidgets titleBarPadding;
				 addChild: self newUpdatesButton;
				 addChild: self newBell;
				 yourself);
		addChild: self newBarLine;
		addChild: navigation;
		addChild: self newBarLine;
		addChild: self newStatusLine
]

{ #category : 'app' }
MMWindow >> isExpectedError: anError [
	"Errors shown in the status bar without going to errors.log"

	^ anError isKindOf: NetworkError
]

{ #category : 'notifications' }
MMWindow >> maxNotificationsHeight [
	"The notifications never take more than 70% of the window's height"

	^ (self height * 0.7) rounded max: 200
]

{ #category : 'accessing' }
MMWindow >> navigation [

	^ navigation
]

{ #category : 'initialization' }
MMWindow >> newBarLine [
	"A separator that touches what it separates: the bars and the tabs have no gap between them."

	^ MMWidgets separator
		  margin: BlInsets empty;
		  yourself
]

{ #category : 'initialization' }
MMWindow >> newBell [
	"The notification bell, with a red dot while there are unread notifications. Clicking it pops up the notifications below it, to its left (they would leave the window otherwise), and marks them read.
	The popup stays open on mouse up (a menu would close), so its buttons get their clicks"

	bellBadge := BlElement new
		             geometry: BlCircleGeometry new;
		             extent: 10 @ 10;
		             background: (Color fromHexString: '#dc2626');
		             visibility: BlVisibility hidden;
		             constraintsDo: [ :c |
				             c frame horizontal alignRight.
				             c frame vertical alignTop ];
		             yourself.
	bell := ToButton new
		        id: #notifications;
		        icon:
			        ((ToMaterialDesignIconProvider iconNamed:
					          'outlined_notifications')
				         extent: 24 @ 24;
				         yourself);
		        tooltipText: 'Notifications';
		        yourself.
	notificationsWindow := ToPopupWindowManager new.
	notificationsWindow placement: ToAnchoredBottomLeftPlacement new.
	notificationsWindow closeOnReleased: false.
	notificationsWindow windowBuilder: [ :window :element |
			window root addChild: self newNotificationsPanel.
			session notifications markAllRead ].
	bell addEventHandler: notificationsWindow.
	^ ToElement new
		  layout: BlFrameLayout new;
		  fitContent;
		  addChild: bell;
		  addChild: bellBadge;
		  yourself
]

{ #category : 'initialization' }
MMWindow >> newBrand [
	"The name at the left of the title bar; the logo is the Home tab"

	^ ToElement new
		  layout: BlLinearLayout horizontal alignCenterLeft;
		  hMatchParent;
		  vFitContent;
		  addChild: (ToLabel new
				   text: (self appName asRopedText
						    fontSize: 20;
						    bold;
						    yourself);
				   yourself);
		  yourself
]

{ #category : 'app' }
MMWindow >> newNavigation [
	"The app's pages in a Toplo tab pane, tabs in a column on the left. Pages are built once and kept; closable pages open after them. The tab group's menus are hidden until tabs overflow, so the skin's padding around them would only cut the column short. Closing a tab can be undone (the page opens again), so its close button gets no red border on hover."

	| pane |
	pane := ToTabPaneElement new.
	pane horizontal: true.
	pane matchParent.
	pane showAddTabItemButton: false.
	pane tabGroup addTokenNamed: #'padding-content-V' withValue: 0.
	pane tabGroup itemList
		addTokenNamed: #'padding-content-V'
		withValue: 6.
	pane tabGroup
		addTokenNamed: #'border-color-danger-selection'
		withValue: Color transparent.
	app pages do: [ :each | pane addItem: (each tabIn: self) ].
	pane
		addEventHandlerOn: ToItemRemovedFromListEvent
		do: [ :event |
		self tabClosed: event item wasSelected: event wasSelected ].
	^ pane
]

{ #category : 'notifications' }
MMWindow >> newNotificationRow: aNotification in: aPanel [
	"A row of the notification center; Show closes the panel before acting"

	^ MMWidgets
		  notificationRow: aNotification
		  time: (self timeTextFor: aNotification time)
		  onDismiss: [ :row |
				  session notifications dismiss: aNotification.
				  aPanel removeChild: row ]
		  onShow:
			  ((self showActionFor: aNotification) ifNotNil: [ :action |
					   [
						   notificationsWindow currentWindow ifNotNil: [ :window |
							   window close ].
						   action value ] ])
]

{ #category : 'notifications' }
MMWindow >> newNotificationsPanel [
	"The notifications, newest first, each with its action and a dismiss button, in a list that scrolls once it reaches 70% of the window's height; below it, always there, Clear all, disabled when there is nothing to clear"

	| list visible scrollable clearAll |
	list := ToElement new
		        id: #notificationList;
		        layout: (BlLinearLayout vertical cellSpacing: 8);
		        hMatchParent;
		        vFitContent;
		        padding: (BlInsets all: 12);
		        yourself.
	visible := session notifications visible.
	visible
		ifEmpty: [ list addChild: (ToLabel text: self quietText) ]
		ifNotEmpty: [
				visible
					do: [ :each |
					list addChild: (self newNotificationRow: each in: list) ]
					separatedBy: [ list addChild: MMWidgets separator ] ].
	scrollable := list asScrollableElement.
	scrollable constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent.
			c maxHeight: self maxNotificationsHeight ].
	clearAll := ToButton new
		            id: #clearNotifications;
		            labelText: 'Clear all';
		            enabled: visible notEmpty;
		            clickAction: [
				            session notifications dismissAll.
				            notificationsWindow currentWindow ifNotNil: [ :window |
						            window close ] ];
		            yourself.
	^ ToElement new
		  id: #notificationsPanel;
		  layout: BlLinearLayout vertical;
		  width: 360;
		  vFitContent;
		  addChild: scrollable;
		  addChild: MMWidgets separator;
		  addChild: (ToElement new
				   layout: BlLinearLayout horizontal;
				   hMatchParent;
				   vFitContent;
				   padding: (BlInsets all: 8);
				   addChild: clearAll;
				   yourself);
		  yourself
]

{ #category : 'navigation' }
MMWindow >> newPageButton: aString icon: anIconName page: anElement [
	"A square tab of a fixed width, so that a long name doesn't move the pages: a large Material Design icon above a small label"

	^ ToTabButton new
		  id: aString asSymbol;
		  labelText: aString;
		  icon: ((ToMaterialDesignIconProvider iconNamed: anIconName)
				   extent: MMWidgets tabIconExtent;
				   yourself);
		  beVertical;
		  width: MMWidgets tabWidth;
		  removable: false;
		  paneBuilder: [ :pane :button :holder | pane addChild: anElement ];
		  yourself
]

{ #category : 'initialization' }
MMWindow >> newStatusLine [
	"Background work and errors, then the app's own labels, shared by every page; the credits at the right"

	| line |
	statusLabel := ToLabel text: ''.
	line := ToElement new
		        layout: (BlLinearLayout horizontal cellSpacing: 16);
		        hMatchParent;
		        vFitContent;
		        padding: MMWidgets statusBarPadding;
		        addChild: statusLabel;
		        yourself.
	self statusLineExtras do: [ :each | line addChild: each ].
	^ line
		  addChild: (BlElement new
				   constraintsDo: [ :c |
						   c horizontal matchParent.
						   c vertical exact: 1 ];
				   yourself);
		  addChild: MMWidgets credits;
		  yourself
]

{ #category : 'initialization' }
MMWindow >> newUpdatesButton [
	"Shown only while what the page shows effectively changed in the background: the page is never redrawn behind the user's back, so the selection stays. Clicking it redraws the page."

	updatesButton := MMWidgets
		                 primaryButton: 'Updates available'
		                 icon: 'outlined_refresh'
		                 do: [ self refreshShownPage ].
	updatesButton
		id: #updatesButton;
		tooltipText: 'Refresh this page with the new data';
		visibility: BlVisibility gone.
	^ updatesButton
]

{ #category : 'accessing' }
MMWindow >> notificationsWindow [

	^ notificationsWindow
]

{ #category : 'navigation' }
MMWindow >> openTab: aString icon: anIconName page: anElement [
	"Add a closable page after the fixed ones and show it. Its name is cut to fit the tab."

	| button |
	button := (self
		           newPageButton: (aString truncateTo: 11)
		           icon: anIconName
		           page: anElement)
		          removable: true;
		          yourself.
	navigation addItem: button.
	self showTab: button.
	^ button
]

{ #category : 'app' }
MMWindow >> opened [
	"The window is shown; apps start their background work here"

	
]

{ #category : 'navigation' }
MMWindow >> pageButton: aPageId [

	^ navigation items asArray detect: [ :each | each id = aPageId ]
]

{ #category : 'theme' }
MMWindow >> pageRoots [
	"Where to look for icons to tint: me, and pages that are not attached while hidden"

	^ { self }
]

{ #category : 'app' }
MMWindow >> quietText [
	"What the notification panel says when it is empty"

	^ 'All quiet.'
]

{ #category : 'updating' }
MMWindow >> refreshShownPage [

	updatesButton visibility: BlVisibility gone.
	refreshBlock value
]

{ #category : 'background work' }
MMWindow >> runGuarded: aBlock [
	"Run background work so that a failure never escapes its process: in a packaged app an unhandled error in a background process quits the app. Expected errors (see isExpectedError:) are shown in the status line; any other error is shown too and appended to errors.log."

	[ aBlock value ]
		on: Error
		do: [ :error |
				(self isExpectedError: error) ifFalse: [
					session ifNotNil: [ session logError: error ] ].
				self inUIDo: [
						statusLabel text: ((self isExpectedError: error)
								 ifTrue: [ error messageText ]
								 ifFalse: [
										 'Something went wrong: ' , error class name , ': '
										 , (error messageText ifNil: [ '' ]) asString
										 , ' (details in errors.log)' ]) ] ]
]

{ #category : 'background work' }
MMWindow >> runInBackground: aBlock [
	"Run work off the UI thread and show its progress. Expected errors (see isExpectedError:) are shown in the status line; any other error is shown too and appended to errors.log, instead of opening a debugger."

	statusLabel text: 'Working…'.
	backgroundRunner value: [
			[
				aBlock value.
				self inUIDo: [ statusLabel text: '' ] ]
				on: Error
				do: [ :error |
						(self isExpectedError: error) ifFalse: [
							session logError: error ].
						self inUIDo: [
								statusLabel text: ((self isExpectedError: error)
										 ifTrue: [ error messageText ]
										 ifFalse: [
												 'Something went wrong: ' , error class name , ': '
												 , (error messageText ifNil: [ '' ]) asString
												 , ' (details in errors.log)' ]) ] ] ]
]

{ #category : 'accessing' }
MMWindow >> session [

	^ session
]

{ #category : 'accessing' }
MMWindow >> session: aSession [
	"Connect to the session: the Update button and the version in the title bar, the theme, and listen to the notifications and the settings. The theme is applied again when I am added to a space."

	session := aSession.
	updateButton := MMWidgets
		                primaryButton: 'Update'
		                icon: 'filled_arrowforward'
		                do: [ self updateApp ].
	(self childWithId: #topBar)
		addChildFirst: updateButton;
		addChildFirst: self newBrand;
		addChild: (MMWidgets help: self appName , ' ' , session appVersion)
		at: 3.
	session announcer
		when: MMNotificationsChanged
		do: [ :announcement | self inUIDo: [ self updateBell ] ]
		for: self.
	session announcer
		when: MMSettingsChanged
		do: [ :announcement |
			self inUIDo: [ self settingChanged: announcement key ] ]
		for: self.
	self
		addEventHandlerOn: BlElementAddedToSceneGraphEvent
		do: [ :event | self applyAppTheme ].
	self applyAppTheme.
	self updateBell
]

{ #category : 'initialization' }
MMWindow >> setApp: anApp [

	app := anApp
]

{ #category : 'app' }
MMWindow >> settingChanged: aKey [
	"A setting changed; called in the UI thread. Apps apply theirs, after calling me."

	aKey = 'appTheme' ifTrue: [ self applyAppTheme ]
]

{ #category : 'app' }
MMWindow >> showActionFor: aNotification [
	"The block of its Show button, or nil for none"

	^ nil
]

{ #category : 'navigation' }
MMWindow >> showPage: aPageId [
	"The page whose tab has aPageId, its name as a symbol"

	navigation selecter selectIndex:
		(navigation items asArray findFirst: [ :each | each id = aPageId ])
]

{ #category : 'navigation' }
MMWindow >> showTab: aTabButton [

	navigation selecter selectIndex:
		(navigation items asArray indexOf: aTabButton)
]

{ #category : 'updating' }
MMWindow >> showUpdatesAvailable [
	"In the UI thread: what the shown page shows changed"

	updatesButton visibility: BlVisibility visible
]

{ #category : 'accessing' }
MMWindow >> statusLabel [

	^ statusLabel
]

{ #category : 'app' }
MMWindow >> statusLineExtras [
	"Labels of the app shown after the status in the status bar"

	^ #(  )
]

{ #category : 'navigation' }
MMWindow >> tabClosed: aTabButton wasSelected: aBoolean [
	"A closable page was closed, from its tab or from its own close button; apps go back to the page it came from"

	
]

{ #category : 'notifications' }
MMWindow >> timeTextFor: aDateAndTime [
	"Today's notifications show their time, older ones their date"

	^ aDateAndTime asDate = Date today
		  ifTrue: [ aDateAndTime asTime print24 first: 5 ]
		  ifFalse: [ aDateAndTime asDate yyyymmdd ]
]

{ #category : 'updates' }
MMWindow >> updateApp [
	"Ask in the title bar before updating: the button makes way for the question"

	| tag question bar |
	tag := session availableUpdate.
	bar := updateButton parent.
	question := ToElement new
		            layout:
			            (BlLinearLayout horizontal alignCenterLeft
				             cellSpacing: 8);
		            fitContent;
		            yourself.
	question
		addChild:
			(ToLabel text: 'Install ' , tag , '? The app will restart.');
		addChild: (MMWidgets
				 primaryButton: 'Update'
				 icon: 'filled_arrowforward'
				 do: [ self updateAppTo: tag ]);
		addChild: (ToButton new
				 labelText: 'Cancel';
				 clickAction: [ bar replaceChild: question with: updateButton ];
				 yourself).
	bar replaceChild: updateButton with: question
]

{ #category : 'updates' }
MMWindow >> updateAppTo: aTagName [
	"Install the release aTagName on the background worker, with the window open. The updater quits once the swap is started and the new version opens by itself; if the update fails, say so and keep running."

	self runInBackground: [
			session updater updateTo: aTagName ifFailed: [ :error |
					session logError: error.
					self inUIDo: [
							session notifications post: (MMNotification
									 key: 'error-Update'
									 kind: #error
									 title: 'Update failed'
									 text:
									 (error messageText ifNil: [ error class name ]) asString) ] ] ]
]

{ #category : 'notifications' }
MMWindow >> updateBell [
	"Show the red dot while there are unread notifications. The Update button is always there, enabled while a newer version exists"

	bellBadge visibility: (session notifications unreadCount > 0
			 ifTrue: [ BlVisibility visible ]
			 ifFalse: [ BlVisibility hidden ]).
	session availableUpdate
		ifNil: [
				updateButton
					labelText: 'Update';
					tooltipText: 'You have the latest version';
					enabled: false ]
		ifNotNil: [ :tag |
				updateButton
					labelText: 'Update to ' , tag;
					tooltipText:
						'Install ' , tag , '. The window closes and opens again.';
					enabled: true ]
]

{ #category : 'accessing' }
MMWindow >> updateButton [

	^ updateButton
]

{ #category : 'updating' }
MMWindow >> whenRefreshedDo: aBlock [
	"The page now shown: it draws the current data, so it is up to date, and Refresh redraws it with aBlock"

	refreshBlock := aBlock.
	updatesButton visibility: BlVisibility gone
]
