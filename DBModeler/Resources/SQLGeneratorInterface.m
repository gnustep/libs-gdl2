/* Native AppKit interface for SQLGenerator.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_SQLGenerator : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_SQLGenerator

+ (void) buildForOwner: (id)owner
{
  NSWindow *sqlgenWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect (0, 0, 476, 582) styleMask: (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask) backing: NSBackingStoreBuffered defer: NO];
  [sqlgenWindow setReleasedWhenClosed: NO];
  [sqlgenWindow setTitle: @"SQL Generation"];
  EOMLayoutView *vbox2 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 476, 582)]);
  [vbox2 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSBox *box3 = AUTORELEASE ([[NSBox alloc] initWithFrame: NSMakeRect (0, 0, 464, 218)]);
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box3 setTitle: @"SQL Generation Options"];
  EOMLayoutView *hbox4 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 448, 188)]);
  [hbox4 setHorizontal: YES];
  [hbox4 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *vbox5 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 208, 108)]);
  [vbox5 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSButton *dropDatabase = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 119, 28)]);
  [dropDatabase setButtonType: NSSwitchButton];
  [dropDatabase setTitle: @"Drop Database"];
  [dropDatabase setTarget: owner];
  [dropDatabase setAction: NSSelectorFromString (@"switchChanged:")];
  NSButton *dropTables = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 105, 28)]);
  [dropTables setButtonType: NSSwitchButton];
  [dropTables setTitle: @"Drop Tables"];
  [dropTables setTarget: owner];
  [dropTables setAction: NSSelectorFromString (@"switchChanged:")];
  NSButton *dropPKSupport = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 196, 28)]);
  [dropPKSupport setButtonType: NSSwitchButton];
  [dropPKSupport setTitle: @"Drop Primary Key Support"];
  [dropPKSupport setTarget: owner];
  [dropPKSupport setAction: NSSelectorFromString (@"switchChanged:")];
  [dropDatabase setFrame: NSMakeRect (6, 74, 196, 28)];
  [vbox5 addSubview: dropDatabase];
  [dropDatabase setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [dropTables setFrame: NSMakeRect (6, 40, 196, 28)];
  [vbox5 addSubview: dropTables];
  [dropTables setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [dropPKSupport setFrame: NSMakeRect (6, 6, 196, 28)];
  [vbox5 addSubview: dropPKSupport];
  [dropPKSupport setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  EOMLayoutView *vbox9 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 222, 176)]);
  [vbox9 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSButton *createDB = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 133, 28)]);
  [createDB setButtonType: NSSwitchButton];
  [createDB setTitle: @"Create Database"];
  [createDB setTarget: owner];
  [createDB setAction: NSSelectorFromString (@"switchChanged:")];
  NSButton *createTables = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 119, 28)]);
  [createTables setButtonType: NSSwitchButton];
  [createTables setTitle: @"Create Tables"];
  [createTables setTarget: owner];
  [createTables setAction: NSSelectorFromString (@"switchChanged:")];
  NSButton *createPKConstraints = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 189, 28)]);
  [createPKConstraints setButtonType: NSSwitchButton];
  [createPKConstraints setTitle: @"Primary Key Constraints"];
  [createPKConstraints setTarget: owner];
  [createPKConstraints setAction: NSSelectorFromString (@"switchChanged:")];
  NSButton *createFKConstraints = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 189, 28)]);
  [createFKConstraints setButtonType: NSSwitchButton];
  [createFKConstraints setTitle: @"Foreign Key Constraints"];
  [createFKConstraints setTarget: owner];
  [createFKConstraints setAction: NSSelectorFromString (@"switchChanged:")];
  NSButton *createPKSupport = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 210, 28)]);
  [createPKSupport setButtonType: NSSwitchButton];
  [createPKSupport setTitle: @"Create Primary Key Support"];
  [createPKSupport setTarget: owner];
  [createPKSupport setAction: NSSelectorFromString (@"switchChanged:")];
  [createDB setFrame: NSMakeRect (6, 142, 210, 28)];
  [vbox9 addSubview: createDB];
  [createDB setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [createTables setFrame: NSMakeRect (6, 108, 210, 28)];
  [vbox9 addSubview: createTables];
  [createTables setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [createPKConstraints setFrame: NSMakeRect (6, 74, 210, 28)];
  [vbox9 addSubview: createPKConstraints];
  [createPKConstraints setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [createFKConstraints setFrame: NSMakeRect (6, 40, 210, 28)];
  [vbox9 addSubview: createFKConstraints];
  [createFKConstraints setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [createPKSupport setFrame: NSMakeRect (6, 6, 210, 28)];
  [vbox9 addSubview: createPKSupport];
  [createPKSupport setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [vbox5 setFrame: NSMakeRect (6, 6, 208, 176)];
  [hbox4 addSubview: vbox5];
  [vbox5 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [vbox9 setFrame: NSMakeRect (220, 6, 222, 176)];
  [hbox4 addSubview: vbox9];
  [vbox9 setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [box3 setContentView: hbox4];
  NSScrollView *scrollView15 = AUTORELEASE ([[NSScrollView alloc] initWithFrame: NSMakeRect (0, 0, 425, 300)]);
  [scrollView15 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [scrollView15 setHasVerticalScroller: YES];
  [scrollView15 setHasHorizontalScroller: NO];
  [scrollView15 setBorderType: NSBezelBorder];
  NSTextView *sqlOutput = AUTORELEASE ([[NSTextView alloc] initWithFrame: NSMakeRect (0, 0, 160, 100)]);
  [sqlOutput setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [sqlOutput setVerticallyResizable: YES];
  [sqlOutput setMinSize: NSMakeSize (0, 0)];
  [sqlOutput setMaxSize: NSMakeSize (1000000, 1000000)];
  [scrollView15 setDocumentView: sqlOutput];
  [sqlOutput setFrame: [[scrollView15 contentView] bounds]];
  EOMLayoutView *hbox17 = AUTORELEASE ([[EOMLayoutView alloc] initWithFrame: NSMakeRect (0, 0, 339, 40)]);
  [hbox17 setHorizontal: YES];
  [hbox17 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  NSButton *executeSQL = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 115, 28)]);
  [executeSQL setButtonType: NSMomentaryPushInButton];
  [executeSQL setTitle: @"Execute SQL"];
  [executeSQL setTarget: owner];
  [executeSQL setAction: NSSelectorFromString (@"executeSQL:")];
  NSButton *saveAs = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 100, 28)]);
  [saveAs setButtonType: NSMomentaryPushInButton];
  [saveAs setTitle: @"Save As..."];
  [saveAs setTarget: owner];
  [saveAs setAction: NSSelectorFromString (@"saveAs:")];
  NSButton *tables = AUTORELEASE ([[NSButton alloc] initWithFrame: NSMakeRect (0, 0, 100, 28)]);
  [tables setButtonType: NSMomentaryPushInButton];
  [tables setTitle: @"Tables..."];
  [tables setTarget: owner];
  [tables setAction: NSSelectorFromString (@"showTables:")];
  [executeSQL setFrame: NSMakeRect (6, 6, 115, 28)];
  [hbox17 addSubview: executeSQL];
  [executeSQL setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [saveAs setFrame: NSMakeRect (127, 6, 100, 28)];
  [hbox17 addSubview: saveAs];
  [saveAs setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [tables setFrame: NSMakeRect (233, 6, 100, 28)];
  [hbox17 addSubview: tables];
  [tables setAutoresizingMask: NSViewHeightSizable | NSViewMaxXMargin];
  [box3 setFrame: NSMakeRect (6, 358, 464, 218)];
  [vbox2 addSubview: box3];
  [box3 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [scrollView15 setFrame: NSMakeRect (6, 52, 464, 300)];
  [vbox2 addSubview: scrollView15];
  [scrollView15 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [hbox17 setFrame: NSMakeRect (6, 6, 464, 40)];
  [vbox2 addSubview: hbox17];
  [hbox17 setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [sqlgenWindow setContentView: vbox2];
  [owner setValue: sqlgenWindow forKey: @"window"];
  [owner setValue: dropDatabase forKey: @"dropDatabaseSwitch"];
  [owner setValue: createDB forKey: @"createDatabaseSwitch"];
  [owner setValue: dropTables forKey: @"dropTablesSwitch"];
  [owner setValue: createTables forKey: @"createTablesSwitch"];
  [owner setValue: dropPKSupport forKey: @"dropPKSwitch"];
  [owner setValue: createPKSupport forKey: @"createPKSwitch"];
  [owner setValue: createPKConstraints forKey: @"createPKConstraintsSwitch"];
  [owner setValue: createFKConstraints forKey: @"createFKConstraintsSwitch"];
  [owner setValue: sqlOutput forKey: @"sqlOutput"];
  [owner awakeFromNib];
  [sqlgenWindow orderFront: nil];
}

@end
