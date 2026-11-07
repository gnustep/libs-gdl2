/* Native AppKit interface for ConsistencyResults.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_ConsistencyResults : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_ConsistencyResults

+ (void) buildForOwner: (id)owner
{
  NSPanel *resultsPanel = [[NSPanel alloc] initWithContentRect: NSMakeRect (0, 0, 512, 258) styleMask: (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask) backing: NSBackingStoreBuffered defer: NO];
  [resultsPanel setReleasedWhenClosed: NO];
  [resultsPanel setTitle: @"Consistency Results"];
  EOMLayoutView *vbox2 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 512, 258)]);
  [vbox2 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSScrollView *scrollView3 = AUTORELEASE ([[NSScrollView alloc] initWithFrame: NSMakeRect (0, 0, 500, 200)]);
  [scrollView3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [scrollView3 setHasVerticalScroller: YES];
  [scrollView3 setHasHorizontalScroller: YES];
  [scrollView3 setBorderType: NSBezelBorder];
  NSTextView *resultsTextView = AUTORELEASE ([[NSTextView alloc] initWithFrame: NSMakeRect (0, 0, 160, 100)]);
  [resultsTextView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [resultsTextView setVerticallyResizable: YES];
  [resultsTextView setMinSize: NSMakeSize (0, 0)];
  [resultsTextView setMaxSize: NSMakeSize (1000000, 1000000)];
  [scrollView3 setDocumentView: resultsTextView];
  [resultsTextView setFrame: [[scrollView3 contentView] bounds]];
  EOMLayoutView *hbox5 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 178, 40)]);
  [hbox5 setHorizontal: YES];
  [hbox5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSButton *cancelBut = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 80, 28)]);
  [cancelBut setButtonType: NSMomentaryPushInButton];
  [cancelBut setTitle: @"Cancel"];
  [cancelBut setTarget: owner];
  [cancelBut setAction: NSSelectorFromString (@"cancel:")];
  NSButton *okBut = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 80, 28)]);
  [okBut setButtonType: NSMomentaryPushInButton];
  [okBut setTitle: @"Ok"];
  [okBut setTarget: owner];
  [okBut setAction: NSSelectorFromString (@"ok:")];
  [cancelBut setFrame: NSMakeRect (6, 6, 80, 28)];
  [hbox5 addSubview: cancelBut];
  [cancelBut setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [okBut setFrame: NSMakeRect (92, 6, 80, 28)];
  [hbox5 addSubview: okBut];
  [okBut setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [scrollView3 setFrame: NSMakeRect (6, 52, 500, 200)];
  [vbox2 addSubview: scrollView3];
  [scrollView3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [hbox5 setFrame: NSMakeRect (6, 6, 500, 40)];
  [vbox2 addSubview: hbox5];
  [hbox5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [resultsPanel setContentView: vbox2];
  [owner setValue: resultsPanel forKey: @"panel"];
  [owner setValue: okBut forKey: @"okButton"];
  [owner setValue: cancelBut forKey: @"cancelButton"];
  [owner setValue: resultsTextView forKey: @"results"];
  [owner awakeFromNib];
  [resultsPanel orderFront: nil];
}

@end
