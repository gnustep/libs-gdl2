/* Native AppKit interface for StoredProcedureInspector.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_StoredProcedureInspector : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_StoredProcedureInspector

+ (void) buildForOwner: (id)owner
{
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect (0, 0, 272, 428) styleMask: (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask) backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setFrameAutosaveName: @"Inspector"];
  [window setTitle: @"Inspector"];
  EOMLayoutView *vbox2 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 272, 428)]);
  [vbox2 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSBox *box3 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 260, 120)]);
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setTitle: @"Names"];
  EOMLayoutView *grid4 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 236, 90)]);
  [grid4 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *gridRow5 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 161, 36)]);
  [gridRow5 setHorizontal: YES];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label6 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 43, 22)]);
  [label6 setStringValue: @"Name:"];
  [label6 setEditable: NO];
  [label6 setBordered: NO];
  [label6 setDrawsBackground: NO];
  [label6 setSelectable: NO];
  [label6 setAlignment: NSRightTextAlignment];
  [label6 setSelectable: NO];
  NSTextField *nameField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [nameField setStringValue: @""];
  [nameField setDelegate: owner];
  [label6 setFrame: NSMakeRect (6, 6, 43, 24)];
  [gridRow5 addSubview: label6];
  [label6 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [nameField setFrame: NSMakeRect (55, 6, 100, 24)];
  [gridRow5 addSubview: nameField];
  [nameField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  EOMLayoutView *gridRow8 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 224, 36)]);
  [gridRow8 setHorizontal: YES];
  [gridRow8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label9 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 106, 22)]);
  [label9 setStringValue: @"External Name:"];
  [label9 setEditable: NO];
  [label9 setBordered: NO];
  [label9 setDrawsBackground: NO];
  [label9 setSelectable: NO];
  [label9 setAlignment: NSRightTextAlignment];
  [label9 setSelectable: NO];
  NSTextField *externalNameField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [externalNameField setStringValue: @""];
  [externalNameField setDelegate: owner];
  [label9 setFrame: NSMakeRect (6, 6, 106, 24)];
  [gridRow8 addSubview: label9];
  [label9 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [externalNameField setFrame: NSMakeRect (118, 6, 100, 24)];
  [gridRow8 addSubview: externalNameField];
  [externalNameField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridRow5 setFrame: NSMakeRect (6, 48, 224, 36)];
  [grid4 addSubview: gridRow5];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [gridRow8 setFrame: NSMakeRect (6, 6, 224, 36)];
  [grid4 addSubview: gridRow8];
  [gridRow8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setContentView: grid4];
  EOMLayoutView *hbox11 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 12, 290)]);
  [hbox11 setHorizontal: YES];
  [hbox11 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setFrame: NSMakeRect (6, 302, 260, 120)];
  [vbox2 addSubview: box3];
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [hbox11 setFrame: NSMakeRect (6, 6, 260, 290)];
  [vbox2 addSubview: hbox11];
  [hbox11 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [window setContentView: vbox2];
  [owner setValue: window forKey: @"window"];
  [owner setValue: nameField forKey: @"nameField"];
  [owner setValue: externalNameField forKey: @"externalNameField"];
  [owner awakeFromNib];
}

@end
