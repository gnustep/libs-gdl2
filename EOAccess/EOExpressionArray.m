/** 
   EOExpressionArray.m <title>EOExpressionArray</title>

   Copyright (C) 1996-2002 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>
   Date: September 1996

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

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

#include "config.h"

RCS_ID("$Id$")

#include <ctype.h>

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#include <GNUstepBase/GSObjCRuntime.h>
#endif

#include <EOControl/EODebug.h>

#include <EOAccess/EOEntity.h>
#include <EOAccess/EOExpressionArray.h>
#include <EOAccess/EORelationship.h>


@implementation EOExpressionArray

+ (void) initialize
{
  static BOOL initialized = NO;

  if (!initialized)
    {
      initialized = YES;
      GSObjCAddClassBehavior(self, [GCArray class]);
    }
}

+ (EOExpressionArray*)expressionArray
{
  return [[self new] autorelease];
}

- (id) init
{
  EOFLOGObjectFnStart();

  self = [super init];

  EOFLOGObjectFnStop();

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

- (void)dealloc
{
  DESTROY(_realAttribute); //TODO mettere nei metodi GC
//  DESTROY(_definition);
  [_prefix release];
  [_infix release];
  [_suffix release];

  [super dealloc];
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
