/* Native AppKit interface for Menu-GNUstep.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <EOModeler/EOMLayoutView.h>
#import <GNUstepBase/GNUstep.h>

@interface EOMInterface_Menu_GNUstep : NSObject

+ (void) buildForOwner: (id)owner;

@end

@implementation EOMInterface_Menu_GNUstep

+ (void) buildForOwner: (id)owner
{
  NSMenu *menu1 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @""]);
  [menu1 setAutoenablesItems: YES];
  NSMenu *menu2 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Info"]);
  [menu2 setTitle: @"Info"];
  [menu2 setAutoenablesItems: YES];
  id<NSMenuItem> menuItem3 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"About DBModeler" action: NSSelectorFromString (@"orderFrontStandardAboutPanel:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem4 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Info Panel..." action: NSSelectorFromString (@"orderFrontStandardInfoPanel:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem5 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Preferences..." action: NSSelectorFromString (@"openPrefs:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem6 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Help..." action: NSSelectorFromString (@"orderFrontHelpPanel:") keyEquivalent: @""]);
  [menu2 addItem: menuItem3];
  [menu2 addItem: menuItem4];
  [menu2 addItem: menuItem5];
  [menu2 addItem: menuItem6];
  NSMenu *menu7 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Model"]);
  [menu7 setTitle: @"Model"];
  id<NSMenuItem> menuItem8 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"New..." action: NSSelectorFromString (@"new:") keyEquivalent: @"n"]);
  id<NSMenuItem> menuItem9 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"New From Database..." action: NSSelectorFromString (@"newFromDatabase:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem10 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Open" action: NSSelectorFromString (@"open:") keyEquivalent: @"o"]);
  id<NSMenuItem> menuSeparator11 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem12 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Save" action: NSSelectorFromString (@"save:") keyEquivalent: @"s"]);
  id<NSMenuItem> menuItem13 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Save As..." action: NSSelectorFromString (@"saveAs:") keyEquivalent: @"S"]);
  id<NSMenuItem> menuItem14 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Revert to Saved" action: NSSelectorFromString (@"revert:") keyEquivalent: @"u"]);
  id<NSMenuItem> menuSeparator15 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem16 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Set Adaptor Info..." action: NSSelectorFromString (@"setAdaptor:") keyEquivalent: @"I"]);
  id<NSMenuItem> menuItem17 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Switch Adaptor..." action: NSSelectorFromString (@"switchAdaptor:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem18 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Check Consistency..." action: NSSelectorFromString (@"checkConsistency:") keyEquivalent: @""]);
  [menu7 addItem: menuItem8];
  [menu7 addItem: menuItem9];
  [menu7 addItem: menuItem10];
  [menu7 addItem: menuSeparator11];
  [menu7 addItem: menuItem12];
  [menu7 addItem: menuItem13];
  [menu7 addItem: menuItem14];
  [menu7 addItem: menuSeparator15];
  [menu7 addItem: menuItem16];
  [menu7 addItem: menuItem17];
  [menu7 addItem: menuItem18];
  NSMenu *menu19 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Edit"]);
  [menu19 setTitle: @"Edit"];
  [menu19 setAutoenablesItems: YES];
  id<NSMenuItem> menuItem20 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Cut" action: NSSelectorFromString (@"cut:") keyEquivalent: @"x"]);
  id<NSMenuItem> menuItem21 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Copy" action: NSSelectorFromString (@"copy:") keyEquivalent: @"c"]);
  id<NSMenuItem> menuItem22 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Paste" action: NSSelectorFromString (@"paste:") keyEquivalent: @"v"]);
  id<NSMenuItem> menuItem23 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"SelectAll" action: NSSelectorFromString (@"selectAll:") keyEquivalent: @"a"]);
  [menu19 addItem: menuItem20];
  [menu19 addItem: menuItem21];
  [menu19 addItem: menuItem22];
  [menu19 addItem: menuItem23];
  NSMenu *menu24 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Property"]);
  [menu24 setTitle: @"Property"];
  [menu24 setAutoenablesItems: YES];
  id<NSMenuItem> menuItem25 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Entity" action: NSSelectorFromString (@"addEntity:") keyEquivalent: @"E"]);
  id<NSMenuItem> menuItem26 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Attribute" action: NSSelectorFromString (@"addAttribute:") keyEquivalent: @"A"]);
  id<NSMenuItem> menuItem27 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Relationship" action: NSSelectorFromString (@"addRelationship:") keyEquivalent: @"R"]);
  id<NSMenuItem> menuItem28 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Delete" action: NSSelectorFromString (@"delete:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem29 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Generate ObjC Files.." action: NSSelectorFromString (@"createTemplate:") keyEquivalent: @""]);
  [menu24 addItem: menuItem25];
  [menu24 addItem: menuItem26];
  [menu24 addItem: menuItem27];
  [menu24 addItem: menuItem28];
  [menu24 addItem: menuItem29];
  NSMenu *menu30 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Tools"]);
  [menu30 setTitle: @"Tools"];
  id<NSMenuItem> menuItem31 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Inspector" action: NSSelectorFromString (@"showInspector:") keyEquivalent: @"i"]);
  id<NSMenuItem> menuItem32 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Generate SQL" action: NSSelectorFromString (@"generateSQL:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem33 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Table Editor" action: NSSelectorFromString (@"showEditor:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem34 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Diagram Editor" action: NSSelectorFromString (@"showEditor:") keyEquivalent: @""]);
  [menu30 addItem: menuItem31];
  [menu30 addItem: menuItem32];
  [menu30 addItem: menuItem33];
  [menu30 addItem: menuItem34];
  NSMenu *menu35 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Services"]);
  [menu35 setTitle: @"Services"];
  [NSApp setServicesMenu: menu35];
  NSMenu *menu36 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Windows"]);
  [menu36 setTitle: @"Windows"];
  id<NSMenuItem> menuItem37 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Arrange" action: NSSelectorFromString (@"arrangeInFront:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem38 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Miniaturize" action: NSSelectorFromString (@"performMiniaturize:") keyEquivalent: @"m"]);
  id<NSMenuItem> menuItem39 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Close" action: NSSelectorFromString (@"performClose:") keyEquivalent: @"w"]);
  [menu36 addItem: menuItem37];
  [menu36 addItem: menuItem38];
  [menu36 addItem: menuItem39];
  [NSApp setWindowsMenu: menu36];
  id<NSMenuItem> menuItem40 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Hide" action: NSSelectorFromString (@"hide:") keyEquivalent: @"h"]);
  id<NSMenuItem> menuItem41 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Quit" action: NSSelectorFromString (@"terminate:") keyEquivalent: @"q"]);
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu2 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu2];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu7 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu7];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu19 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu19];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu24 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu24];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu30 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu30];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu35 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu35];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu36 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu36];
    [menu1 addItem: item];
  }
  [menu1 addItem: menuItem40];
  [menu1 addItem: menuItem41];
  [NSApp setMainMenu: menu1];
  [owner awakeFromNib];
}

@end
