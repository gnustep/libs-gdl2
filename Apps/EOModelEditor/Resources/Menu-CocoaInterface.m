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
  id<NSMenuItem> menuItem3 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"About EOModelEditor" action: NSSelectorFromString (@"orderFrontStandardAboutPanel:") keyEquivalent: @""]);
  id<NSMenuItem> menuSeparator4 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem5 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Preferences..." action: NSSelectorFromString (@"openPrefs:") keyEquivalent: @","]);
  id<NSMenuItem> menuSeparator6 = [NSMenuItem separatorItem];
  NSMenu *menu7 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Services"]);
  [menu7 setTitle: @"Services"];
  [NSApp setServicesMenu: menu7];
  id<NSMenuItem> menuSeparator8 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem9 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Hide EOModelEditor" action: NSSelectorFromString (@"hide:") keyEquivalent: @"h"]);
  id<NSMenuItem> menuItem10 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Hide Others" action: NSSelectorFromString (@"hideOtherApplications:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem11 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Show All" action: NSSelectorFromString (@"unhideAllApplications:") keyEquivalent: @""]);
  id<NSMenuItem> menuSeparator12 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem13 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Quit EOModelEditor" action: NSSelectorFromString (@"terminate:") keyEquivalent: @"q"]);
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
  [menu14 setAutoenablesItems: YES];
  id<NSMenuItem> menuItem15 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"New..." action: NSSelectorFromString (@"new:") keyEquivalent: @"n"]);
  id<NSMenuItem> menuItem16 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"New From Database..." action: NSSelectorFromString (@"newFromDatabase:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem17 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Open" action: NSSelectorFromString (@"openDocument:") keyEquivalent: @"o"]);
  id<NSMenuItem> menuSeparator18 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem19 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Save" action: NSSelectorFromString (@"saveDocument:") keyEquivalent: @"s"]);
  id<NSMenuItem> menuItem20 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Save As..." action: NSSelectorFromString (@"saveDocumentAs:") keyEquivalent: @"S"]);
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
  id<NSMenuItem> menuItem27 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Undo" action: NSSelectorFromString (@"undo:") keyEquivalent: @"z"]);
  id<NSMenuItem> menuItem28 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Redo" action: NSSelectorFromString (@"redo:") keyEquivalent: @"Z"]);
  id<NSMenuItem> menuSeparator29 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem30 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Cut" action: NSSelectorFromString (@"cut:") keyEquivalent: @"x"]);
  id<NSMenuItem> menuItem31 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Copy" action: NSSelectorFromString (@"copy:") keyEquivalent: @"c"]);
  id<NSMenuItem> menuItem32 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Paste" action: NSSelectorFromString (@"paste:") keyEquivalent: @"v"]);
  id<NSMenuItem> menuItem33 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"SelectAll" action: NSSelectorFromString (@"selectAll:") keyEquivalent: @"a"]);
  [menu26 addItem: menuItem27];
  [menu26 addItem: menuItem28];
  [menu26 addItem: menuSeparator29];
  [menu26 addItem: menuItem30];
  [menu26 addItem: menuItem31];
  [menu26 addItem: menuItem32];
  [menu26 addItem: menuItem33];
  NSMenu *menu34 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Property"]);
  [menu34 setTitle: @"Property"];
  [menu34 setAutoenablesItems: YES];
  id<NSMenuItem> menuItem35 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Entity" action: NSSelectorFromString (@"addEntity:") keyEquivalent: @"E"]);
  id<NSMenuItem> menuItem36 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Attribute" action: NSSelectorFromString (@"addAttribute:") keyEquivalent: @"A"]);
  id<NSMenuItem> menuItem37 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Relationship" action: NSSelectorFromString (@"addRelationship:") keyEquivalent: @"R"]);
  id<NSMenuItem> menuItem38 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Add Procedure" action: NSSelectorFromString (@"addProcedure:") keyEquivalent: @"P"]);
  id<NSMenuItem> menuItem39 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Delete" action: NSSelectorFromString (@"delete:") keyEquivalent: @""]);
  [menu34 addItem: menuItem35];
  [menu34 addItem: menuItem36];
  [menu34 addItem: menuItem37];
  [menu34 addItem: menuItem38];
  [menu34 addItem: menuItem39];
  NSMenu *menu40 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Tools"]);
  [menu40 setTitle: @"Tools"];
  id<NSMenuItem> menuItem41 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Inspector" action: NSSelectorFromString (@"showInspector:") keyEquivalent: @"i"]);
  id<NSMenuItem> menuItem42 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Generate SQL" action: NSSelectorFromString (@"generateSQL:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem43 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Generate ObjC Files.." action: NSSelectorFromString (@"createTemplates:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem44 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"DataBrowser" action: NSSelectorFromString (@"dataBrowser:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem45 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Diagram Editor" action: NSSelectorFromString (@"showEditor:") keyEquivalent: @""]);
  [menu40 addItem: menuItem41];
  [menu40 addItem: menuItem42];
  [menu40 addItem: menuItem43];
  [menu40 addItem: menuItem44];
  [menu40 addItem: menuItem45];
  NSMenu *menu46 = AUTORELEASE ([[NSMenu alloc] initWithTitle: @"Windows"]);
  [menu46 setTitle: @"Windows"];
  id<NSMenuItem> menuItem47 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Close Window" action: NSSelectorFromString (@"performClose:") keyEquivalent: @"w"]);
  id<NSMenuItem> menuItem48 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Zoom Window" action: NSSelectorFromString (@"zoom:") keyEquivalent: @""]);
  id<NSMenuItem> menuItem49 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Miniaturize Window" action: NSSelectorFromString (@"performMiniaturize:") keyEquivalent: @"m"]);
  id<NSMenuItem> menuSeparator50 = [NSMenuItem separatorItem];
  id<NSMenuItem> menuItem51 = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: @"Bring All to Front" action: NSSelectorFromString (@"arrangeInFront:") keyEquivalent: @""]);
  [menu46 addItem: menuItem47];
  [menu46 addItem: menuItem48];
  [menu46 addItem: menuItem49];
  [menu46 addItem: menuSeparator50];
  [menu46 addItem: menuItem51];
  [NSApp setWindowsMenu: menu46];
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
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu34 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu34];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu40 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu40];
    [menu1 addItem: item];
  }
  {
    id<NSMenuItem> item = AUTORELEASE ([[NSMenuItem alloc] initWithTitle: [menu46 title] action: NULL keyEquivalent: @""]);
    [item setSubmenu: menu46];
    [menu1 addItem: item];
  }
  [NSApp setMainMenu: menu1];
  [owner awakeFromNib];
}

@end
