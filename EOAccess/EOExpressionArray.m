/** 
   EOExpressionArray.m <title>EOExpressionArray</title>

   Copyright (C) 1996-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>
   Date: September 1996

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#include <ctype.h>

#ifdef GNUSTEP
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#include <GNUstepBase/GSObjCRuntime.h>
#endif

#define GSI_ARRAY_TYPES GSUNION_OBJ
#include <GNUstepBase/GSIArray.h>

#include <EOControl/EODebug.h>

#include <EOAccess/EOEntity.h>
#include <EOAccess/EOExpressionArray.h>
#include <EOAccess/EORelationship.h>


static SEL eqSel;

@interface EOExpressionArray (PrivateExceptions)
- (void) _raiseRangeExceptionWithIndex:(unsigned) index from:(SEL)selector;
@end


@implementation EOExpressionArray

+ (void) initialize
{
 eqSel = NSSelectorFromString(@"isEqual:"); 
}

+ (EOExpressionArray*)expressionArray
{
  return [[self new] autorelease];
}

- (void)dealloc
{
  DESTROY(_realAttribute); //TODO mettere nei metodi GC
//  DESTROY(_definition);
  DESTROY(_prefix);
  DESTROY(_infix);
  DESTROY(_suffix);
  GSIArrayEmpty(_contents);
  NSZoneFree([self zone], _contents);
  [super dealloc];
}

- (id) init
{
  EOFLOGObjectFnStart();

  self = [self initWithCapacity:0];

  EOFLOGObjectFnStop();

  return self;
}

/* designated initializer */
- (id) initWithCapacity:(unsigned)capacity
{
  self = [super init];
  _contents = NSZoneMalloc([self zone], sizeof(GSIArray_t));
  _contents = GSIArrayInitWithZoneAndCapacity(_contents, [self zone], capacity);
  return self;
}

- (id) initWithObjects:(id *)objects count:(unsigned)count
{
  int i;
  self = [self initWithCapacity:count];
  for (i = 0; i < count; i++)
    GSIArrayAddItem(_contents, (GSIArrayItem)objects[i]);
  return self;
}


+ (EOExpressionArray*)expressionArrayWithPrefix: (NSString *)prefix
					  infix: (NSString *)infix
					 suffix: (NSString *)suffix
{
  return [[[self alloc]initWithPrefix: prefix
                       infix: infix
                       suffix: suffix] autorelease];
}

- (id)initWithPrefix: (NSString *)prefix
               infix: (NSString *)infix
              suffix: (NSString *)suffix
{
  EOFLOGObjectFnStart();

  if ((self = [self init]))
    {
      ASSIGN(_prefix, prefix);
      ASSIGN(_infix, infix);
      ASSIGN(_suffix, suffix);
    }

  EOFLOGObjectFnStop();

  return self;
}

- (BOOL)referencesObject: (id)anObject
{
  return [self indexOfObject: anObject] != NSNotFound;
}

- (NSString *)expressionValueForContext: (id<EOExpressionContext>)ctx
{
  if (ctx && [self count]
      && [[self objectAtIndex: 0] isKindOfClass: [EORelationship class]])
    return [ctx expressionValueForAttributePath: self];
  else 
    {
      int i, count = [self count];
      id result = [[NSMutableString new] autorelease];
      SEL sel = @selector(appendString:);
      IMP imp = [result methodForSelector: sel];
      
      if (_prefix)
        [result appendString:_prefix];
      
      if (count) 
        {
          (*imp)(result, sel, [[self objectAtIndex: 0]
                                expressionValueForContext: ctx]);

          for (i = 1 ; i < count; i++) 
            {
              if (_infix)
                (*imp)(result, sel, _infix);
              (*imp)(result, sel, [[self objectAtIndex: i]
                                    expressionValueForContext: ctx]);
            }
        }
      
      if(_suffix)
        [result appendString: _suffix];
      
      return result;
    }
}

- (void)setPrefix: (NSString *)prefix
{
  ASSIGN(_prefix, prefix);
}

- (void)setInfix: (NSString *)infix
{
  ASSIGN(_infix, infix);
}

- (void)setSuffix: (NSString *)suffix
{
  ASSIGN(_suffix, suffix);
}

- (NSString *)prefix
{
  return _prefix;
}

- (NSString *)infix
{
  return _infix;
}

- (NSString *)suffix
{
  return _suffix;
}

- (NSString *)definition
{
//  return _definition;
  return [self valueForSQLExpression: nil];
}

