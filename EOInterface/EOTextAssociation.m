/**
   EOTextAssociation.m

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
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSControl.h>
#include <AppKit/NSText.h>
#include <AppKit/NSTextView.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include "EOTextAssociation.h"

@implementation EOTextAssociation

+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"value", @"URL", @"editable", nil];
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
        = RETAIN ([[super objectKeysTaken] arrayByAddingObject: @"delegate"]);
    }
  return _keys;
}
+ (BOOL)isUsableWithObject: (id)object
{
  /* NB: NSCStringText is obsolete.  So unless someone asks for it,
     ignore it for now.  */
  return [object isKindOfClass: [NSText class]]
    || [object isKindOfClass: [NSTextView class]];
}

+ (NSString *)primaryAspect
{
  return @"value";
}

- (void)establishConnection
{
}
- (void)breakConnection
{
}

- (void)subjectChanged
{
}
- (BOOL)endEditing
{
  return NO;
}

- (BOOL)control: (NSControl *)control isValidObject: (id)object
{
  return NO;
}

- (void)control: (NSControl *)control
didFailToValidatePartialString: (NSString *)string
errorDescription: (NSString *)description
{
}

- (BOOL)textShouldBeginEditing: (NSText *) text
{
  return NO;
}
- (BOOL)textShouldEndEditing: (NSText *)text
{
  return NO;
}

@end
