/* Native AppKit interface for EntityInspector.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_EntityInspector : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_EntityInspector

+ (void) buildForOwner: (id)owner
{
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect (0, 0, 272, 387) styleMask: (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask) backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setFrameAutosaveName: @"Inspector"];
  [window setTitle: @"Inspector"];
  EOMLayoutView *vbox2 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 272, 387)]);
  [vbox2 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSBox *box3 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 260, 162)]);
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setTitle: @"Names"];
  EOMLayoutView *grid4 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 215, 132)]);
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
  EOMLayoutView *gridRow8 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 203, 36)]);
  [gridRow8 setHorizontal: YES];
  [gridRow8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label9 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 85, 22)]);
  [label9 setStringValue: @"Table Name:"];
  [label9 setEditable: NO];
  [label9 setBordered: NO];
  [label9 setDrawsBackground: NO];
  [label9 setSelectable: NO];
  [label9 setAlignment: NSRightTextAlignment];
  [label9 setSelectable: NO];
  NSTextField *tableNameField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [tableNameField setStringValue: @""];
  [tableNameField setDelegate: owner];
  [label9 setFrame: NSMakeRect (6, 6, 85, 24)];
  [gridRow8 addSubview: label9];
  [label9 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [tableNameField setFrame: NSMakeRect (97, 6, 100, 24)];
  [gridRow8 addSubview: tableNameField];
  [tableNameField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  EOMLayoutView *gridRow11 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 168, 36)]);
  [gridRow11 setHorizontal: YES];
  [gridRow11 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label12 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 50, 22)]);
  [label12 setStringValue: @"Class:"];
  [label12 setEditable: NO];
  [label12 setBordered: NO];
  [label12 setDrawsBackground: NO];
  [label12 setSelectable: NO];
  [label12 setAlignment: NSRightTextAlignment];
  [label12 setSelectable: NO];
  NSTextField *classNameField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [classNameField setStringValue: @""];
  [classNameField setDelegate: owner];
  [label12 setFrame: NSMakeRect (6, 6, 50, 24)];
  [gridRow11 addSubview: label12];
  [label12 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [classNameField setFrame: NSMakeRect (62, 6, 100, 24)];
  [gridRow11 addSubview: classNameField];
  [classNameField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridRow5 setFrame: NSMakeRect (6, 90, 203, 36)];
  [grid4 addSubview: gridRow5];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [gridRow8 setFrame: NSMakeRect (6, 48, 203, 36)];
  [grid4 addSubview: gridRow8];
  [gridRow8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [gridRow11 setFrame: NSMakeRect (6, 6, 203, 36)];
  [grid4 addSubview: gridRow11];
  [gridRow11 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setContentView: grid4];
  NSBox *box14 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 260, 200)]);
  [box14 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box14 setTitle: @"Properties"];
  NSTextField *label15 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 141, 22)]);
  [label15 setStringValue: @"Not in this version"];
  [label15 setEditable: NO];
  [label15 setBordered: NO];
  [label15 setDrawsBackground: NO];
  [label15 setSelectable: NO];
  [label15 setSelectable: NO];
  [box14 setContentView: label15];
  [box3 setFrame: NSMakeRect (6, 219, 260, 162)];
  [vbox2 addSubview: box3];
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box14 setFrame: NSMakeRect (6, 13, 260, 200)];
  [vbox2 addSubview: box14];
  [box14 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [window setContentView: vbox2];
  [owner setValue: window forKey: @"window"];
  [owner setValue: nameField forKey: @"nameField"];
  [owner setValue: tableNameField forKey: @"tableNameField"];
  [owner setValue: classNameField forKey: @"classNameField"];
  [owner awakeFromNib];
}

@end