- (BOOL)isFlattened
{
//  return _flags.isFlattened;
  return ([self count] > 1);
}

- (EOAttribute *)realAttribute
{
  return _realAttribute;
}

/*
+ (EOExpressionArray *)parseExpression:(NSString *)expression
                                entity:(EOEntity *)entity
             replacePropertyReferences:(BOOL)replacePropertyReferences
{
  EOExpressionArray *array = nil;
  const char *s = NULL;
  const char *start=NULL;
  id objectToken=nil;
  EOFLOGObjectFnStart();
  NSDebugMLLog(@"gsdb",@"expression=%@",expression);
  NSDebugMLLog(@"gsdb",@"entity=%@",entity);

  array = [[EOExpressionArray new] autorelease];
  s = [expression cString];

//  ASSIGN(array->_definition, expression);
  array->_flags.isFlattened = NO;

  if([expression isNameOfARelationshipPath])
    {
      NSArray  *defArray;
      NSString *realAttributeName;
      int count, i;

      array->_flags.isFlattened = YES;
      defArray = [expression componentsSeparatedByString:@"."];
      count = [defArray count];

      for(i = 0; i < count - 1; i++)
        {
	  id relationshipName = [defArray objectAtIndex:i];
	  id relationship=nil;
            
	  relationship = [entity relationshipNamed:relationshipName];

	  if(!relationship)
	    [NSException raise:NSInvalidArgumentException
                         format:@"%@ -- %@ 0x%x: '%@' for entity '%@' is an invalid property",
                         NSStringFromSelector(_cmd),
                         NSStringFromClass([self class]),
                         self,
                         relationshipName,
                         entity];

	  //	  if([relationship isToMany])
	  //	    [NSException raise:NSInvalidArgumentException format:@"%@ -- %@ 0x%x: '%@' for entity '%@' must be a to one relationship",
          //NSStringFromSelector(_cmd),
          //NSStringFromClass([self class]), 
          //self,
          //relationshipName,
          //entity];

	  [array addObject:relationship];
	  entity = [relationship destinationEntity];
        }
      realAttributeName = [defArray lastObject];
      ASSIGN(array->_realAttribute, [entity attributeNamed:realAttributeName]);

      if(!array->_realAttribute)
	ASSIGN(array->_realAttribute, [entity relationshipNamed:realAttributeName]);

      if(!array->_realAttribute)
	[NSException raise:NSInvalidArgumentException
                     format:@"%@ -- %@ 0x%x: '%@' for entity '%@' is an invalid property",
                     NSStringFromSelector(_cmd),
                     NSStringFromClass([self class]),
                     self,
                     realAttributeName,
                     entity];

      [array addObject:array->_realAttribute];
    }
  else
    {
      //IN eoentity persedescr
    }
  NSDebugMLLog(@"gsdb",@"_prefix=%@",array->_prefix);
  NSDebugMLLog(@"gsdb",@"_infix=%@",array->_infix);
  NSDebugMLLog(@"gsdb",@"_suffix=%@",array->_suffix);
//  NSDebugMLLog(@"gsdb",@"_definition=%@",array->_definition);
  NSDebugMLLog(@"gsdb",@"_realAttribute=%@",array->_realAttribute);

  EOFLOGObjectFnStop();
  return array;
}
*/

- (BOOL)_isPropertyPath
{
/*
  int i=0;
  int count=0;

  count=[self count];
objectAtIndex:i
if it's a string return NO
*/
//TODO

  return NO;
}

- (NSString *)valueForSQLExpression: (EOSQLExpression*)sqlExpression
{
  //TODO verify
  NSMutableString *value = [NSMutableString string];
  volatile int i;
  int count;

  NS_DURING //Just for debugging
    {
      count = [self count];

      for(i = 0; i < count; i++)
        {
          id obj = [self objectAtIndex: i];
          NSString *relValue;

          relValue = [obj valueForSQLExpression: sqlExpression];

          if (i > 0)
            [value appendString: @"."];

          [value appendString: relValue];
        }
    }
  NS_HANDLER
    {
      NSLog(@"exception in EOExpressionArray valueForSQLExpression: self=%p class=%@ i=%d", self, [self class], i);
      NSLog(@"exception in EOExpressionArray valueForSQLExpression: self=%@ class=%@ i=%d", self, [self class], i);
      NSLog(@"exception=%@", localException);

      [localException raise];
    }
  NS_ENDHANDLER;

  return value;
}

/* These are *this* subclasses responsibility */
- (unsigned) count
{
  return GSIArrayCount(_contents);
}

