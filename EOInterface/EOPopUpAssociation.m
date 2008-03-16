/**
   EOPopUpAssociation.m

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 3, 
   or (at your option) any later version.

   The GNUstep Database Library is distributed in the hope that it will be 
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License 
   along with the GNUstep Database Library; see the file COPYING. If not, 
   write to the Free Software Foundation, Inc., 
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
*/

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSPopUpButton.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include <GNUstepBase/GNUstep.h>
#include "EOControlAssociation.h"
#include "EODisplayGroup.h"
#include "EOPopUpAssociation.h"
#include "SubclassFlags.h"

@implementation EOPopUpAssociation

+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"titles", @"selectedTitle", @"selectedTag",
			      @"selectedObject", @"enabled", nil];
      _aspects = RETAIN ([[super aspects] arrayByAddingObjectsFromArray: arr]);
    }
  return _aspects;
}
+ (NSArray *)aspectSignatures
{
  static NSArray *_signatures = nil;
  if (_signatures == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"A", @"A", @"A", @"1", @"A", nil];
      arr = [[super aspectSignatures] arrayByAddingObjectsFromArray: arr];
      _signatures = RETAIN(arr);
    }
  return _signatures;
}

+ (NSArray *)objectKeysTaken
{
  static NSArray *_keys = nil;
  if (_keys == nil)
    {
      _keys = [[NSArray alloc] initWithObject: @"target"];
    }
  return _keys;
}
+ (BOOL)isUsableWithObject: (id)object
{
  return [object isKindOfClass: [NSPopUpButton class]];
}

+ (NSArray *)associationClassesSuperseded
{
  static NSArray *_classes = nil;
  if (_classes == nil)
    {
      _classes
        = RETAIN ([[super associationClassesSuperseded]
                    arrayByAddingObject: [EOControlAssociation class]]);
    }
  return _classes;
}

- (id) initWithObject:(id)obj
{
  self = [super initWithObject:obj];
  _tagValueForOther = -1; 
  return self;
}

+ (NSString *)displayName
{
  return @"EOPopupAssoc";
}

+ (NSString *)primaryAspect
{
  return @"selectedTitle";
}

- (void)establishConnection
{
  EODisplayGroup *dg;
  [super establishConnection];
  if ((dg = [self displayGroupForAspect:@"titles"]))
    {
      int i,c;
      NSArray *dispObj;
      
      subclassFlags |= TitlesAspectMask;
      dispObj = [dg displayedObjects];
      c = [dispObj count];
      [_object removeAllItems];
      for (i = 0; i < c; i++)
        {
          [_object addItemWithTitle: [self valueForAspect:@"titles" atIndex:i]];
	  /* hmm used in _action.... :*/
          [[_object lastItem] setRepresentedObject:[dg valueForObjectAtIndex:i
		       				        key:@"self"]];
	}
    }
  if ([self displayGroupForAspect:@"selectedTitle"])
    {
      subclassFlags |= SelectedTitleAspectMask;
    }
  if ([self displayGroupForAspect:@"selectedTag"])
    {
      subclassFlags |= SelectedTagAspectMask;
    }
  if ([self displayGroupForAspect:@"selectedObject"])
    {
      subclassFlags |= SelectedObjectAspectMask;
    }
  if ([self displayGroupForAspect:@"enabled"])
    {
      subclassFlags |= EnabledAspectMask;
    }

  if (((subclassFlags & SelectedTitleAspectMask) 
        && (subclassFlags & (SelectedTagAspectMask | SelectedObjectAspectMask)))
      || ((subclassFlags & SelectedTagAspectMask)
       	  && (subclassFlags & (SelectedObjectAspectMask | SelectedTitleAspectMask))))
    {
      [[NSException exceptionWithName:NSInternalInconsistencyException 
	 reason:[NSString stringWithFormat:@"more than one selectedTag, %@ %@",
	        @"selectedTitle, or selectedObject aspect bound to %@", self]
       userInfo:nil] raise];
    }
  [_object setTarget:self];
  [_object setAction:@selector(_action:)];
}

- (void)breakConnection
{
  subclassFlags = 0;
  [super breakConnection];
}

- (void)subjectChanged
{
  EODisplayGroup *dg;
  
  if (subclassFlags & TitlesAspectMask)
    {
      dg = [self displayGroupForAspect:@"titles"];
      if ([dg contentsChanged])
        {
	  int i,c;
	  NSArray *dispObj;

          dispObj = [dg displayedObjects];
          c = [dispObj count];
	  [_object removeAllItems];
          for (i = 0; i < c; i++)
            { 
              [_object addItemWithTitle: [self valueForAspect:@"titles" atIndex:i]];
               /* hmm */
              [[_object lastItem] setRepresentedObject:[dg valueForObjectAtIndex:i 
								key:@"self"]];
            }
	}
    }

  if (subclassFlags & SelectedTagAspectMask)
    {
      dg = [self displayGroupForAspect:@"selectedTag"];
      
      if ([dg selectionChanged] || [dg contentsChanged])
        {
	  int tag = [[self valueForAspect:@"selectedTag"] intValue];

	  [_object selectItemAtIndex:tag];
	}
    }
  else if (subclassFlags & SelectedTitleAspectMask)
    {
      dg = [self displayGroupForAspect:@"selectedTitle"];
      if ([dg selectionChanged] || [dg contentsChanged])
        {
	  [_object selectItemWithTitle:[self valueForAspect:@"selectedTitle"]];
	}
    }
  else if (subclassFlags & SelectedObjectAspectMask)
    {
      dg = [self displayGroupForAspect:@"selectedObject"];
      if ([dg selectionChanged] || [dg contentsChanged])
        { 
          NSString *titlesKey;
	  NSString *newTitle;
	  titlesKey = [self displayGroupKeyForAspect:@"titles"];
	  newTitle = [[self valueForAspect:@"selectedObject"] 
	  					valueForKey:titlesKey];
	  
          [_object selectItemWithTitle:newTitle];
	}
    }

  if (subclassFlags & EnabledAspectMask)
    {
      dg = [self displayGroupForAspect:@"enabled"];
      if ([dg selectionChanged] || [dg contentsChanged])
        [_object setEnabled: [[self valueForAspect:@"enabled"] boolValue]];
    } 
}

- (void)setTagValueForOther: (int)value
{
  _tagValueForOther = value;
}

- (int)tagValueForOther
{
  return _tagValueForOther;
}

- (void) _action:(id)sender
{
  if (subclassFlags & SelectedTagAspectMask)
    {
      [self setValue: [NSNumber numberWithInt: [[_object itemAtIndex: [_object indexOfSelectedItem]] tag]] 
	   forAspect:@"selectedTag"];
    }
  else if (subclassFlags & SelectedTitleAspectMask)
    {
      [self setValue: [_object titleOfSelectedItem] forAspect:@"selectedTitle"];
    } 
  else if (subclassFlags & SelectedObjectAspectMask)
    { 
      id obj = [[_object itemAtIndex:[_object indexOfSelectedItem]] representedObject];
      [self setValue: obj forAspect:@"selectedObject"];
    
    }
}
@end
