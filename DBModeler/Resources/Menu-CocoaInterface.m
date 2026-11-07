/* Native AppKit interface for Menu-Cocoa.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_Menu_Cocoa : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_Menu_Cocoa

+ (void) buildForOwner: (id)owner
{
  NSMenu *menu1 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @""]);
  [menu1 setAutoenablesItems: YES];
  NSMenu *menu2 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Info"]);
  [menu2 setTitle: @"Info"];
  [menu2 setAutoenablesItems: YES];
  id<NSMenuItem> menuItem3 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"About DBModeler" action: NSSelectorFromString (@"orderFrontStandardAboutPanel:") keyEquivalent: @""]);
  id<NSMenuItem> menuSeparator4 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem5 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Preferences..." action: NSSelectorFromString (@"openPrefs:") keyEquivalent: @","]);
  id<NSMenuItem> menuSeparator6 = [NSMenuItem separatorItem];
  NSMenu *menu7 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Services"]);
  [menu7 setTitle: @"Services"];
  [NSApp setServicesMenu: menu7];
  id<NSMenuItem> menuSeparator8 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem9 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Hide DBModeler" action: NSSelectorFromString (@"hide:") keyEquivalent: @"h"]);
  id<NSMenuItem> menuItem10 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Hide Others" action: NSSelectorFromString (@"hideOtherApplications:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem11 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Show All" action: NSSelectorFromString (@"unhideAllApplications:") keyEquivalent: @""]);
  id<NSMenuItem> menuSeparator12 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem13 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Quit DBModeler" action: NSSelectorFromString (@"terminate:") keyEquivalent: @"q"]);
  [menu2 addItem: menuItem3];
  [menu2 addItem: menuSeparator4];
  [menu2 addItem: menuItem5];
  [menu2 addItem: menuSeparator6];
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu7 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu7];
    [menu2 addItem: item];
  }
  [menu2 addItem: menuSeparator8];
  [menu2 addItem: menuItem9];
  [menu2 addItem: menuItem10];
  [menu2 addItem: menuItem11];
  [menu2 addItem: menuSeparator12];
  [menu2 addItem: menuItem13];
  NSMenu *menu14 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Model"]);
  [menu14 setTitle: @"Model"];
  id<NSMenuItem> menuItem15 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"New..." action: NSSelectorFromString (@"new:") keyEquivalent: @"n"]);
  id<NSMenuItem> menuItem16 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"New From Database..." action: NSSelectorFromString (@"newFromDatabase:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem17 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Open" action: NSSelectorFromString (@"open:") keyEquivalent: @"o"]);
  id<NSMenuItem> menuSeparator18 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem19 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Save" action: NSSelectorFromString (@"save:") keyEquivalent: @"s"]);
  id<NSMenuItem> menuItem20 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Save As..." action: NSSelectorFromString (@"saveAs:") keyEquivalent: @"S"]);
  id<NSMenuItem> menuItem21 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Revert to Saved" action: NSSelectorFromString (@"revert:") keyEquivalent: @"u"]);
  id<NSMenuItem> menuSeparator22 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem23 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Set Adaptor Info..." action: NSSelectorFromString (@"setAdaptor:") keyEquivalent: @"I"]);
  id<NSMenuItem> menuItem24 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Switch Adaptor..." action: NSSelectorFromString (@"switchAdaptor:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem25 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Check Consistency..." action: NSSelectorFromString (@"checkConsistency:") keyEquivalent: @""]);
  [menu14 addItem: menuItem15];
  [menu14 addItem: menuItem16];
  [menu14 addItem: menuItem17];
  [menu14 addItem: menuSeparator18];
  [menu14 addItem: menuItem19];
  [menu14 addItem: menuItem20];
  [menu14 addItem: menuItem21];
  [menu14 addItem: menuSeparator22];
  [menu14 addItem: menuItem23];
  [menu14 addItem: menuItem24];
  [menu14 addItem: menuItem25];
  NSMenu *menu26 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Edit"]);
  [menu26 setTitle: @"Edit"];
  [menu26 setAutoenablesItems: YES];
  id<NSMenuItem> menuItem27 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Cut" action: NSSelectorFromString (@"cut:") keyEquivalent: @"x"]);
  id<NSMenuItem> menuItem28 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Copy" action: NSSelectorFromString (@"copy:") keyEquivalent: @"c"]);
  id<NSMenuItem> menuItem29 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Paste" action: NSSelectorFromString (@"paste:") keyEquivalent: @"v"]);
  id<NSMenuItem> menuItem30 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"SelectAll" action: NSSelectorFromString (@"selectAll:") keyEquivalent: @"a"]);
  [menu26 addItem: menuItem27];
  [menu26 addItem: menuItem28];
  [menu26 addItem: menuItem29];
  [menu26 addItem: menuItem30];
  NSMenu *menu31 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Property"]);
  [menu31 setTitle: @"Property"];
  [menu31 setAutoenablesItems: YES];
  id<NSMenuItem> menuItem32 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Entity" action: NSSelectorFromString (@"addEntity:") keyEquivalent: @"E"]);
  id<NSMenuItem> menuItem33 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Attribute" action: NSSelectorFromString (@"addAttribute:") keyEquivalent: @"A"]);
  id<NSMenuItem> menuItem34 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Relationship" action: NSSelectorFromString (@"addRelationship:") keyEquivalent: @"R"]);
  id<NSMenuItem> menuItem35 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Delete" action: NSSelectorFromString (@"delete:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem36 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Generate ObjC Files.." action: NSSelectorFromString (@"createTemplate:") keyEquivalent: @""]);
  [menu31 addItem: menuItem32];
  [menu31 addItem: menuItem33];
  [menu31 addItem: menuItem34];
  [menu31 addItem: menuItem35];
  [menu31 addItem: menuItem36];
  NSMenu *menu37 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Tools"]);
  [menu37 setTitle: @"Tools"];
  id<NSMenuItem> menuItem38 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Inspector" action: NSSelectorFromString (@"showInspector:") keyEquivalent: @"i"]);
  id<NSMenuItem> menuItem39 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Generate SQL" action: NSSelectorFromString (@"generateSQL:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem40 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Table Editor" action: NSSelectorFromString (@"showEditor:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem41 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Diagram Editor" action: NSSelectorFromString (@"showEditor:") keyEquivalent: @""]);
  [menu37 addItem: menuItem38];
  [menu37 addItem: menuItem39];
  [menu37 addItem: menuItem40];
  [menu37 addItem: menuItem41];
  NSMenu *menu42 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Windows"]);
  [menu42 setTitle: @"Windows"];
  id<NSMenuItem> menuItem43 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Close Window" action: NSSelectorFromString (@"performClose:") keyEquivalent: @"w"]);
  id<NSMenuItem> menuItem44 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Zoom Window" action: NSSelectorFromString (@"zoom:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem45 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Miniaturize Window" action: NSSelectorFromString (@"performMiniaturize:") keyEquivalent: @"m"]);
  id<NSMenuItem> menuSeparator46 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem47 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Bring All to Front" action: NSSelectorFromString (@"arrangeInFront:") keyEquivalent: @""]);
  [menu42 addItem: menuItem43];
  [menu42 addItem: menuItem44];
  [menu42 addItem: menuItem45];
  [menu42 addItem: menuSeparator46];
  [menu42 addItem: menuItem47];
  [NSApp setWindowsMenu: menu42];
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu2 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu2];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu14 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu14];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu26 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu26];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu31 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu31];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu37 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu37];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu42 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu42];
    [menu1 addItem: item];
  }
  [NSApp setMainMenu: menu1];
  [owner awakeFromNib];
}

@end
