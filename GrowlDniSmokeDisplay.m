//
//  GrowlDniSmokeDisplay.m
//  Display Plugins
//
//  Created by Matthew Walton on 09/09/2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlDniSmokeDisplay.h"
#import "GrowlDniSmokeWindowController.h"
#import "GrowlDniSmokePrefsController.h"
#import "GrowlDniSmokeDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlApplicationNotification.h"
#import "GrowlNotificationDisplayBridge.h"

#include "CFDictionaryAdditions.h"

@implementation GrowlDniSmokeDisplay

- (id) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlDniSmokeWindowController");
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlDniSmokePrefsController alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.DniSmoke"]];
	return preferencePane;
}

- (BOOL)requiresPositioning {
	return YES;
}


- (void) configureBridge:(GrowlNotificationDisplayBridge *)theBridge {
	// Note: currently we assume there is only one WC...
	GrowlDniSmokeWindowController *controller = [[theBridge windowControllers] objectAtIndex:0U];
	GrowlApplicationNotification *note = [theBridge notification];
	NSDictionary *noteDict = [note dictionaryRepresentation];
	[controller setNotifyingApplicationName:[note applicationName]];
	[controller setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setScreenshotModeEnabled:getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)];
	[controller setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];
}

@end
