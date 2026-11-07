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
  id<NSMenuItem> menuItem3 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"About EOModelEditor" action: NSSelectorFromString (@"orderFrontStandardAboutPanel:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem4 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Preferences..." action: NSSelectorFromString (@"openPrefs:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem5 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Help..." action: NSSelectorFromString (@"orderFrontHelpPanel:") keyEquivalent: @""]);
  [menu2 addItem: menuItem3];
  [menu2 addItem: menuItem4];
  [menu2 addItem: menuItem5];
  NSMenu *menu6 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Model"]);
  [menu6 setTitle: @"Model"];
  id<NSMenuItem> menuItem7 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"New..." action: NSSelectorFromString (@"new:") keyEquivalent: @"n"]);
  id<NSMenuItem> menuItem8 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"New From Database..." action: NSSelectorFromString (@"newFromDatabase:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem9 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Open" action: NSSelectorFromString (@"openDocument:") keyEquivalent: @"o"]);
  id<NSMenuItem> menuSeparator10 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem11 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Save" action: NSSelectorFromString (@"saveDocument:") keyEquivalent: @"s"]);
  id<NSMenuItem> menuItem12 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Save As..." action: NSSelectorFromString (@"saveDocumentAs:") keyEquivalent: @"S"]);
  id<NSMenuItem> menuItem13 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Revert to Saved" action: NSSelectorFromString (@"revert:") keyEquivalent: @"u"]);
  id<NSMenuItem> menuSeparator14 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem15 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Set Adaptor Info..." action: NSSelectorFromString (@"setAdaptor:") keyEquivalent: @"I"]);
  id<NSMenuItem> menuItem16 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Switch Adaptor..." action: NSSelectorFromString (@"switchAdaptor:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem17 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Check Consistency..." action: NSSelectorFromString (@"checkConsistency:") keyEquivalent: @""]);
  [menu6 addItem: menuItem7];
  [menu6 addItem: menuItem8];
  [menu6 addItem: menuItem9];
  [menu6 addItem: menuSeparator10];
  [menu6 addItem: menuItem11];
  [menu6 addItem: menuItem12];
  [menu6 addItem: menuItem13];
  [menu6 addItem: menuSeparator14];
  [menu6 addItem: menuItem15];
  [menu6 addItem: menuItem16];
  [menu6 addItem: menuItem17];
  NSMenu *menu18 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Edit"]);
  [menu18 setTitle: @"Edit"];
  [menu18 setAutoenablesItems: YES];
  id<NSMenuItem> menuItem19 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Undo" action: NSSelectorFromString (@"undo:") keyEquivalent: @"z"]);
  id<NSMenuItem> menuItem20 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Redo" action: NSSelectorFromString (@"redo:") keyEquivalent: @"Z"]);
  id<NSMenuItem> menuSeparator21 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem22 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Cut" action: NSSelectorFromString (@"cut:") keyEquivalent: @"x"]);
  id<NSMenuItem> menuItem23 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Copy" action: NSSelectorFromString (@"copy:") keyEquivalent: @"c"]);
  id<NSMenuItem> menuItem24 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Paste" action: NSSelectorFromString (@"paste:") keyEquivalent: @"v"]);
  id<NSMenuItem> menuItem25 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"SelectAll" action: NSSelectorFromString (@"selectAll:") keyEquivalent: @"a"]);
  [menu18 addItem: menuItem19];
  [menu18 addItem: menuItem20];
  [menu18 addItem: menuSeparator21];
  [menu18 addItem: menuItem22];
  [menu18 addItem: menuItem23];
  [menu18 addItem: menuItem24];
  [menu18 addItem: menuItem25];
  NSMenu *menu26 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Property"]);
  [menu26 setTitle: @"Property"];
  [menu26 setAutoenablesItems: YES];
  id<NSMenuItem> menuItem27 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Entity" action: NSSelectorFromString (@"addEntity:") keyEquivalent: @"E"]);
  id<NSMenuItem> menuItem28 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Attribute" action: NSSelectorFromString (@"addAttribute:") keyEquivalent: @"A"]);
  id<NSMenuItem> menuItem29 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Relationship" action: NSSelectorFromString (@"addRelationship:") keyEquivalent: @"R"]);
  id<NSMenuItem> menuItem30 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Procedure" action: NSSelectorFromString (@"addProcedure:") keyEquivalent: @"P"]);
  id<NSMenuItem> menuItem31 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Delete" action: NSSelectorFromString (@"delete:") keyEquivalent: @""]);
  [menu26 addItem: menuItem27];
  [menu26 addItem: menuItem28];
  [menu26 addItem: menuItem29];
  [menu26 addItem: menuItem30];
  [menu26 addItem: menuItem31];
  NSMenu *menu32 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Tools"]);
  [menu32 setTitle: @"Tools"];
  id<NSMenuItem> menuItem33 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Inspector" action: NSSelectorFromString (@"showInspector:") keyEquivalent: @"i"]);
  id<NSMenuItem> menuItem34 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Generate SQL" action: NSSelectorFromString (@"generateSQL:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem35 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Generate ObjC Files.." action: NSSelectorFromString (@"createTemplates:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem36 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"DataBrowser" action: NSSelectorFromString (@"dataBrowser:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem37 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Diagram Editor" action: NSSelectorFromString (@"showEditor:") keyEquivalent: @""]);
  [menu32 addItem: menuItem33];
  [menu32 addItem: menuItem34];
  [menu32 addItem: menuItem35];
  [menu32 addItem: menuItem36];
  [menu32 addItem: menuItem37];
  NSMenu *menu38 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Services"]);
  [menu38 setTitle: @"Services"];
  [NSApp setServicesMenu: menu38];
  NSMenu *menu39 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Windows"]);
  [menu39 setTitle: @"Windows"];
  id<NSMenuItem> menuItem40 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Arrange" action: NSSelectorFromString (@"arrangeInFront:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem41 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Miniaturize" action: NSSelectorFromString (@"performMiniaturize:") keyEquivalent: @"m"]);
  id<NSMenuItem> menuItem42 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Close" action: NSSelectorFromString (@"performClose:") keyEquivalent: @"w"]);
  [menu39 addItem: menuItem40];
  [menu39 addItem: menuItem41];
  [menu39 addItem: menuItem42];
  [NSApp setWindowsMenu: menu39];
  id<NSMenuItem> menuItem43 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Hide" action: NSSelectorFromString (@"hide:") keyEquivalent: @"h"]);
  id<NSMenuItem> menuItem44 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Quit" action: NSSelectorFromString (@"terminate:") keyEquivalent: @"q"]);
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu2 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu2];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu6 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu6];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu18 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu18];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu26 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu26];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu32 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu32];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu38 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu38];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu39 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu39];
    [menu1 addItem: item];
  }
  [menu1 addItem: menuItem43];
  [menu1 addItem: menuItem44];
  [NSApp setMainMenu: menu1];
  [owner awakeFromNib];
}

@end
