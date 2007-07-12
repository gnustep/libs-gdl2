/**
  EOMInspector.m <title>EOMInspector Class</title>
  
  Copyright (C) 2005 Free Software Foundation, Inc.
 
  Author: Matt Rice <ratmice@gmail.com>
  Date: April 2005
  
  This file is part of the GNUstep Database Library.
  
  <license>
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 3 of the License, or (at your option) any later version.
 
  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.
 
  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
  </license>
**/

#include <AppKit/AppKit.h>
#include "EOModeler/EOMInspector.h"
#include "EOModeler/EOMInspectorController.h"
#include "EOModeler/EOModelerApp.h"
#include "EOModeler/EOModelerEditor.h"
#include <Foundation/NSArray.h>
static NSMapTable *_inspectorsByClass;


@implementation EOMInspector

- (id) init
{
  self = [super init];

  return self;
}

/* this method currently assumes that allRegisteredInspectors has been called *after* all bundles have been loaded. */

+ (NSArray *) allRegisteredInspectors
{
  if (!_inspectorsByClass)
    {
      NSArray *inspectorClasses = GSObjCAllSubclassesOfClass([self class]);
      int i,c;
      _inspectorsByClass = NSCreateMapTableWithZone(NSObjectMapKeyCallBacks,
		      				    NSObjectMapValueCallBacks,
						    [inspectorClasses count],
						    [self zone]);

      for (i = 0, c = [inspectorClasses count]; i < c; i++)
	{
	  [[inspectorClasses objectAtIndex:i] sharedInspector];
	}
    }

  return [NSAllMapTableValues(_inspectorsByClass) sortedArrayUsingSelector:@selector(_compareDisplayOrder:)];
}

+ (NSArray *) allInspectorsThatCanInspectObject:(id)selectedObject
{
  int i,c;
  NSMutableArray *inspectors = [[NSMutableArray alloc] init];
  NSArray *_allInspectors = [self allRegisteredInspectors];
  
  for (i = 0, c = [_allInspectors count]; i < c; i++)
    {
      id gadget = [_allInspectors objectAtIndex:i];
      
      if ([gadget canInspectObject:selectedObject])
	{
	  [inspectors addObject:gadget];
	}
    }
  return inspectors;
}

+ (EOMInspector *)sharedInspector
{
  EOMInspector *_sharedInspector = NSMapGet(_inspectorsByClass, [self class]);
  
  if (!_sharedInspector)
    {
      id foo = [[self alloc] init];
      NSMapInsert(_inspectorsByClass,[self class], foo);
      _sharedInspector = foo;
    }
      
  return _sharedInspector;
}

+ (BOOL) usesControlActionForValidation
{
  return YES; 
}

+ (NSArray *) selectionBeingValidated
{
  return nil; // FIXME
}

- (NSString *) displayName
{
  return [window title];
}

- (NSImage *) image
{
  if (!image)
    image = [NSImage imageNamed:NSStringFromClass([self class])];
  return image;
}

- (NSImage *) hilightedImage
{
  return [self image];
}

- (float) displayOrder
{
  return 10.0;
}

- (NSComparisonResult) _compareDisplayOrder:(EOMInspector *)inspector
{
  float itsResult, myResult;

  myResult = [self displayOrder];
  itsResult = [inspector displayOrder];
  
  return (myResult < itsResult)
	 ? NSOrderedAscending 
	 : (myResult == itsResult)
	   ? NSOrderedSame
	   : NSOrderedDescending;

}

- (BOOL) canInspectObject:(id)selectedObject
{
  return NO; 
}

- (void) load
{
  if (![NSBundle loadNibNamed:NSStringFromClass([self class])
	    owner: self])
      NSLog(@"failed to load: %@.gorm", NSStringFromClass([self class]));
}

- (void) unload
{

}

- (void) prepareForDisplay
{
  if (!view)
    {
      [self load];
    }
}

/* returns the 'view' ivar if it exists otherwise the 'window' ivars content view */
- (NSView *) view
{
  /* yes we leak this but these live throughout the applictions lifespan,
   * we'll only leak one because inspectors are singletons.
   * and theres no good way to release it in all cases. */
  if (!view && window)
    view = RETAIN([window contentView]);
  
  return view;
}

- (void) refresh
{
  return;
}

- (NSArray *) selectedObjects
{
  NSArray *sel = [[EOMApp currentEditor] selectionWithinViewedObject];
  if (![sel count])
    sel = [NSArray arrayWithObject: 
	    	[[[EOMApp currentEditor] viewedObjectPath] lastObject]];
  return sel;
}

- (id) selectedObject
{
  NSArray *selection = [[EOMApp currentEditor] selectionWithinViewedObject];
  
  if ([selection count])
    return [selection objectAtIndex:0];
  else
    return [[[EOMApp currentEditor] viewedObjectPath] lastObject]; 
}

- (BOOL) isAdvanced
{
  return NO;
}


@end
