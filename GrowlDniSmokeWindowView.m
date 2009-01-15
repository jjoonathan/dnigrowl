//
//  GrowlDniSmokeWindowView.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Modified by Jonathan deWerd, 1/14/2009. Modifications distributed under the MIT license. 
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlDniSmokeWindowView.h"
#import "GrowlDniSmokeDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlImageAdditions.h"
#import "GrowlBezierPathAdditions.h"
#import "NSMutableAttributedStringAdditions.h"
#import <WebKit/WebPreferences.h>

#define GrowlDniSmokeTextAreaWidth (GrowlDniSmokeNotificationWidth - GrowlDniSmokePadding - iconSize - GrowlDniSmokeIconTextPadding - GrowlDniSmokePadding)
#define GrowlDniSmokeMinTextHeight	(GrowlDniSmokePadding + iconSize + GrowlDniSmokePadding)

@interface GDProgressIndicator : NSProgressIndicator {
}
@end
@implementation GDProgressIndicator
- (void) startAnimation:(id)sender {
#pragma unused(sender)
}
- (void) stopAnimation:(id)sender {
#pragma unused(sender)
}
- (void) animate:(id)sender {
#pragma unused(sender)
}
@end

@implementation GrowlDniSmokeWindowView

- (id) initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		textFont = [[NSFont fontWithName:@"D'ni Script" size:GrowlDniSmokeTextFontSize] retain];
		titleFont = [[NSFont fontWithName:@"D'ni Script" size:GrowlDniSmokeTitleFontSize] retain];
		textLayoutManager = [[NSLayoutManager alloc] init];
		titleLayoutManager = [[NSLayoutManager alloc] init];
		lineHeight = [textLayoutManager defaultLineHeightForFont:textFont];
		textShadow = [[NSShadow alloc] init];
		[textShadow setShadowOffset:NSMakeSize(0.0f, -2.0f)];
		[textShadow setShadowBlurRadius:3.0f];
		
		int size = GrowlDniSmokeSizePrefDefault;
		READ_GROWL_PREF_INT(GrowlDniSmokeSizePref, GrowlDniSmokePrefDomain, &size);
		if (size == GrowlDniSmokeSizeLarge)
			iconSize = GrowlDniSmokeIconSizeLarge;
		else
			iconSize = GrowlDniSmokeIconSize;
	}
	[self setCloseBoxOrigin:NSMakePoint(2,3)];
	return self;
}

- (void) setProgress:(NSNumber *)value {
	if (value) {
		if (!progressIndicator) {
			progressIndicator = [[GDProgressIndicator alloc] initWithFrame:NSMakeRect(GrowlDniSmokePadding, GrowlDniSmokePadding + iconSize + GrowlDniSmokeIconProgressPadding, iconSize, NSProgressIndicatorPreferredSmallThickness)];
			[progressIndicator setStyle:NSProgressIndicatorBarStyle];
			[progressIndicator setControlSize:NSSmallControlSize];
			[progressIndicator setBezeled:NO];
			[progressIndicator setControlTint:NSDefaultControlTint];
			[progressIndicator setIndeterminate:NO];
			[self addSubview:progressIndicator];
			[progressIndicator release];
		}
		[progressIndicator setDoubleValue:[value doubleValue]];
		[self setNeedsDisplay:YES];
	} else if (progressIndicator) {
		[progressIndicator removeFromSuperview];
		progressIndicator = nil;
	}
}

- (void) dealloc {
	[titleFont          release];
	[textFont           release];
	[icon               release];
	[bgColor            release];
	[textColor          release];
	[textShadow         release];
	[textStorage        release];
	[textLayoutManager  release];
	[titleStorage       release];
	[titleLayoutManager release];
	
	[super dealloc];
}

- (BOOL) isFlipped {
	// Coordinates are based on top left corner
    return YES;
}

