/** 
   EOKeyValueQualifier.m <title>EOKeyValueQualifier Class</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: November 2001

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   </license>
**/

static char rcsId[] = "$Id$";

#import <Foundation/Foundation.h>

#import <EOControl/EOQualifier.h>
#import <EOControl/EOKeyValueCoding.h>
#import <EOControl/EOObjectStore.h>
#import <EOControl/EOObjectStoreCoordinator.h>
#import <EOControl/EOEditingContext.h>
#import <EOControl/EODebug.h>


@implementation EOKeyValueQualifier

+ (EOKeyValueQualifier *)qualifierWithKey: (NSString *)key
			 operatorSelector: (SEL)selector
				    value: (id)value
{
  return [[[self alloc] initWithKey: key
			operatorSelector: selector
			value: value] autorelease];
}

- initWithKey: (NSString *)key
operatorSelector: (SEL)selector
        value: (id)value
{
  //OK
  if ((self = [super init]))
    {
      _selector = selector;
      ASSIGN(_key, key);
      ASSIGN(_value, value);
    }

  return self;
}

- (void)dealloc
{
  DESTROY(_key);
  DESTROY(_value);

  [super dealloc];
}

- (SEL)selector
{
  return _selector;
}

- (NSString *)key
{
  return _key;
}

- (id)value
{
  return _value;
}

- (id)copyWithZone: (NSZone *)zone
{
  EOKeyValueQualifier *qual = [[EOKeyValueQualifier allocWithZone: zone] init];

  qual->_selector = _selector;
  ASSIGN(qual->_key, _key); //Don't copy it [_key copyWithZone:zone];
  ASSIGN(qual->_value, _value); //Don't copy it: if this is a generic record, it isn't copyable [_value copyWithZone:zone];

  return qual;
}

- (BOOL)evaluateWithObject: (id)object
{
  id key;

  key = [object valueForKey: _key];

  if (sel_eq(_selector, EOQualifierOperatorEqual) == YES)
    {
      return [key compare: _value] == NSOrderedSame;
    }
  else if (sel_eq(_selector, EOQualifierOperatorNotEqual) == YES)
    {
      return [key compare: _value] != NSOrderedSame;
    }
  else if (sel_eq(_selector, EOQualifierOperatorLessThan) == YES)
    {
      return [key compare: _value] == NSOrderedAscending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorGreaterThan) == YES)
    {
      return [key compare: _value] == NSOrderedDescending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorLessThanOrEqualTo) == YES)
    {
      return [key compare: _value] != NSOrderedDescending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorGreaterThanOrEqualTo) == YES)
    {
      return [key compare: _value] != NSOrderedAscending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorContains) == YES)
    {
      [self notImplemented: _cmd];
    }
  else if (sel_eq(_selector, EOQualifierOperatorLike) == YES)
    {
      NSEmitTODO();  //TODO
      return [key isEqual: _value] == NSOrderedSame;
    }
  else if (sel_eq(_selector, EOQualifierOperatorCaseInsensitiveLike) == YES)
    {
      NSEmitTODO();  //TODO
      return [[key uppercaseString] isEqual: [_value uppercaseString]]
	== NSOrderedSame;
    }

  return NO;
}

- (NSString *)description
{
/*  //TODO revoir
  NSString *dscr=nil;
  int i=0;
  dscr = [NSString stringWithFormat:@"<%s %p - %@ %@ (%@)%@>",
		   object_get_class_name(self),
		   (void*)self,
                   _key,
                   NSStringFromSelector(_selector),
		   NSStringFromClass([_value class]),
                   _value];
  return dscr;
*/

  return [NSString stringWithFormat:@"<%s %p - %@ %@ (%@)'%@'>",
		   object_get_class_name(self),
		   (void*)self,
		   _key,
		   [isa stringForOperatorSelector:_selector],
		   NSStringFromClass([_value class]),
		   _value];
}


- (id) validateKeysWithRootClassDescription: (id)param0
{
  return [self notImplemented: _cmd]; //TODO
}

- (id) initWithKeyValueUnarchiver: (id)param0
{
  return [self notImplemented: _cmd]; //TODO
}

- (void) encodeWithKeyValueArchiver: (id)param0
{
  [self notImplemented: _cmd]; //TODO
}

- (void) _addBindingsToDictionary: (id)param0
{
  [self notImplemented: _cmd]; //TODO
}

- (EOQualifier *) qualifierWithBindings: (NSDictionary*)bindings
		   requiresAllVariables: (BOOL)requiresAllVariables
{
  EOFLOGObjectLevelArgs(@"EOQualifier", @"bindings=%@", bindings);

  if ([bindings count] > 0)
    {
      NSEmitTODO();  
      return [self notImplemented: _cmd]; //TODO
    }
  else 
    return self;
}

- (EOQualifier *) qualifierMigratedFromEntity: (id)param0
                  relationshipPath: (id)param1
{
  return [self notImplemented: _cmd]; //TODO
}

@end

@implementation EOKeyValueQualifier (EOKeyValueArchiving)

- (id) initWithKeyValueUnarchiver: (EOKeyValueUnarchiver*)unarchiver
{
  EOFLOGObjectFnStartOrCond(@"EOQualifier");

  if ((self = [self init]))
    {
      NSString *selectorName = [unarchiver decodeObjectForKey: @"selectorName"];

      if (selectorName) 
        _selector = NSSelectorFromString(selectorName);
      
      ASSIGN(_key, [unarchiver decodeObjectForKey: @"key"]);
      ASSIGN(_value, [unarchiver decodeObjectForKey: @"value"]);
    }
  
  EOFLOGObjectFnStopOrCond(@"EOQualifier");

  return self;
}

- (void) encodeWithKeyValueArchiver: (EOKeyValueUnarchiver*)archiver
{
  [self notImplemented: _cmd];
}

@end
