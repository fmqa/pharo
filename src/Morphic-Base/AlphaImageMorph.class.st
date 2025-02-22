"
Displays an image with the specified alpha value (translucency) and optional scale and layout (scaled, top-right etc.).



"
Class {
	#name : #AlphaImageMorph,
	#superclass : #ImageMorph,
	#instVars : [
		'alpha',
		'cachedForm',
		'layout',
		'scale',
		'enabled',
		'autoSize',
		'getImageSelector',
		'model'
	],
	#classVars : [
		'DefaultImage'
	],
	#category : #'Morphic-Base-Basic'
}

{ #category : #'instance creation' }
AlphaImageMorph class >> defaultImage: aForm [
	"Set the default image used for new instances of the receiver."

	DefaultImage := aForm
]

{ #category : #accessing }
AlphaImageMorph >> alpha [
	"Answer the value of alpha"

	^ alpha
]

{ #category : #accessing }
AlphaImageMorph >> alpha: anObject [
	"Set the value of alpha"

	alpha := anObject.
	self
		cachedForm: nil;
		changed;
		changed: #alpha
]

{ #category : #accessing }
AlphaImageMorph >> autoSize [
	"Answer the value of autoSize"

	^ autoSize
]

{ #category : #accessing }
AlphaImageMorph >> autoSize: anObject [
	"Set the value of autoSize"

	autoSize := anObject
]

{ #category : #accessing }
AlphaImageMorph >> cachedForm [
	"Answer the value of cachedForm"
	
	|form i effectiveAlpha|
	cachedForm ifNil: [
		i := self scaledImage.
		effectiveAlpha := self enabled
			ifTrue: [self alpha]
			ifFalse: [self alpha / 2].
		effectiveAlpha = 1.0
			ifTrue: [self cachedForm: i]
			ifFalse: [form := Form extent: i extent depth: 32.
					form fillColor: (Color white alpha: 0.003922).
					(form getCanvas asAlphaBlendingCanvas: effectiveAlpha)
						drawImage: i
					at: 0@0.
					self cachedForm: form]].
	^cachedForm
]

{ #category : #accessing }
AlphaImageMorph >> cachedForm: anObject [
	"Set the value of cachedForm"

	cachedForm := anObject
]

{ #category : #initialization }
AlphaImageMorph >> defaultColor [
	"Answer the default color for the receiver."

	^Color transparent
]

{ #category : #initialization }
AlphaImageMorph >> defaultImage [
	"Answer the default image for the receiver."

	^DefaultImage ifNil: [DefaultImage := DefaultForm asFormOfDepth: 32]
]

{ #category : #geometry }
AlphaImageMorph >> displayBounds [
	"Answer a rectangle in display coordinates that
	bounds the image (may be larger/smaller than visible area).
	Just one rep for the tiled case."

	^self layoutPosition extent: self cachedForm extent
]

{ #category : #drawing }
AlphaImageMorph >> drawOn: aCanvas [
	"Draw with the current alpha
	Can't do simple way since BitBlt rules are dodgy!."
	
	aCanvas fillRectangle: self bounds fillStyle: self fillStyle borderStyle: self borderStyle.
	(self cachedForm width = 0 or: [self cachedForm height = 0]) ifTrue: [^self].
	self layout == #tiled
		ifTrue: [aCanvas fillRectangle: self innerBounds fillStyle: (AlphaInfiniteForm with: self cachedForm)]
		ifFalse: [aCanvas clipBy: self innerBounds during: [:c |
					c translucentImage: self cachedForm at: self layoutPosition]]
]

{ #category : #accessing }
AlphaImageMorph >> enabled [
	"Answer the value of enabled"

	^enabled
]

{ #category : #accessing }
AlphaImageMorph >> enabled: anObject [
	"Set the value of enabled"

	enabled := anObject.
	self
		cachedForm: nil;
		changed
]

{ #category : #geometry }
AlphaImageMorph >> extent: aPoint [
	"Allow as normal."
	
	self basicExtent: aPoint.
	
	(self layout = #scaled or: [self layout = #scaledAspect]) ifTrue: [self cachedForm: nil]
]

{ #category : #accessing }
AlphaImageMorph >> getImageSelector [

	^ getImageSelector
]

{ #category : #accessing }
AlphaImageMorph >> getImageSelector: anObject [

	getImageSelector := anObject
]

{ #category : #accessing }
AlphaImageMorph >> image: anImage [ 
	"Clear the cached form."
	
	^self image: anImage size: anImage extent
]

{ #category : #accessing }
AlphaImageMorph >> image: aForm size: aPoint [
	"Set the image to be the form scaled to the given size and padded if neccesary."

	|f|
	"Convert color forms etc. to 32 bit before resizing since scaling of ColorForm introduces degraded color resolution.
	Most noticable with grayscale forms."
	(aForm depth < 32 and: [aForm depth > 4])
		ifTrue: [f := Form extent: aPoint depth: 32.
				f fillColor: (Color white alpha: 0.003922).
				f getCanvas translucentImage: aForm at: 0@0.
				f fixAlpha]
		ifFalse: [f := aForm].
	f := f scaledToSize: aPoint.
	self autoSize
		ifTrue: [super image: f]
		ifFalse: [image := f.
				self changed].
	self cachedForm: nil.
	self changed: #imageExtent
]

{ #category : #accessing }
AlphaImageMorph >> imageExtent [
	"Answer the extent of the original form."

	^self form extent
]

{ #category : #geometry }
AlphaImageMorph >> imageRectangleFromDisplayRectangle: aRectangle [
	"Answer a rectangle in (original) image coordinates that
	corresponds to the given rectangle (in relative display coordinates)."

	|db|
	db := self displayBounds .
	db area = 0 ifTrue: [^db].
	self layout == #scaledAspect ifTrue: [
		^((aRectangle translateBy: self layoutPosition negated)
			scaleBy: self form width / db width) rounded].
	self layout == #scaled ifTrue: [
		^((aRectangle translateBy: self layoutPosition negated)
			scaleBy: (self form width / db width) @ (self form height / db height)) rounded].
	^self scale = 1
		ifTrue: [aRectangle translateBy: self layoutPosition negated]
		ifFalse: [((aRectangle translateBy: self layoutPosition negated)
					scaleBy: 1 / self scale) rounded]
]

{ #category : #initialization }
AlphaImageMorph >> initialize [
	"Initialize the receiver.
	Use the 32 bit depth default image to avoid
	unnecessary conversions."

	enabled := true.
	autoSize := true.
	scale := 1.0.
	layout := #topLeft.
	alpha := 1.0.
	super initialize
]

{ #category : #accessing }
AlphaImageMorph >> layout [
	"Answer the value of layout"

	^ layout
]

{ #category : #accessing }
AlphaImageMorph >> layout: aSymbol [
	"Set the value of layout"

	|old|
	(old := layout) = aSymbol ifTrue: [^self].
	layout := aSymbol.
	((old = #scaled or: [old = #scaledAspect]) or: [aSymbol = #scaled or: [aSymbol = #scaledAspect]])
		ifTrue: [self cachedForm: nil].
	self changed
]

{ #category : #geometry }
AlphaImageMorph >> layoutPosition [
	"Answer the position that the cached form should be drawn
	based on the layout"
	
	self layout == #topCenter ifTrue: [^self innerBounds topCenter - (self cachedForm width // 2 @ 0)].
	self layout == #topRight ifTrue: [^self innerBounds topRight - (self cachedForm width @ 0)].
	self layout == #rightCenter ifTrue: [^self innerBounds rightCenter - (self cachedForm width @ (self cachedForm height // 2))].
	self layout == #bottomRight ifTrue: [^self innerBounds bottomRight - self cachedForm extent].
	self layout == #bottomCenter ifTrue: [^self innerBounds bottomCenter - (self cachedForm width // 2 @ self cachedForm height)].
	self layout == #bottomLeft ifTrue: [^self innerBounds bottomLeft - (0 @ self cachedForm height)].
	self layout == #leftCenter ifTrue: [^self innerBounds leftCenter - (0 @ (self cachedForm height // 2))].
	(self layout == #center or: [self layout == #scaledAspect]) ifTrue: [^self innerBounds center - (self cachedForm extent // 2)].
	^self innerBounds topLeft
]

{ #category : #accessing }
AlphaImageMorph >> layoutSymbols [
	"Answer the available layout options."

	^#(#center #tiled #scaled #scaledAspect
		#topLeft #topCenter #topRight #rightCenter
		#bottomRight #bottomCenter #bottomLeft #leftCenter)
]

{ #category : #accessing }
AlphaImageMorph >> model [

	^ model
]

{ #category : #accessing }
AlphaImageMorph >> model: anObject [
	"Set my model and make me me a dependent of the given object."

	model ifNotNil: [model removeDependent: self].
	anObject ifNotNil: [anObject addDependent: self].
	model := anObject
]

{ #category : #geometry }
AlphaImageMorph >> optimalExtent [
	"Answer the optimal extent for the receiver."
	
	^self form extent * self scale + (self borderWidth * 2)
]

{ #category : #accessing }
AlphaImageMorph >> scale [
	"Answer the value of scale"

	^ scale
]

{ #category : #accessing }
AlphaImageMorph >> scale: aNumber [
	"Set the value of scale"

	scale = aNumber ifTrue: [^self].
	scale := aNumber.
	self
		cachedForm: nil;
		changed;
		changed: #scale
]

{ #category : #accessing }
AlphaImageMorph >> scaledImage [
	"Answer the image scaled as required."
	
	|i|
	i := self form.
	i boundingBox area = 0 ifTrue: [^i].
	(self layout == #scaled and: [self extent ~= i extent]) ifTrue: [
		^i magnify: i boundingBox by: (self extent / i extent) smoothing: 2].
	(self layout == #scaledAspect and: [self extent ~= i extent]) ifTrue: [
		^self width / i width > (self height / i height)
			ifTrue: [i magnify: i boundingBox by: (self height / i height) smoothing: 2]
			ifFalse: [i magnify: i boundingBox by: (self width / i width) smoothing: 2]].
	self scale ~= 1 ifTrue: [
		^i magnify: i boundingBox by: self scale smoothing: 2].
	^i
]

{ #category : #accessing }
AlphaImageMorph >> update: aSymbol [
	"Update the image if changed."
	
	super update: aSymbol.
	aSymbol = self getImageSelector ifTrue: [
		self updateImage]
]

{ #category : #accessing }
AlphaImageMorph >> updateImage [
	"Get the image from the model."
	
	(self model notNil and: [self getImageSelector notNil]) ifTrue: [
		(self model perform: self getImageSelector) ifNotNil: [:i | self image: i]]
]
