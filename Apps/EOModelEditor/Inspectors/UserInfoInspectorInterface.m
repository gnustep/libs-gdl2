/* Native AppKit interface for UserInfoInspector.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_UserInfoInspector : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_UserInfoInspector

+ (void) buildForOwner: (id)owner
{
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect (0, 0, 336, 482) styleMask: (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask) backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setFrameAutosaveName: @"Inspector"];
  [window setTitle: @"Inspector"];
  EOMLayoutView *vbox2 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 336, 482)]);
  [vbox2 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSSplitView *splitView3 = AUTORELEASE ([[NSSplitView alloc] initWithFrame: NSMakeRect (0, 0, 324, 412)]);
  [splitView3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [splitView3 setVertical: NO];
  EOMLayoutView *vbox4 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 312, 232)]);
  [vbox4 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSScrollView *scrollView5 = AUTORELEASE ([[NSScrollView alloc] initWithFrame: NSMakeRect (0, 0, 300, 220)]);
  [scrollView5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [scrollView5 setHasVerticalScroller: YES];
  [scrollView5 setHasHorizontalScroller: NO];
  [scrollView5 setBorderType: NSBezelBorder];
  NSTableView *tableView = AUTORELEASE ([[NSTableView alloc] initWithFrame: NSMakeRect (0, 0, 160, 100)]);
  [tableView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [tableView setUsesAlternatingRowBackgroundColors: YES];
  [tableView setAllowsEmptySelection: NO];
  [tableView setAllowsColumnSelection: NO];
  [tableView setDrawsGrid: YES];
  NSTableColumn *tableColumn7 = AUTORELEASE ([[NSTableColumn alloc] initWithIdentifier: @"key"]);
  [[tableColumn7 headerCell] setStringValue: @"Key"];
  [tableColumn7 setMinWidth: 100];
  NSTableColumn *tableColumn8 = AUTORELEASE ([[NSTableColumn alloc] initWithIdentifier: @"value"]);
  [[tableColumn8 headerCell] setStringValue: @"Value"];
  [tableColumn8 setEditable: YES];
  [tableColumn8 setMinWidth: 100];
  [tableView addTableColumn: tableColumn7];
  [tableView addTableColumn: tableColumn8];
  [scrollView5 setDocumentView: tableView];
  [tableView setFrame: [[scrollView5 contentView] bounds]];
  [scrollView5 setFrame: NSMakeRect (6, 6, 300, 220)];
  [vbox4 addSubview: scrollView5];
  [scrollView5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *vbox9 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 312, 162)]);
  [vbox9 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSScrollView *scrollView10 = AUTORELEASE ([[NSScrollView alloc] initWithFrame: NSMakeRect (0, 0, 300, 150)]);
  [scrollView10 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [scrollView10 setHasVerticalScroller: YES];
  [scrollView10 setHasHorizontalScroller: NO];
  [scrollView10 setBorderType: NSBezelBorder];
  NSTextView *textView = AUTORELEASE ([[NSTextView alloc] initWithFrame: NSMakeRect (0, 0, 160, 100)]);
  [textView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [textView setVerticallyResizable: YES];
  [textView setMinSize: NSMakeSize (0, 0)];
  [textView setMaxSize: NSMakeSize (1000000, 1000000)];
  [scrollView10 setDocumentView: textView];
  [textView setFrame: [[scrollView10 contentView] bounds]];
  [scrollView10 setFrame: NSMakeRect (6, 6, 300, 150)];
  [vbox9 addSubview: scrollView10];
  [scrollView10 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [vbox4 setFrame: NSMakeRect (6, 174, 312, 232)];
  [splitView3 addSubview: vbox4];
  [vbox4 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [vbox9 setFrame: NSMakeRect (6, 6, 312, 162)];
  [splitView3 addSubview: vbox9];
  [vbox9 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [splitView3 adjustSubviews];
  EOMLayoutView *grid12 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 190, 52)]);
  [grid12 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *gridRow13 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 178, 40)]);
  [gridRow13 setHorizontal: YES];
  [gridRow13 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSButton *button14 = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 80, 28)]);
  [button14 setButtonType: NSMomentaryPushInButton];
  [button14 setTitle: @"Add"];
  [button14 setTarget: owner];
  [button14 setAction: NSSelectorFromString (@"add:")];
  NSButton *button15 = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 80, 28)]);
  [button15 setButtonType: NSMomentaryPushInButton];
  [button15 setTitle: @"Remove"];
  [button15 setTarget: owner];
  [button15 setAction: NSSelectorFromString (@"remove:")];
  [button14 setFrame: NSMakeRect (6, 6, 80, 28)];
  [gridRow13 addSubview: button14];
  [button14 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [button15 setFrame: NSMakeRect (92, 6, 80, 28)];
  [gridRow13 addSubview: button15];
  [button15 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [gridRow13 setFrame: NSMakeRect (6, 6, 178, 40)];
  [grid12 addSubview: gridRow13];
  [gridRow13 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [splitView3 setFrame: NSMakeRect (6, 64, 324, 412)];
  [vbox2 addSubview: splitView3];
  [splitView3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [grid12 setFrame: NSMakeRect (6, 6, 324, 52)];
  [vbox2 addSubview: grid12];
  [grid12 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [window setContentView: vbox2];
  [owner setValue: window forKey: @"window"];
  [owner setValue: tableView forKey: @"tableView"];
  [owner setValue: textView forKey: @"textView"];
  [owner awakeFromNib];
}

@end
