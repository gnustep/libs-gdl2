/* Native AppKit interface for AdvancedRelationshipInspector.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_AdvancedRelationshipInspector : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_AdvancedRelationshipInspector

+ (void) buildForOwner: (id)owner
{
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect (0, 0, 272, 416) styleMask: (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask) backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setFrameAutosaveName: @"Inspector"];
  [window setTitle: @"Inspector"];
  EOMLayoutView *vbox2 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 272, 416)]);
  [vbox2 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSBox *box3 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 260, 78)]);
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setTitle: @"Batch Faulting"];
  EOMLayoutView *grid4 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 215, 48)]);
  [grid4 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *gridRow5 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 203, 36)]);
  [gridRow5 setHorizontal: YES];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label6 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 85, 22)]);
  [label6 setStringValue: @"Batch Size:"];
  [label6 setEditable: NO];
  [label6 setBordered: NO];
  [label6 setDrawsBackground: NO];
  [label6 setSelectable: NO];
  [label6 setAlignment: NSRightTextAlignment];
  [label6 setSelectable: NO];
  NSTextField *batchSizeField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [batchSizeField setStringValue: @""];
  [batchSizeField setDelegate: owner];
  [label6 setFrame: NSMakeRect (6, 6, 85, 24)];
  [gridRow5 addSubview: label6];
  [label6 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [batchSizeField setFrame: NSMakeRect (97, 6, 100, 24)];
  [gridRow5 addSubview: batchSizeField];
  [batchSizeField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridRow5 setFrame: NSMakeRect (6, 6, 203, 36)];
  [grid4 addSubview: gridRow5];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setContentView: grid4];
  NSBox *box8 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 260, 78)]);
  [box8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box8 setTitle: @"Optionality"];
  NSMatrix *optionalityMatrix = AUTORELEASE ([[NSMatrix alloc] initWithFrame: NSMakeRect (0, 0, 91, 48) mode: NSRadioModeMatrix cellClass: [NSButtonCell class] numberOfRows: 2 numberOfColumns: 1]);
  [optionalityMatrix setTarget: owner];
  [optionalityMatrix setAction: NSSelectorFromString (@"optionalityClicked:")];
  [[optionalityMatrix cellAtRow: 0 column: 0] setButtonType: NSRadioButton];
  [[optionalityMatrix cellAtRow: 0 column: 0] setTitle: @"Optional"];
  [[optionalityMatrix cellAtRow: 0 column: 0] setTag: 0];
  [[optionalityMatrix cellAtRow: 1 column: 0] setButtonType: NSRadioButton];
  [[optionalityMatrix cellAtRow: 1 column: 0] setTitle: @"Mandatory"];
  [[optionalityMatrix cellAtRow: 1 column: 0] setTag: 1];
  [optionalityMatrix setCellSize: NSMakeSize (91, 24)];
  [optionalityMatrix selectCellAtRow: 0 column: 0];
  [box8 setContentView: optionalityMatrix];
  NSBox *box10 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 260, 126)]);
  [box10 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box10 setTitle: @"Delete Rule"];
  NSMatrix *deleteRuleMatrix = AUTORELEASE ([[NSMatrix alloc] initWithFrame: NSMakeRect (0, 0, 91, 96) mode: NSRadioModeMatrix cellClass: [NSButtonCell class] numberOfRows: 4 numberOfColumns: 1]);
  [deleteRuleMatrix setTarget: owner];
  [deleteRuleMatrix setAction: NSSelectorFromString (@"deleteRuleClicked:")];
  [[deleteRuleMatrix cellAtRow: 0 column: 0] setButtonType: NSRadioButton];
  [[deleteRuleMatrix cellAtRow: 0 column: 0] setTitle: @"Nullify"];
  [[deleteRuleMatrix cellAtRow: 0 column: 0] setTag: 0];
  [[deleteRuleMatrix cellAtRow: 1 column: 0] setButtonType: NSRadioButton];
  [[deleteRuleMatrix cellAtRow: 1 column: 0] setTitle: @"Cascade"];
  [[deleteRuleMatrix cellAtRow: 1 column: 0] setTag: 1];
  [[deleteRuleMatrix cellAtRow: 2 column: 0] setButtonType: NSRadioButton];
  [[deleteRuleMatrix cellAtRow: 2 column: 0] setTitle: @"Deny"];
  [[deleteRuleMatrix cellAtRow: 2 column: 0] setTag: 2];
  [[deleteRuleMatrix cellAtRow: 3 column: 0] setButtonType: NSRadioButton];
  [[deleteRuleMatrix cellAtRow: 3 column: 0] setTitle: @"No Action"];
  [[deleteRuleMatrix cellAtRow: 3 column: 0] setTag: 3];
  [deleteRuleMatrix setCellSize: NSMakeSize (91, 24)];
  [deleteRuleMatrix selectCellAtRow: 0 column: 0];
  [box10 setContentView: deleteRuleMatrix];
  NSBox *box12 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 260, 104)]);
  [box12 setTitlePosition: NSNoTitle];
  [box12 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *vbox13 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 187, 74)]);
  [vbox13 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSButton *ownsDestinationSwitch = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 140, 28)]);
  [ownsDestinationSwitch setButtonType: NSSwitchButton];
  [ownsDestinationSwitch setTitle: @"Owns Destination"];
  [ownsDestinationSwitch setTarget: owner];
  [ownsDestinationSwitch setAction: NSSelectorFromString (@"ownsDestinationClicked:")];
  NSButton *propagadePrimaryKeySwitch = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 175, 28)]);
  [propagadePrimaryKeySwitch setButtonType: NSSwitchButton];
  [propagadePrimaryKeySwitch setTitle: @"Propagade Primary Key"];
  [propagadePrimaryKeySwitch setTarget: owner];
  [propagadePrimaryKeySwitch setAction: NSSelectorFromString (@"propagadePrimaryKeyClicked:")];
  [ownsDestinationSwitch setFrame: NSMakeRect (6, 40, 175, 28)];
  [vbox13 addSubview: ownsDestinationSwitch];
  [ownsDestinationSwitch setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [propagadePrimaryKeySwitch setFrame: NSMakeRect (6, 6, 175, 28)];
  [vbox13 addSubview: propagadePrimaryKeySwitch];
  [propagadePrimaryKeySwitch setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box12 setContentView: vbox13];
  [box3 setFrame: NSMakeRect (6, 332, 260, 78)];
  [vbox2 addSubview: box3];
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box8 setFrame: NSMakeRect (6, 248, 260, 78)];
  [vbox2 addSubview: box8];
  [box8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box10 setFrame: NSMakeRect (6, 116, 260, 126)];
  [vbox2 addSubview: box10];
  [box10 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box12 setFrame: NSMakeRect (6, 6, 260, 104)];
  [vbox2 addSubview: box12];
  [box12 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [window setContentView: vbox2];
  [owner setValue: window forKey: @"window"];
  [owner setValue: batchSizeField forKey: @"batchSizeField"];
  [owner setValue: optionalityMatrix forKey: @"optionalityMatrix"];
  [owner setValue: deleteRuleMatrix forKey: @"deleteRuleMatrix"];
  [owner setValue: ownsDestinationSwitch forKey: @"ownsDestinationSwitch"];
  [owner setValue: propagadePrimaryKeySwitch forKey: @"propagadePrimaryKeySwitch"];
  [owner awakeFromNib];
}

@end