- (void) drawRect:(NSRect)rect {
#pragma unused(rect)
	//Make sure that we don't draw in the main thread
	//if ([super dispatchDrawingToThread:rect]) {
	NSRect b = [self bounds];
	CGRect bounds = CGRectMake(b.origin.x, b.origin.y, b.size.width, b.size.height);
	
	CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	
	// calculate bounds based on icon-float pref on or off
	CGRect shadedBounds;
	BOOL floatIcon = GrowlDniSmokeFloatIconPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlDniSmokeFloatIconPref, GrowlDniSmokePrefDomain, &floatIcon);
	if (floatIcon) {
		float sizeReduction = GrowlDniSmokePadding + iconSize + (GrowlDniSmokeIconTextPadding * 0.5f);
		
		shadedBounds = CGRectMake(bounds.origin.x + sizeReduction + 1.0f,
								  bounds.origin.y + 1.0f,
								  bounds.size.width - sizeReduction - 2.0f,
								  bounds.size.height - 2.0f);
	} else {
		shadedBounds = CGRectInset(bounds, 1.0f, 1.0f);
	}
	
	// set up bezier path for rounded corners
	addRoundedRectToPath(context, shadedBounds, GrowlDniSmokeBorderRadius);
	CGContextSetLineWidth(context, 2.0f);
	
	// draw background
	CGPathDrawingMode drawingMode;
	if (mouseOver) {
		drawingMode = kCGPathFillStroke;
		[bgColor setFill];
		[textColor setStroke];
	} else {
		drawingMode = kCGPathFill;
		[bgColor set];
	}
	CGContextDrawPath(context, drawingMode);
	
	// draw the title and the text
	NSRect drawRect;
	drawRect.origin.x = GrowlDniSmokePadding;
	drawRect.origin.y = GrowlDniSmokePadding;
	drawRect.size.width = iconSize;
	drawRect.size.height = iconSize;
	
	[icon setFlipped:YES];
	[icon drawScaledInRect:drawRect
				 operation:NSCompositeSourceOver
				  fraction:1.0f];
	
	drawRect.origin.x += iconSize + GrowlDniSmokeIconTextPadding;
	
	if (haveTitle) {
		[titleLayoutManager drawGlyphsForGlyphRange:titleRange atPoint:drawRect.origin];
		drawRect.origin.y += titleHeight + GrowlDniSmokeTitleTextPadding;
	}
	
	if (haveText)
		[textLayoutManager drawGlyphsForGlyphRange:textRange atPoint:drawRect.origin];
	
	[[self window] invalidateShadow];
	[super drawRect:rect];
	//}
}