- (id) objectAtIndex:(unsigned) index
{
  if (index >= GSIArrayCount(_contents))
    [self _raiseRangeExceptionWithIndex:index from:_cmd];

  return GSIArrayItemAtIndex(_contents, index).obj;
}

- (void) addObject:(id)object
{
  if (object == nil)
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Attempt to add nil to an array"];
      return;
    }

  GSIArrayAddItem(_contents, (GSIArrayItem)object);
}

- (void) replaceObjectAtIndex:(unsigned)index withObject:(id)object
{
  if (object == nil)
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Attempt to add nil to an array"];
      return;
    }
  else if (index >= GSIArrayCount(_contents))
    {
      [self _raiseRangeExceptionWithIndex:index from:_cmd];
      return;
    }
   
  GSIArraySetItemAtIndex(_contents, (GSIArrayItem)object, index);
}

- (void) insertObject:(id)object atIndex:(unsigned)index
{
  if (object == nil)
    {
      [NSException raise: NSInvalidArgumentException
  		  format: @"Attempt to add nil to an array"];
      return;
    }
  else if (index >= GSIArrayCount(_contents))
    {
      [self _raiseRangeExceptionWithIndex:index from:_cmd];
    }
  
  GSIArrayInsertItem(_contents, (GSIArrayItem)object, index);
}

- (void) removeObjectAtIndex:(unsigned)index
{
  if (index >= GSIArrayCount(_contents))
    {
      [self _raiseRangeExceptionWithIndex:index from:_cmd];
    }
  GSIArrayRemoveItemAtIndex(_contents, index);
}

- (void) removeAllObjects
{
  GSIArrayRemoveAllItems(_contents);
}

/* might as well also implement because we can do it faster */
- (id) lastObject
{
  return GSIArrayLastItem(_contents).obj;
}

- (id) firstObject
{
  if (GSIArrayCount(_contents) == 0)
    return nil;
  return GSIArrayItemAtIndex(_contents, 0).obj;
}

/* not only make it faster but work around for old buggy implementations of
 * NSArray in gnustep with an extra release */
- (void) removeObject:(id)anObject
{
  int index = GSIArrayCount(_contents);
  BOOL (*eq)(id,SEL,id) 
    = (BOOL (*)(id, SEL, id))[anObject methodForSelector:eqSel];
  
  /* iterate backwards, so that all objects equal to 'anObject'
   * can safely be removed from the array while iterating. */
  while (index-- > 0)
    {
      if ((*eq)(anObject, eqSel, GSIArrayItemAtIndex(_contents, index).obj))
        {
	  GSIArrayRemoveItemAtIndex(_contents, index);
	}
    }
}

/* private methods. */
- (void) _raiseRangeExceptionWithIndex: (unsigned)index from: (SEL)sel
{
  NSDictionary *info;
  NSException  *exception;
  NSString     *reason;
  unsigned     count = GSIArrayCount(_contents);

  info = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithUnsignedInt: index], @"Index",
    [NSNumber numberWithUnsignedInt: count], @"Count",
    self, @"Array", nil, nil];

  reason = [NSString stringWithFormat: @"Index %d is out of range %d (in '%@')",    index, count, NSStringFromSelector(sel)];

  exception = [NSException exceptionWithName: NSRangeException
                                      reason: reason
                                    userInfo: info];
  [exception raise];
}

@end /* EOExpressionArray */


@implementation NSObject (EOExpression)

- (NSString*)expressionValueForContext: (id<EOExpressionContext>)ctx
{
  if ([self respondsToSelector: @selector(stringValue)])
    return [(id)self stringValue];
  else
    return [self description];
}

@end


@implementation NSString (EOExpression)

/* Avoid returning the description in case of NSString because if the string
   contains whitespaces it will be quoted. Particular adaptors have to override
   -formatValue:forAttribute: and they have to quote with the specific
   database character the returned string. */
- (NSString*)expressionValueForContext: (id<EOExpressionContext>)ctx
{
  return self;
}

@end

@implementation NSString (EOAttributeTypeCheck)

- (BOOL)isNameOfARelationshipPath
{
  const char *s = [self cString];
  BOOL result = NO;

  if (isalnum(*s) || *s == '@' || *s == '_' || *s == '#')
    {
      for (++s; *s; s++)
        {
          if (!isalnum(*s) && *s != '@' && *s != '_' && *s != '#' && *s != '$'
	      && *s != '.')
            return NO;
          
          if (*s == '.')
            result = YES;
        }
    }

  return result;
}

@end
