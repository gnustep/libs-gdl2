/** -*-ObjC-*-
   EOMatrixAssociation.h

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
*/

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSButtonCell.h>
#include <AppKit/NSMatrix.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include "EOControlAssociation.h"
#include "EOMatrixAssociation.h"
#include "EODisplayGroup.h"
#include "SubclassFlags.h"

@implementation EOMatrixAssociation

+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"enabled", @"image", @"title", nil];
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
      _keys
        = RETAIN ([[super objectKeysTaken] arrayByAddingObject: @"target"]);
    }
  return _keys;
}

+ (BOOL)isUsableWithObject: (id)object
{
  return [object isKindOfClass: [NSMatrix class]];
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

+ (NSString *)displayName
{
  return @"EOMatrixAssoc";
}

+ (NSString *)primaryAspect
{
  return @"title";
}

- (void)establishConnection
{

  EODisplayGroup *dg;
  if ((dg = [self displayGroupForAspect:@"image"]))
    { 
      subclassFlags |= ImageAspectMask;
      NSArray *dispObj = [dg displayedObjects];
      int c = [dispObj count];
      int rows = [_object numberOfRows];
      int i;

      if (rows < c)
        {
          [_object renewRows:[[dg displayedObjects] count] columns:1];
        }
      else if (rows > c)
        {
          while (rows != c)
            {
              [_object removeRow:0];
              rows--;
            }
        }
      [_object sizeToFit];
      for (i = 0; i < c; i++)
        {
          NSCell *cell = [_object cellAtRow:i column:0]; // column 0???  
          [cell setImage: [self valueForAspect:@"image" atIndex:i]];
        }
    }

  if ((dg = [self displayGroupForAspect:@"title"]))
    {
      subclassFlags |= TitleAspectMask;
      NSArray *dispObj = [dg displayedObjects];
      int c = [dispObj count];
      int rows = [_object numberOfRows];
      int i;

      if (rows < c)
        {
          [_object renewRows:[[dg displayedObjects] count] columns:1];
        }
      else if (rows > c)
        {
          while (rows != c)
            {
              [_object removeRow:0];
              rows--;
            }
        }
      for (i = 0; i < c; i++)
        {
          NSCell *cell = [_object cellAtRow:i column:0]; // column 0???  
          [cell setTitle: [self valueForAspect:@"title" atIndex:i]];
        }
    }
  [_object sizeToFit];
  [_object sizeToCells];
  [_object setNeedsDisplay:YES];
  if ([self displayGroupForAspect:@"enabled"])
    {
      subclassFlags |= EnabledAspectMask;
    }
  [super establishConnection];
  [self subjectChanged]; 
}
- (void)breakConnection
{
  subclassFlags = 0;
  [super breakConnection];
}

- (void)subjectChanged
{
  EODisplayGroup *dg;
  if (subclassFlags & EnabledAspectMask)
    {
      dg = [self displayGroupForAspect:@"enabled"];
      if ([dg selectionChanged] || [dg contentsChanged])
        [_object setEnabled: [[self valueForAspect:@"enabled"] boolValue]];
    }

  if (subclassFlags & TitleAspectMask)
    {
      dg = [self displayGroupForAspect:@"title"];
      if ([dg selectionChanged] || [dg contentsChanged])
        {
	  NSArray *dispObj = [dg displayedObjects];
	  int c = [dispObj count];
	  int rows = [_object numberOfRows];
	  int i;

	  if (rows < c)
	    { 
	      [_object renewRows:[[dg displayedObjects] count] columns:1];
	    }
	  else if (rows > c)
	    {
	      while (rows != c)
	        {
	          [_object removeRow:0];
		  rows--;
		}
	    }
	  for (i = 0; i < c; i++)
	    {
	      NSCell *cell = [_object cellAtRow:i column:0]; // column 0???  
	      [cell setTitle: [self valueForAspect:@"title" atIndex:i]];
	    }
          [_object sizeToFit];
	  [_object sizeToCells];
	  [_object setNeedsDisplay:YES];
	}
    }

  if (subclassFlags & ImageAspectMask)
    {
      dg = [self displayGroupForAspect:@"image"];
      if ([dg selectionChanged] || [dg contentsChanged])
        {
          NSArray *dispObj = [dg displayedObjects];
          int c = [dispObj count];
          int rows = [_object numberOfRows];
	  int i;

          if (rows < c)
            { 
              [_object renewRows:[[dg displayedObjects] count] columns:1];
	    } 
          else if (rows > c)
            {
              while (rows != c)
                {
                  [_object removeRow:0];
                  rows--;
                }
            }
	  for (i = 0; i < c; i++)
            {
              NSCell *cell = [_object cellAtRow:i column:0]; // column 0???  
              [cell setImage: [self valueForAspect:@"image" atIndex:i]];
	    }
          [_object sizeToFit];
	  [_object sizeToCells];
	  [_object setNeedsDisplay:YES];
        }
    }
}

@end