- (void) setIcon:(NSImage *)anIcon {
	[icon release];
	icon = [anIcon retain];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *)aTitle {
	haveTitle = [aTitle length] != 0;
	
	if (!haveTitle) {
		[self setNeedsDisplay:YES];
		return;
	}
	
	if (!titleStorage) {
		NSSize containerSize;
		containerSize.width = GrowlDniSmokeTextAreaWidth;
		containerSize.height = FLT_MAX;
		titleStorage = [[NSTextStorage alloc] init];
		titleContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
		[titleLayoutManager addTextContainer:titleContainer];	// retains textContainer
		[titleContainer release];
		[titleStorage addLayoutManager:titleLayoutManager];	// retains layoutManager
		[titleContainer setLineFragmentPadding:0.0f];
	}
	
	// construct attributes for the title
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	NSDictionary *defaultAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
									   titleFont,		NSFontAttributeName,
									   textColor,		NSForegroundColorAttributeName,
									   textShadow,     NSShadowAttributeName,
									   paragraphStyle, NSParagraphStyleAttributeName,
									   [NSNumber numberWithFloat:1.0], NSKernAttributeName,
									   nil];
	[paragraphStyle release];
	
	aTitle = [self dnifiedString:aTitle];
	[[titleStorage mutableString] setString:aTitle];
	[titleStorage setAttributes:defaultAttributes range:NSMakeRange(0U, [aTitle length])];
	
	[defaultAttributes release];
	
	titleRange = [titleLayoutManager glyphRangeForTextContainer:titleContainer];	// force layout
	titleHeight = [titleLayoutManager usedRectForTextContainer:titleContainer].size.height;
	
	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *)aText {
	haveText = [aText length] != 0;
	
	if (!haveText) {
		[self setNeedsDisplay:YES];
		return;
	}
	
	if (!textStorage) {
		NSSize containerSize;
		BOOL limitPref = GrowlDniSmokeLimitPrefDefault;
		READ_GROWL_PREF_BOOL(GrowlDniSmokeLimitPref, GrowlDniSmokePrefDomain, &limitPref);
		containerSize.width = GrowlDniSmokeTextAreaWidth;
		if (limitPref)
			containerSize.height = lineHeight * GrowlDniSmokeMaxLines;
		else
			containerSize.height = FLT_MAX;
		textStorage = [[NSTextStorage alloc] init];
		textContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
		[textLayoutManager addTextContainer:textContainer];	// retains textContainer
		[textContainer release];
		[textStorage addLayoutManager:textLayoutManager];	// retains layoutManager
		[textContainer setLineFragmentPadding:0.0f];
	}
	
	// construct default attributes for the description text
	NSDictionary *defaultAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
									   textFont,	NSFontAttributeName,
									   textColor,  NSForegroundColorAttributeName,
									   textShadow, NSShadowAttributeName,
									   [NSNumber numberWithFloat:1.0], NSKernAttributeName,
									   nil];
	
	aText = [self dnifiedString:aText];
	[[textStorage mutableString] setString:aText];
	[textStorage setAttributes:defaultAttributes range:NSMakeRange(0U, [aText length])];
	
	[defaultAttributes release];
	
	textRange = [textLayoutManager glyphRangeForTextContainer:textContainer];	// force layout
	textHeight = [textLayoutManager usedRectForTextContainer:textContainer].size.height;
	
	[self setNeedsDisplay:YES];
}

- (void) setPriority:(int)priority {
	NSString *key;
	NSString *textKey;
	switch (priority) {
		case -2:
			key = GrowlDniSmokeVeryLowColor;
			textKey = GrowlDniSmokeVeryLowTextColor;
			break;
		case -1:
			key = GrowlDniSmokeModerateColor;
			textKey = GrowlDniSmokeModerateTextColor;
			break;
		case 1:
			key = GrowlDniSmokeHighColor;
			textKey = GrowlDniSmokeHighTextColor;
			break;
		case 2:
			key = GrowlDniSmokeEmergencyColor;
			textKey = GrowlDniSmokeEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlDniSmokeNormalColor;
			textKey = GrowlDniSmokeNormalTextColor;
			break;
	}
	
	float backgroundAlpha = GrowlDniSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlDniSmokeAlphaPref, GrowlDniSmokePrefDomain, &backgroundAlpha);
	backgroundAlpha *= 0.01f;
	
	[bgColor release];
	
	Class NSDataClass = [NSData class];
	NSData *data = nil;
	
	READ_GROWL_PREF_VALUE(key, GrowlDniSmokePrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:NSDataClass]) {
		bgColor = [NSUnarchiver unarchiveObjectWithData:data];
		bgColor = [bgColor colorWithAlphaComponent:backgroundAlpha];
	} else {
		bgColor = [NSColor colorWithCalibratedWhite:0.1f alpha:backgroundAlpha];
	}
	[bgColor retain];
	[data release];
	data = nil;
	
	[textColor release];
	READ_GROWL_PREF_VALUE(textKey, GrowlDniSmokePrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:NSDataClass])
		textColor = [NSUnarchiver unarchiveObjectWithData:data];
	else
		textColor = [NSColor whiteColor];
	[textColor retain];
	[data release];
	
	[textShadow setShadowColor:[bgColor blendedColorWithFraction:0.5f ofColor:[NSColor blackColor]]];
}

