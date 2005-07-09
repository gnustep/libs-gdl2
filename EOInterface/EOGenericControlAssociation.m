/**
   EOGenericControlAssociation.h

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: David Ayers <d.ayers@inode.at>

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 2, 
   or (at your option) any later version.

   The GNUstep Database Library is distributed in the hope that it will be 
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License 
   along with the GNUstep Database Library; see the file COPYING. If not, 
   write to the Free Software Foundation, Inc., 
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 
*/


#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>

#include <AppKit/NSControl.h>
#include <AppKit/NSText.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include "EOControlAssociation.h"
#include "EODisplayGroup.h"
#include "SubclassFlags.h"

@implementation EOGenericControlAssociation
+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"value", @"enabled", @"URL", nil];
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
                                @"A", @"A", @"A", nil];
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
      _keys = [[NSArray alloc] initWithObjects: @"delegate", @"target", nil];
    }
  return _keys;
}

+ (BOOL)isUsableWithObject: (id)object
{
  return NO;
}

- (void)establishConnection
{
  [super establishConnection];
  
  if ([self displayGroupForAspect:@"value"] != nil) 
    subclassFlags |= ValueAspectMask;
  
  if ([self displayGroupForAspect:@"enabled"] != nil)
    subclassFlags |= EnabledAspectMask;
    
  /* where does URL come from, accident or is it undocumented?? */   
  if ([self displayGroupForAspect:@"URL"] != nil)
    subclassFlags |= URLAspectMask;

  [[self control] setAction:@selector(_action:)];
  [[self control] setTarget:self];
  
  if ([[self object] respondsToSelector: @selector(setDelegate:)])
    [[self object] setDelegate:self];
}

- (void)breakConnection
{
  subclassFlags = 0;
  [super breakConnection];
}

- (void)subjectChanged
{
  if (subclassFlags & ValueAspectMask)
    {
      [[self control] setObjectValue: [self valueForAspect:@"value"]];
    }
  if (subclassFlags & EnabledAspectMask)
    [[self control] setEnabled: [[self valueForAspect: @"enabled"] boolValue]];
  
  [super subjectChanged];
}

- (void) _action: (id)sender
{
  [self endEditing];
}

- (BOOL)endEditing
{
  BOOL flag = NO;

  if (subclassFlags & ValueAspectMask)
    {
      flag = [self setValue: [[self control] objectValue] forAspect: @"value"]; 
      [[self displayGroupForAspect:@"value"] associationDidEndEditing: self];
    }
  /* not sure if this is neccessary */
  if (subclassFlags & EnabledAspectMask)
    {
      [[self displayGroupForAspect:@"enabled"] associationDidEndEditing: self];
    }
  return flag;
}

- (NSControl *)control
{
  return nil;
}

- (EOGenericControlAssociation *)editingAssociation
{
  return nil;
}

- (BOOL)control: (NSControl *)control
didFailToFormatString: (NSString *)string
errorDescription: (NSString *)description
{
  return NO;
}

- (BOOL)control: (NSControl *)control
  isValidObject: (id)object
{
  return NO;
}

- (BOOL)control: (NSControl *)control
textShouldBeginEditing: (NSText *)fieldEditor
{
  EODisplayGroup *dg = nil;
  BOOL flag = NO;
  
  /* inform display groups for all aspects that the editing association should
     change if multiple aspects are bound to the same display group only do so
     one time */
  if (subclassFlags & ValueAspectMask)
    {
      dg = [self displayGroupForAspect:@"value"];
      flag = [dg endEditing];
      if (flag == YES)
        {
 	  [dg associationDidBeginEditing:self];
        }
    }
  /* not sure if this is really neccessary */  
  if (subclassFlags & EnabledAspectMask)
    {
      EODisplayGroup *dg2 = [self displayGroupForAspect:@"enabled"];
      if (dg2 != dg || flag == NO)
        {
	  flag = [dg endEditing];
	  if (flag == YES)
	    {
	      [dg2 associationDidBeginEditing:self];
	    }
	}
    } 
   return flag;
}

@end
