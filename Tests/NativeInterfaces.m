/* Native model editor interface smoke test.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#import <AppKit/AppKit.h>
#import <GNUstepBase/GNUstep.h>
#import "EOModeler/EOMInterface.h"
#import "EOModeler/EOMLayoutView.h"

@interface InterfaceOwner : NSObject
{
  NSMutableDictionary *outlets;
  BOOL awake;
}

- (BOOL) isAwake;

@end

@implementation InterfaceOwner

- (id) init
{
  self = [super init];
  if (self)
    outlets = [[NSMutableDictionary alloc] init];
  return self;
}

- (void) setValue: (id)value forUndefinedKey: (NSString *)key
{
  NSCAssert (value != nil, @"Missing outlet %@", key);
  [outlets setObject: value forKey: key];
}

- (void) addWindowController: (NSWindowController *)controller
{
  [outlets setObject: controller forKey: @"controller"];
}

- (void) awakeFromNib
{
  awake = YES;
}

- (BOOL) isAwake
{
  return awake;
}

- (NSInteger) outlineView: (NSOutlineView *)view numberOfChildrenOfItem: (id)item
{
  return 0;
}

- (id) outlineView: (NSOutlineView *)view child: (NSInteger)index ofItem: (id)item
{
  return nil;
}

- (BOOL) outlineView: (NSOutlineView *)view isItemExpandable: (id)item
{
  return NO;
}

- (NSInteger) browser: (NSBrowser *)browser numberOfRowsInColumn: (NSInteger)column
{
  return 0;
}

- (void) browser: (NSBrowser *)browser willDisplayCell: (id)cell
          atRow: (NSInteger)row column: (NSInteger)column
{
}

- (void) dealloc
{
  DESTROY (outlets);
  DEALLOC;
}

@end

static void
CheckLayout (void)
{
  EOMLayoutView *layout = AUTORELEASE ([[EOMLayoutView alloc]
    initWithFrame: NSMakeRect (0, 0, 300, 246)]);
  NSScrollView *scroll = AUTORELEASE ([[NSScrollView alloc]
    initWithFrame: NSMakeRect (6, 40, 288, 200)]);
  NSButton *button = AUTORELEASE ([[NSButton alloc]
    initWithFrame: NSMakeRect (6, 6, 288, 28)]);

  [layout addSubview: scroll];
  [layout addSubview: button];
  [layout setFrameSize: NSMakeSize (500, 446)];
  NSCAssert ([scroll frame].size.height == 400, @"Scroll view must grow");
  NSCAssert ([button frame].size.height == 28, @"Button must keep its height");
  NSCAssert ([scroll frame].size.width == 488, @"Content must fill width");
  NSCAssert (NSMaxY ([button frame]) < NSMinY ([scroll frame]), @"Views overlap");
}

int
main (int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL (pool);
  NSArray *names;
  NSEnumerator *enumerator;
  NSString *name;

  [NSApplication sharedApplication];
  CheckLayout ();
  names = [NSArray arrayWithObjects: @"Menu-GNUstep", @"Menu-Cocoa",
    @"ConsistencyResults", @"SQLGenerator", @"AttributeInspector",
#ifndef LEGACY_EDITOR
    @"DataBrowser", @"EOMEDocument",
    @"AdvancedAttributeInspector",
    @"EntityInspector", @"AdvancedEntityInspector",
    @"RelationshipInspector", @"AdvancedRelationshipInspector",
    @"StoredProcedureInspector", @"EntityStoredProcedureInspector",
    @"ConnectionDictionaryInspector", @"UserInfoInspector",
#endif
    nil];
  enumerator = [names objectEnumerator];
  while ((name = [enumerator nextObject]) != nil)
    {
      InterfaceOwner *owner = AUTORELEASE ([[InterfaceOwner alloc] init]);
      @try
        {
          NSCAssert (EOMLoadInterface (name, owner), @"Cannot build %@", name);
        }
      @catch (NSException *exception)
        {
          NSLog (@"Failed %@: %@", name, exception);
          return 1;
        }
      NSCAssert ([owner isAwake], @"Owner not awakened for %@", name);
      NSLog (@"Built %@", name);
    }
  NSCAssert ([[NSApp mainMenu] numberOfItems] > 0, @"Missing main menu");
  RELEASE (pool);
  return 0;
}