- (void) sizeToFit {
	float height = GrowlDniSmokePadding + GrowlDniSmokePadding + [self titleHeight] + [self descriptionHeight];
	if (haveTitle && haveText)
		height += GrowlDniSmokeTitleTextPadding;
	if (progressIndicator)
		height += GrowlDniSmokeIconProgressPadding + [progressIndicator bounds].size.height;
	if (height < GrowlDniSmokeMinTextHeight)
		height = GrowlDniSmokeMinTextHeight;
	
	NSRect rect = [self frame];
	rect.size.height = height;
	[self setFrame:rect];
	
	// resize the window so that it contains the tracking rect
	NSWindow *window = [self window];
	NSRect windowRect = [window frame];
	windowRect.origin.y -= height - windowRect.size.height;
	windowRect.size.height = height;
	[window setFrame:windowRect display:YES animate:YES];
	
	if (trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	trackingRectTag = [self addTrackingRect:rect owner:self userData:NULL assumeInside:NO];
}

- (float) titleHeight {
	return haveTitle ? titleHeight : 0.0f;
}

- (float) descriptionHeight {
	return haveText ? textHeight : 0.0f;
}

- (int) descriptionRowCount {
	int rowCount = textHeight / lineHeight;
	BOOL limitPref = GrowlDniSmokeLimitPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlDniSmokeLimitPref, GrowlDniSmokePrefDomain, &limitPref);
	if (limitPref)
		return MIN(rowCount, GrowlDniSmokeMaxLines);
	else
		return rowCount;
}

#pragma mark -

- (id) target {
	return target;
}

- (void) setTarget:(id) object {
	target = object;
}

#pragma mark -

- (SEL) action {
	return action;
}

- (void) setAction:(SEL) selector {
	action = selector;
}





static void appendDnizedSentenceOf_to_(NSString* of, NSMutableString* to) {
	OSErr e;
	SpeechChannel chan;
	e = NewSpeechChannel(NULL, &chan);
	if (e) {NSLog(@"Err %i at %s:%s", e, __FILE__, __LINE__); return;}
	
	CFStringRef phonemes;
	e = CopyPhonemesFromText(chan, (CFStringRef)of, &phonemes);
	if (e) {NSLog(@"Err %i at %s:%s", e, __FILE__, __LINE__); return;}
	const char* phons = [(NSString*)phonemes UTF8String];
	NSString* to_append = nil;
	while (*phons) {
		to_append = nil;
		switch (*phons) {
			case 'b': to_append=@"b"; break;
			case 'C': to_append=@"tS"; break;
			case 'd': to_append=@"D"; break;
			case 'D': to_append=@"d"; break;
			case 'f': to_append=@"f"; break;
			case 'g': to_append=@"g"; break;
			case 'h': to_append=@"h"; break;
			case 'J': to_append=@"j"; break;
			case 'k': to_append=@"K"; break;
			case 'l': to_append=@"l"; break;
			case 'm': to_append=@"m"; break;
			case 'n': to_append=@"n"; break;
			case 'N': to_append=@"ng"; break;
			case 'p': to_append=@"p"; break;
			case 'r': to_append=@"r"; break;
			case 's': to_append=@"s"; break;
			case 'S': to_append=@"S"; break;
			case 't': to_append=@"t"; break;
			case 'T': to_append=@"T"; break;
			case 'v': to_append=@"v"; break;
			case 'w': to_append=@"w"; break;
			case 'y': to_append=@"y"; break;
			case 'z': to_append=@"z"; break;
			case 'Z': to_append=@"Z"; break; //Probably not right, but we can imagine...
			case 'A':
				phons++;
				switch (*phons) {
					case 'E': to_append=@"Y"; break;
					case 'O': to_append=@"a"; break;
					case 'X': to_append=@"u"; break;
					case 'Y': to_append=@"I"; break;
					case 'A': to_append=@"a"; break;
					case 'W': to_append=@"aw"; break;
					default:
						NSLog(@"Strange phoneme code %c%c in %s", 'A', *phons, phons);
						phons--;
				};
				break;
			case 'E':
				phons++;
				switch (*phons) {
					case 'Y': to_append=@"A"; break;
					case 'H': to_append=@"e"; break;
					default:
						NSLog(@"Strange phoneme code %c%c in %s", 'E', *phons, phons);
						phons--;
				};
				break;
			case 'I':
				phons++;
				switch (*phons) {
					case 'H': to_append=@"i"; break;
					case 'Y': to_append=@"E"; break;
					case 'X': to_append=@"e"; break;
					default:
						NSLog(@"Strange phoneme code %c%c in %s", 'I', *phons, phons);
						phons--;
				};
				break;
			case 'U':
				phons++;
				switch (*phons) {
					case 'W': to_append=@"U"; break; //oo
					case 'H': to_append=@"U"; break; //ooih
					case 'X': to_append=@"u"; break; 
					default:
						NSLog(@"Strange phoneme code %c%c in %s", 'U', *phons, phons);
						phons--;
				};
				break;
			case 'O':
				phons++;
				switch (*phons) {
					case 'W': to_append=@"o"; break;
					case 'Y': to_append=@"O"; break;
					default:
						NSLog(@"Strange phoneme code %c%c in %s", 'O', *phons, phons);
						phons--;
				};
				break;
			case ' ': to_append=@"  "; break;
			case '.': case '?': case '!': break;
			case '%': case '@': case '~': case '_': break;
			case '1': case '2': case '3': case '4': break;
			default:
				NSLog(@"Unknown phoneme %c", *phons);
		}
		if (to_append) [to appendString:to_append];
		phons++;
	}
	CFRelease(phonemes);
	DisposeSpeechChannel(chan);
}

