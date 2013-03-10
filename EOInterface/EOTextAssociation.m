/**
   EOTextAssociation.m

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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include <GNUstepBase/GNUstep.h>
#include "EODisplayGroup.h"
#include "EOTextAssociation.h"
#include "SubclassFlags.h"
#include "../EOControl/EOPrivate.h"
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
      NSArray *arr = [NSArray arrayWithObjects:@"A", @"A", @"A", nil];
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
  [super establishConnection];
  if ([self displayGroupForAspect:@"value"])
    {
      subclassFlags |= ValueAspectMask;
      if (subclassFlags & ValueAspectMask)
	{
	  id value = [self valueForAspect:@"value"];
	  if ([value isKindOfClass:[NSString class]])
	    {
	      [_object setString:value];
	    }
	  else if ([value isKindOfClass:[NSData class]])
	    {
	      int oldLength = [[_object string] length];
	      [_object replaceCharactersInRange:NSMakeRange(0,oldLength)
					withRTF:value];
	    }
	}
    }
  if ([self displayGroupForAspect:@"editable"])
    {
      subclassFlags |= EditableAspectMask;
      [_object setEditable: [[self valueForAspect:@"editable"] boolValue]];
    }
  [_object setDelegate:self]; 
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
      id value = [self valueForAspect:@"value"];
      if ([value isKindOfClass: [NSString class]])
        {
          [_object setString:value];
	}
      else if ([value isKindOfClass: [NSData class]])
        {
	  int oldLength = [[_object string] length];
	  [_object replaceCharactersInRange:NSMakeRange(0,oldLength)
	  		withRTF: value];
	  
	}
      else if (_isNilOrEONull(value))
        {
	  [_object setString:@""];
        }
    }
  if (subclassFlags & EditableAspectMask)
    {
      [_object setEditable: [[self valueForAspect:@"editable"] boolValue]];
    }
}

- (BOOL)endEditing
{
  BOOL flag = NO;
  
  if (subclassFlags & ValueAspectMask)
    {
      BOOL isRichText = [_object isRichText];
      id value;
      if (isRichText)
        {
          value = [_object RTFFromRange:NSMakeRange(0,[[_object string] length])];
	}
      else
        {
	  value = [[_object string] copy];
	}
      flag = [self setValue:value forAspect:@"value"];
      if (flag)
        {
	  [[self displayGroupForAspect:@"value"] associationDidEndEditing:self];       }
    }
  /* dunno if this is neccesary */
  if (flag && (subclassFlags & EditableAspectMask))
    {
      [[self displayGroupForAspect:@"editable"] associationDidEndEditing:self];
    }
  return flag;
}

- (BOOL)control:(NSControl *)control isValidObject:(id)object
{
  /* FIXME */
  NSLog(@"FIXME %@",NSStringFromSelector(_cmd));
  return YES;
}

- (void)control: (NSControl *)control
didFailToValidatePartialString: (NSString *)string
errorDescription: (NSString *)description
{
}

- (BOOL)textShouldBeginEditing: (NSText *) text
{
  EODisplayGroup *dg = [self displayGroupForAspect:@"value"];
  BOOL flag = [dg endEditing];
  if (flag == YES)
    {
      [dg associationDidBeginEditing:self];
    }
  return flag;
}

- (BOOL)textShouldEndEditing: (NSText *)text
{
  [self endEditing];
  [[self displayGroupForAspect:@"value"] associationDidEndEditing:self];
  return YES;
}

@end
