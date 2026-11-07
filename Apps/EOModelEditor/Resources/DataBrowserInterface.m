/* Native AppKit interface for DataBrowser.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_DataBrowser : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_DataBrowser

+ (void) buildForOwner: (id)owner
{
  NSWindow *window = [[NSClassFromString (@"EOWindow") alloc] initWithContentRect: NSMakeRect (0, 0, 1255, 300) styleMask: (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask) backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setTitle: @"Data Browser"];
  [window setDelegate: owner];
  EOMLayoutView *vbox2 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 1255, 300)]);
  [vbox2 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSBox *box3 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 1243, 82)]);
  [box3 setTitlePosition: NSNoTitle];
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *grid4 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 1227, 52)]);
  [grid4 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *gridRow5 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 1215, 40)]);
  [gridRow5 setHorizontal: YES];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label6 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 57, 22)]);
  [label6 setStringValue: @"Entity:"];
  [label6 setEditable: NO];
  [label6 setBordered: NO];
  [label6 setDrawsBackground: NO];
  [label6 setSelectable: NO];
  [label6 setAlignment: NSRightTextAlignment];
  [label6 setSelectable: NO];
  NSTextField *entityNameField = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 92, 22)]);
  [entityNameField setStringValue: @"XXXXXXXXXXXX"];
  [entityNameField setEditable: NO];
  [entityNameField setBordered: NO];
  [entityNameField setDrawsBackground: NO];
  [entityNameField setSelectable: NO];
  [entityNameField setSelectable: NO];
  NSView *gridEmptyCell8 = AUTORELEASE ([[NSView alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [gridEmptyCell8 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label9 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 92, 22)]);
  [label9 setStringValue: @"Fetch Limit:"];
  [label9 setEditable: NO];
  [label9 setBordered: NO];
  [label9 setDrawsBackground: NO];
  [label9 setSelectable: NO];
  [label9 setAlignment: NSRightTextAlignment];
  [label9 setSelectable: NO];
  NSTextField *fetchLimitText = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [fetchLimitText setStringValue: @"10"];
  [fetchLimitText setDelegate: owner];
  NSView *gridEmptyCell11 = AUTORELEASE ([[NSView alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [gridEmptyCell11 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSTextField *label12 = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 78, 22)]);
  [label12 setStringValue: @"Qualifier:"];
  [label12 setEditable: NO];
  [label12 setBordered: NO];
  [label12 setDrawsBackground: NO];
  [label12 setSelectable: NO];
  [label12 setAlignment: NSRightTextAlignment];
  [label12 setSelectable: NO];
  NSTextField *qualifierText = AUTORELEASE ([[NSTextField alloc] initWithFrame: NSMakeRect (0, 0, 350, 24)]);
  [qualifierText setStringValue: @""];
  [qualifierText setDelegate: owner];
  NSView *gridEmptyCell14 = AUTORELEASE ([[NSView alloc] initWithFrame: NSMakeRect (0, 0, 100, 24)]);
  [gridEmptyCell14 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSButton *button15 = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 80, 28)]);
  [button15 setButtonType: NSMomentaryPushInButton];
  [button15 setTitle: @"Fetch"];
  [button15 setTarget: owner];
  [button15 setAction: NSSelectorFromString (@"fetch:")];
  [label6 setFrame: NSMakeRect (6, 6, 57, 28)];
  [gridRow5 addSubview: label6];
  [label6 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [entityNameField setFrame: NSMakeRect (69, 6, 92, 28)];
  [gridRow5 addSubview: entityNameField];
  [entityNameField setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridEmptyCell8 setFrame: NSMakeRect (167, 6, 100, 28)];
  [gridRow5 addSubview: gridEmptyCell8];
  [gridEmptyCell8 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [label9 setFrame: NSMakeRect (273, 6, 92, 28)];
  [gridRow5 addSubview: label9];
  [label9 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [fetchLimitText setFrame: NSMakeRect (371, 6, 100, 28)];
  [gridRow5 addSubview: fetchLimitText];
  [fetchLimitText setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridEmptyCell11 setFrame: NSMakeRect (477, 6, 100, 28)];
  [gridRow5 addSubview: gridEmptyCell11];
  [gridEmptyCell11 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [label12 setFrame: NSMakeRect (583, 6, 78, 28)];
  [gridRow5 addSubview: label12];
  [label12 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [qualifierText setFrame: NSMakeRect (667, 6, 350, 28)];
  [gridRow5 addSubview: qualifierText];
  [qualifierText setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridEmptyCell14 setFrame: NSMakeRect (1023, 6, 100, 28)];
  [gridRow5 addSubview: gridEmptyCell14];
  [gridEmptyCell14 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [button15 setFrame: NSMakeRect (1129, 6, 80, 28)];
  [gridRow5 addSubview: button15];
  [button15 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridRow5 setFrame: NSMakeRect (6, 6, 1215, 40)];
  [grid4 addSubview: gridRow5];
  [gridRow5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setContentView: grid4];
  NSScrollView *scrollView16 = AUTORELEASE ([[NSScrollView alloc] initWithFrame: NSMakeRect (0, 0, 300, 200)]);
  [scrollView16 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [scrollView16 setHasVerticalScroller: YES];
  [scrollView16 setHasHorizontalScroller: YES];
  [scrollView16 setBorderType: NSBezelBorder];
  NSTableView *tableView = AUTORELEASE ([[NSTableView alloc] initWithFrame: NSMakeRect (0, 0, 160, 100)]);
  [tableView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [tableView setUsesAlternatingRowBackgroundColors: YES];
  [tableView setAllowsEmptySelection: YES];
  [tableView setAllowsColumnSelection: YES];
  [tableView setDrawsGrid: YES];
  NSTableColumn *tableColumn18 = AUTORELEASE ([[NSTableColumn alloc] initWithIdentifier: @"_#number"]);
  [[tableColumn18 headerCell] setStringValue: @"Row #"];
  [tableColumn18 setEditable: NO];
  [tableColumn18 setMinWidth: 30];
  [tableColumn18 setMaxWidth: 80];
  [tableColumn18 setWidth: 30];
  [tableView addTableColumn: tableColumn18];
  [scrollView16 setDocumentView: tableView];
  [tableView setFrame: [[scrollView16 contentView] bounds]];
  [box3 setFrame: NSMakeRect (6, 212, 1243, 82)];
  [vbox2 addSubview: box3];
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [scrollView16 setFrame: NSMakeRect (6, 6, 1243, 200)];
  [vbox2 addSubview: scrollView16];
  [scrollView16 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [window setContentView: vbox2];
  [owner setValue: window forKey: @"window"];
  [owner setValue: entityNameField forKey: @"entityNameField"];
  [owner setValue: fetchLimitText forKey: @"fetchLimitText"];
  [owner setValue: qualifierText forKey: @"qualifierText"];
  [owner setValue: tableView forKey: @"tableView"];
  [owner awakeFromNib];
  [window orderFront: nil];
}

@end
