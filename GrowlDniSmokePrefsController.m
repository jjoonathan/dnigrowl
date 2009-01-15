//
//  GrowlDniSmokePrefsController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlDniSmokePrefsController.h"
#import "GrowlDniSmokeDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlDniSmokePrefsController

- (NSString *) mainNibName {
	return @"DniSmokePrefs";
}

+ (void) loadColorWell:(NSColorWell *)colorWell fromKey:(NSString *)key defaultColor:(NSColor *)defaultColor {
	NSData *data = nil;
	NSColor *color;
	READ_GROWL_PREF_VALUE(key, GrowlDniSmokePrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:[NSData class]]) {
		color = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		color = defaultColor;
	}
	[colorWell setColor:color];
	[data release];
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:0.05];

	// priority colour settings
	NSColor *defaultColor = [NSColor colorWithCalibratedWhite:0.1f alpha:1.0f];

	[GrowlDniSmokePrefsController loadColorWell:color_veryLow fromKey:GrowlDniSmokeVeryLowColor defaultColor:defaultColor];
	[GrowlDniSmokePrefsController loadColorWell:color_moderate fromKey:GrowlDniSmokeModerateColor defaultColor:defaultColor];
	[GrowlDniSmokePrefsController loadColorWell:color_normal fromKey:GrowlDniSmokeNormalColor defaultColor:defaultColor];
	[GrowlDniSmokePrefsController loadColorWell:color_high fromKey:GrowlDniSmokeHighColor defaultColor:defaultColor];
	[GrowlDniSmokePrefsController loadColorWell:color_emergency fromKey:GrowlDniSmokeEmergencyColor defaultColor:defaultColor];

	defaultColor = [NSColor whiteColor];

	[GrowlDniSmokePrefsController loadColorWell:text_veryLow fromKey:GrowlDniSmokeVeryLowTextColor defaultColor:defaultColor];
	[GrowlDniSmokePrefsController loadColorWell:text_moderate fromKey:GrowlDniSmokeModerateTextColor defaultColor:defaultColor];
	[GrowlDniSmokePrefsController loadColorWell:text_normal fromKey:GrowlDniSmokeNormalTextColor defaultColor:defaultColor];
	[GrowlDniSmokePrefsController loadColorWell:text_high fromKey:GrowlDniSmokeHighTextColor defaultColor:defaultColor];
	[GrowlDniSmokePrefsController loadColorWell:text_emergency fromKey:GrowlDniSmokeEmergencyTextColor defaultColor:defaultColor];
}

- (float) opacity {
	float value = GrowlDniSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlDniSmokeAlphaPref, GrowlDniSmokePrefDomain, &value);
	return value;
}

- (void) setOpacity:(float)value {
	WRITE_GROWL_PREF_FLOAT(GrowlDniSmokeAlphaPref, value, GrowlDniSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

- (float) duration {
	float value = GrowlDniSmokeDurationPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlDniSmokeDurationPref, GrowlDniSmokePrefDomain, &value);
	return value;
}

- (void) setDuration:(float)value {
	WRITE_GROWL_PREF_FLOAT(GrowlDniSmokeDurationPref, value, GrowlDniSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

- (IBAction) colorChanged:(id)sender {
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlDniSmokeVeryLowColor;
			break;
		case -1:
			key = GrowlDniSmokeModerateColor;
			break;
		case 1:
			key = GrowlDniSmokeHighColor;
			break;
		case 2:
			key = GrowlDniSmokeEmergencyColor;
			break;
		case 0:
		default:
			key = GrowlDniSmokeNormalColor;
			break;
	}

	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowlDniSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

- (IBAction) textColorChanged:(id)sender {
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlDniSmokeVeryLowTextColor;
			break;
		case -1:
			key = GrowlDniSmokeModerateTextColor;
			break;
		case 1:
			key = GrowlDniSmokeHighTextColor;
			break;
		case 2:
			key = GrowlDniSmokeEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlDniSmokeNormalTextColor;
			break;
	}

	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowlDniSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

- (BOOL) isFloatingIcon {
	BOOL value = GrowlDniSmokeFloatIconPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlDniSmokeFloatIconPref, GrowlDniSmokePrefDomain, &value);
	return value;
}

- (void) setFloatingIcon:(BOOL)value {
	WRITE_GROWL_PREF_BOOL(GrowlDniSmokeFloatIconPref, value, GrowlDniSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

- (BOOL) isLimit {
	BOOL value = GrowlDniSmokeLimitPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlDniSmokeLimitPref, GrowlDniSmokePrefDomain, &value);
	return value;
}

- (void) setLimit:(BOOL)value {
	WRITE_GROWL_PREF_BOOL(GrowlDniSmokeLimitPref, value, GrowlDniSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

- (int) numberOfItemsInComboBox:(NSComboBox *)aComboBox {
#pragma unused(aComboBox)
	return [[NSScreen screens] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)idx {
#pragma unused(aComboBox)
	return [NSNumber numberWithInt:idx];
}

- (int) screen {
	int value = 0;
	READ_GROWL_PREF_INT(GrowlDniSmokeScreenPref, GrowlDniSmokePrefDomain, &value);
	return value;
}

- (void) setScreen:(int)value {
	WRITE_GROWL_PREF_INT(GrowlDniSmokeScreenPref, value, GrowlDniSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

- (int) size {
	int value = 0;
	READ_GROWL_PREF_INT(GrowlDniSmokeSizePref, GrowlDniSmokePrefDomain, &value);
	return value;
}

- (void) setSize:(int)value {
	WRITE_GROWL_PREF_INT(GrowlDniSmokeSizePref, value, GrowlDniSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

@end
