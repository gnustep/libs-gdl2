/* Native AppKit interface for EntityStoredProcedureInspector.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_EntityStoredProcedureInspector : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_EntityStoredProcedureInspector

+ (void) buildForOwner: (id)owner
{
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect (0, 0, 272, 387) styleMask: (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask) backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setFrameAutosaveName: @"Inspector"];
  [window setTitle: @"Inspector"];
  EOMLayoutView *vbox2 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 272, 387)]);
  [vbox2 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSBox *box3 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 260, 246)]);
  [box3 setTitlePosition: NSNoTitle];
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *grid4 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 215, 216)]);
  [grid4 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *gridRow5 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 175, 36)]);
  [gridRow5 setHorizontal: YES];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label6 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 57, 22)]);
  [label6 setStringValue: @"Insert:"];
  [label6 setEditable: NO];
  [label6 setBordered: NO];
  [label6 setDrawsBackground: NO];
  [label6 setSelectable: NO];
  [label6 setAlignment: NSRightTextAlignment];
  [label6 setSelectable: NO];
  NSTextField *insertField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [insertField setStringValue: @""];
  [insertField setToolTip: @"Name of procedure to insert a record."];
  [insertField setDelegate: owner];
  [label6 setFrame: NSMakeRect (6, 6, 57, 24)];
  [gridRow5 addSubview: label6];
  [label6 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [insertField setFrame: NSMakeRect (69, 6, 100, 24)];
  [gridRow5 addSubview: insertField];
  [insertField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  EOMLayoutView *gridRow8 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 175, 36)]);
  [gridRow8 setHorizontal: YES];
  [gridRow8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label9 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 57, 22)]);
  [label9 setStringValue: @"Delete:"];
  [label9 setEditable: NO];
  [label9 setBordered: NO];
  [label9 setDrawsBackground: NO];
  [label9 setSelectable: NO];
  [label9 setAlignment: NSRightTextAlignment];
  [label9 setSelectable: NO];
  NSTextField *deleteField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [deleteField setStringValue: @""];
  [deleteField setToolTip: @"Name of procedure to delete a record."];
  [deleteField setDelegate: owner];
  [label9 setFrame: NSMakeRect (6, 6, 57, 24)];
  [gridRow8 addSubview: label9];
  [label9 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [deleteField setFrame: NSMakeRect (69, 6, 100, 24)];
  [gridRow8 addSubview: deleteField];
  [deleteField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  EOMLayoutView *gridRow11 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 196, 36)]);
  [gridRow11 setHorizontal: YES];
  [gridRow11 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label12 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 78, 22)]);
  [label12 setStringValue: @"Fetch All:"];
  [label12 setEditable: NO];
  [label12 setBordered: NO];
  [label12 setDrawsBackground: NO];
  [label12 setSelectable: NO];
  [label12 setAlignment: NSRightTextAlignment];
  [label12 setSelectable: NO];
  NSTextField *fetchAllField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [fetchAllField setStringValue: @""];
  [fetchAllField setToolTip: @"Name of procedure to fetch all records."];
  [fetchAllField setDelegate: owner];
  [label12 setFrame: NSMakeRect (6, 6, 78, 24)];
  [gridRow11 addSubview: label12];
  [label12 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [fetchAllField setFrame: NSMakeRect (90, 6, 100, 24)];
  [gridRow11 addSubview: fetchAllField];
  [fetchAllField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  EOMLayoutView *gridRow14 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 203, 36)]);
  [gridRow14 setHorizontal: YES];
  [gridRow14 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label15 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 85, 22)]);
  [label15 setStringValue: @"Fetch w/PK:"];
  [label15 setEditable: NO];
  [label15 setBordered: NO];
  [label15 setDrawsBackground: NO];
  [label15 setSelectable: NO];
  [label15 setAlignment: NSRightTextAlignment];
  [label15 setSelectable: NO];
  NSTextField *fetchWithPKField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [fetchWithPKField setStringValue: @""];
  [fetchWithPKField setToolTip: @"Name of procedure to fetch by primary key."];
  [fetchWithPKField setDelegate: owner];
  [label15 setFrame: NSMakeRect (6, 6, 85, 24)];
  [gridRow14 addSubview: label15];
  [label15 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [fetchWithPKField setFrame: NSMakeRect (97, 6, 100, 24)];
  [gridRow14 addSubview: fetchWithPKField];
  [fetchWithPKField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  EOMLayoutView *gridRow17 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 175, 36)]);
  [gridRow17 setHorizontal: YES];
  [gridRow17 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label18 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 57, 22)]);
  [label18 setStringValue: @"Get PK:"];
  [label18 setEditable: NO];
  [label18 setBordered: NO];
  [label18 setDrawsBackground: NO];
  [label18 setSelectable: NO];
  [label18 setAlignment: NSRightTextAlignment];
  [label18 setSelectable: NO];
  NSTextField *pkGetField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [pkGetField setStringValue: @""];
  [pkGetField setToolTip: @"Name of procedure to generate a new primary key."];
  [pkGetField setDelegate: owner];
  [label18 setFrame: NSMakeRect (6, 6, 57, 24)];
  [gridRow17 addSubview: label18];
  [label18 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [pkGetField setFrame: NSMakeRect (69, 6, 100, 24)];
  [gridRow17 addSubview: pkGetField];
  [pkGetField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridRow5 setFrame: NSMakeRect (6, 174, 203, 36)];
  [grid4 addSubview: gridRow5];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [gridRow8 setFrame: NSMakeRect (6, 132, 203, 36)];
  [grid4 addSubview: gridRow8];
  [gridRow8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [gridRow11 setFrame: NSMakeRect (6, 90, 203, 36)];
  [grid4 addSubview: gridRow11];
  [gridRow11 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [gridRow14 setFrame: NSMakeRect (6, 48, 203, 36)];
  [grid4 addSubview: gridRow14];
  [gridRow14 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [gridRow17 setFrame: NSMakeRect (6, 6, 203, 36)];
  [grid4 addSubview: gridRow17];
  [gridRow17 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setContentView: grid4];
  [box3 setFrame: NSMakeRect (6, 135, 260, 246)];
  [vbox2 addSubview: box3];
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [window setContentView: vbox2];
  [owner setValue: window forKey: @"window"];
  [owner setValue: insertField forKey: @"insertField"];
  [owner setValue: deleteField forKey: @"deleteField"];
  [owner setValue: fetchAllField forKey: @"fetchAllField"];
  [owner setValue: fetchWithPKField forKey: @"fetchWithPKField"];
  [owner setValue: pkGetField forKey: @"pkGetField"];
  [owner awakeFromNib];
}

@end