static void appendDnizedTextOf_to_(NSString* of, NSMutableString* to) {
	NSCharacterSet* punct = [NSCharacterSet punctuationCharacterSet];
	NSString* chunk;
	NSScanner *sc = [NSScanner scannerWithString:of];
	UInt64 last_sentence_start = [to length];
	while (![sc isAtEnd]) {
		if ([sc scanUpToCharactersFromSet:punct intoString:&chunk]) {
			last_sentence_start = [to length];
			appendDnizedSentenceOf_to_(chunk, to);
		}
		if ([sc scanCharactersFromSet:punct intoString:&chunk]) {
			[to insertString:chunk atIndex:last_sentence_start];
		}
	}
}

static void appendNumber_to_(int num, NSMutableString* to) {
	int absnum = abs(num);
	char dnum_internal[10] = {0};
	char* dnum = dnum_internal+8;
	if (absnum==25) *dnum-- = '|';
	else while (absnum) {
		*dnum-- = "0123456789)!@#$%^&*([]{}\\|"[absnum%25];
		absnum/=25;
	}
	if (num<0) *dnum-- = '-';
	//NSLog(@"Numbr(%i): %i => %s", wasnum, numbr, dnum+1);
	[to appendFormat:@"%s ",dnum+1];
}

- (NSString*)dnifiedString:(NSString*)str {
	NSScanner* sc = [NSScanner scannerWithString:str];
	NSCharacterSet* decimalNumbers = [NSCharacterSet decimalDigitCharacterSet];
	NSMutableString* dnistr = [NSMutableString string];
	NSString* part; int num;
	while (![sc isAtEnd]) {
		if ([sc scanUpToCharactersFromSet:decimalNumbers intoString:&part]) {
			appendDnizedTextOf_to_(part, dnistr);
		}
		else if ([sc scanInt:&num]) {
			appendNumber_to_(num, dnistr);
		}
		else { //Skip over stuff we don't recognize
			[sc scanUpToCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:nil];
		}
	}
	
	return [[dnistr copy] autorelease];
}






@end
