/* Native AppKit interface for AdvancedAttributeInspector.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_AdvancedAttributeInspector : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_AdvancedAttributeInspector

+ (void) buildForOwner: (id)owner
{
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect (0, 0, 289, 387) styleMask: (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask) backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setFrameAutosaveName: @"Inspector"];
  [window setTitle: @"Inspector"];
  EOMLayoutView *vbox2 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 289, 387)]);
  [vbox2 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSBox *box3 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 277, 82)]);
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setTitle: @"Options"];
  EOMLayoutView *grid4 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 261, 52)]);
  [grid4 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *gridRow5 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 249, 40)]);
  [gridRow5 setHorizontal: YES];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSButton *readOnlySwitch = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 91, 28)]);
  [readOnlySwitch setButtonType: NSSwitchButton];
  [readOnlySwitch setTitle: @"Read Only"];
  [readOnlySwitch setTarget: owner];
  [readOnlySwitch setAction: NSSelectorFromString (@"readOnlyClicked:")];
  NSButton *allowNullSwitch = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 140, 28)]);
  [allowNullSwitch setButtonType: NSSwitchButton];
  [allowNullSwitch setTitle: @"Allow Null Value"];
  [allowNullSwitch setTarget: owner];
  [allowNullSwitch setAction: NSSelectorFromString (@"allowNullClicked:")];
  [readOnlySwitch setFrame: NSMakeRect (6, 6, 91, 28)];
  [gridRow5 addSubview: readOnlySwitch];
  [readOnlySwitch setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [allowNullSwitch setFrame: NSMakeRect (103, 6, 140, 28)];
  [gridRow5 addSubview: allowNullSwitch];
  [allowNullSwitch setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridRow5 setFrame: NSMakeRect (6, 6, 249, 40)];
  [grid4 addSubview: gridRow5];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setContentView: grid4];
  NSBox *box8 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 196, 120)]);
  [box8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box8 setTitle: @"Custom Formatting"];
  EOMLayoutView *grid9 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 180, 90)]);
  [grid9 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *gridRow10 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 161, 36)]);
  [gridRow10 setHorizontal: YES];
  [gridRow10 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label11 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 43, 22)]);
  [label11 setStringValue: @"Read:"];
  [label11 setEditable: NO];
  [label11 setBordered: NO];
  [label11 setDrawsBackground: NO];
  [label11 setSelectable: NO];
  [label11 setAlignment: NSRightTextAlignment];
  [label11 setSelectable: NO];
  NSTextField *readField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [readField setStringValue: @""];
  [readField setDelegate: owner];
  [label11 setFrame: NSMakeRect (6, 6, 43, 24)];
  [gridRow10 addSubview: label11];
  [label11 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [readField setFrame: NSMakeRect (55, 6, 100, 24)];
  [gridRow10 addSubview: readField];
  [readField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  EOMLayoutView *gridRow13 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 168, 36)]);
  [gridRow13 setHorizontal: YES];
  [gridRow13 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label14 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 50, 22)]);
  [label14 setStringValue: @"Write:"];
  [label14 setEditable: NO];
  [label14 setBordered: NO];
  [label14 setDrawsBackground: NO];
  [label14 setSelectable: NO];
  [label14 setAlignment: NSRightTextAlignment];
  [label14 setSelectable: NO];
  NSTextField *writeField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [writeField setStringValue: @""];
  [writeField setDelegate: owner];
  [label14 setFrame: NSMakeRect (6, 6, 50, 24)];
  [gridRow13 addSubview: label14];
  [label14 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [writeField setFrame: NSMakeRect (62, 6, 100, 24)];
  [gridRow13 addSubview: writeField];
  [writeField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridRow10 setFrame: NSMakeRect (6, 48, 168, 36)];
  [grid9 addSubview: gridRow10];
  [gridRow10 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [gridRow13 setFrame: NSMakeRect (6, 6, 168, 36)];
  [grid9 addSubview: gridRow13];
  [gridRow13 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box8 setContentView: grid9];
  [box3 setFrame: NSMakeRect (6, 299, 277, 82)];
  [vbox2 addSubview: box3];
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box8 setFrame: NSMakeRect (6, 173, 277, 120)];
  [vbox2 addSubview: box8];
  [box8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [window setContentView: vbox2];
  [owner setValue: window forKey: @"window"];
  [owner setValue: readOnlySwitch forKey: @"readOnlySwitch"];
  [owner setValue: allowNullSwitch forKey: @"allowNullSwitch"];
  [owner setValue: readField forKey: @"readField"];
  [owner setValue: writeField forKey: @"writeField"];
  [owner awakeFromNib];
}

@end
