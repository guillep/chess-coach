"
I am a Toplo table for the pages of a Mamotreto app: columns sorted by the arrow in their header, which keep their widths when the table is first laid out in a hidden tab, and keep their order when the data is replaced (see resort).

	(MMTableElement new)
		columns: { MMTableElement column: 'Title' width: 300 value: [ :each | each title ] };
		yourself
"
Class {
	#name : 'MMTableElement',
	#superclass : 'ToTableElement',
	#category : 'Mamotreto-UI',
	#package : 'Mamotreto-UI'
}

{ #category : 'columns' }
MMTableElement class >> column: aTitle width: aNumber value: aBlock [
	"A column showing aBlock's value for each row, sorted by that value"

	^ ToTableColumn new
		  key: aTitle;
		  title: aTitle;
		  width: aNumber;
		  dataIndex: aBlock;
		  sorterBlock: aBlock;
		  yourself
]

{ #category : 'selection' }
MMTableElement >> beSingleSelection [
	"One row at a time. Set on the list's primary selection mode, not only on its selecter: Toplo asks the mode whether a list is multiple, and for a multiple one it delays a click on a selected row into another process (to tell it from a double click), which then changes the list outside the UI process"

	self list primarySelectionMode multiple: false
]

{ #category : 'initialization' }
MMTableElement >> initialize [
	"After each header layout, restore the column widths lost while the table was hidden, in a task so the layout isn't changed while it runs"

	super initialize.
	self useScrollbar: true.
	header
		addEventHandlerOn: BlElementLayoutComputedEvent
		do: [ :event |
				self enqueueTask:
					(BlTaskAction new action: [ self restoreColumnWidths ]) ]
]

{ #category : 'sorting' }
MMTableElement >> resort [
	"Sort the rows again as the headers say, after the data was replaced"

	self columns
		detect: [ :each |
		each sortOrder notNil and: [ each sorterBlock notNil ] ]
		ifFound: [ :column |
			self dispatchEvent: (ToTableColumnSortRequestEvent column: column) ]
]

{ #category : 'private' }
MMTableElement >> restoreColumnWidths [
	"Workaround: a Toplo table laid out in a hidden tab records 0 as its column widths (upstream/toplo-table-in-hidden-tab-repro.st). Once the table is shown, give each header cell its column's width again and let the rows follow"

	| containers |
	self width > 0 ifFalse: [ ^ self ].
	containers := header cellContainers.
	(containers anySatisfy: [ :each | each width = 0 ]) ifFalse: [
		^ self ].
	containers
		with: self columns
		do: [ :container :column | container updateWidthWith: column width ].
	list recordCellsWidth
]

{ #category : 'sorting' }
MMTableElement >> sortButtonOf: aTitle [
	"The arrow in the header of the column with that title"

	| index |
	index := self columns findFirst: [ :each | each title = aTitle ].
	(header cellContainers at: index) allChildrenBreadthFirstDo: [ :each |
		(each isKindOf: ToIconicArrowButton) ifTrue: [ ^ each ] ].
	^ NotFound signalFor: aTitle
]
