/** 
   EOQualifier.m <title>EOQualifier</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

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

#include <stdio.h>
#include <string.h>

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSDictionary.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSScanner.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <EOControl/EOQualifier.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>
#include <EOControl/EOClassDescription.h>

#include <GNUstepBase/GSObjCRuntime.h>

NSString *EOQualifierVariableSubstitutionException=@"EOQualifierVariableSubstitutionException";


@implementation NSNumber (EOQualifierExtras)

- (id)initWithString: (NSString *)string
{
    double   dVal;
    float    fVal;
    int      iVal;

    dVal = [string doubleValue];
    fVal = [string floatValue];
    iVal = [string intValue];

    if (dVal == iVal)
      {
	return [self initWithInt: iVal];
      }
    else if (dVal == fVal)
      {
	return [self initWithFloat: fVal];
      }
    else
      {
	return [self initWithDouble: dVal];
      }
}
@end

@interface EOQualifier (Privat)
- (void) _addBindingsToDictionary: (NSMutableDictionary*)dictionary;
- (id) _qualifierMigratedToSubEntity: (id)param0
                    fromParentEntity: (id)param1;
@end

@implementation EOQualifier

/**
 * Returns an autoreleased qualifier which is constructed by calling
 * [EOQualifier+qualifierWithQualifierFormat:varargList:]
 */
+ (EOQualifier *)qualifierWithQualifierFormat: (NSString *)qualifierFormat, ...
{
  EOQualifier *qualifier = nil;

  if(qualifierFormat)
    {
      va_list ap;

      va_start(ap, qualifierFormat);

      qualifier = [EOQualifier qualifierWithQualifierFormat: qualifierFormat
                               varargList: ap];

      va_end(ap);
    }

  return qualifier;
}

+ (EOQualifier *)qualifierWithQualifierFormat: (NSString *)format
				    arguments: (NSArray *)args
{
  [self notImplemented: _cmd];
  return nil;
}

- (void)dealloc
{
#ifdef DEBUG
//  NSDebugFLog(@"Dealloc EOQualifier %p. ThreadID=%p",
//              (void*)self,(void*)objc_thread_id());
#endif

  [super dealloc];

#ifdef DEBUG
//  NSDebugFLog(@"Stop Dealloc EOQualifier %p. ThreadID=%p",
//              (void*)self,(void*)objc_thread_id());
#endif
}

static NSString *getOperator(const char **cFormat, const char **s)
{
  NSString *operator;

  while (**s && isspace(**s))
    (*s)++;

  *cFormat = *s;

  if (isalnum(**s))
    {
      while (**s && !isspace(**s) && **s != '%' && **s != '\'')
        {
	  (*s)++;
        }

      operator = [NSString stringWithCString: *cFormat length: *s - *cFormat];
    }
  else
    {
      while (**s && !isalnum(**s) && !isspace(**s) && **s != '%' && **s != '\'')
        {
	  NSDebugLog(@"avoid gcc 3.1.1 bug which optimizes to segfault", "");
	  (*s)++;
        }

      operator = [NSString stringWithCString: *cFormat length: *s - *cFormat];
    }

  *cFormat = *s;

  return operator;
}
        
static id getKey(const char **cFormat, const char **s, BOOL *isKeyValue,
		 va_list *args)
{
  NSMutableString *key, *classString = nil;
  char quoteChar;
  BOOL quoted = NO;

  while (**s && isspace(**s))
    (*s)++;

  if (isKeyValue)
    {
      if (**s == '(')
        {
	  (*s)++; *cFormat = *s;

	  while (**s && **s != ')')
	    (*s)++;

	  if (!*s); //TODO exception

	  classString = [NSString stringWithCString: *cFormat
				  length: *s - *cFormat];

	  (*s)++; *cFormat = *s;
        }
  
      if (!strncmp("nil", *s, 3))
	{
	  char value = *(*s+3);

	  if (value == 0 || value == ' ')
	    {
	      *cFormat = *s = *s+3;
	      return nil;
	    }
	}
    }

  quoteChar = **s;
  if (quoteChar && (quoteChar == '"' || quoteChar == '\''))
    {
      quoted = YES;
      (*s)++;
    }
  
  *cFormat = *s;
  
  if (quoted)
    {
      while (**s && **s != quoteChar)
	(*s)++;

      key = [NSString stringWithCString: *cFormat length: *s - *cFormat];
      (*s)++; // skip closing quote
    }
  else
    {
      key = [NSMutableString stringWithCapacity:8];

      while (**s && (isalnum(**s) || **s == '@' || **s == '#' || **s == '_'
		     || **s == '$' || **s == '%' || **s == '.'))
        {
	  if (**s == '%')
	    {
	      const char *argString;
	      NSString *argObj;
	      //float argFloat;
	      double argFloat; // `float' is promoted to `double' when passed through `...' (so you should pass `double' not `float' to `va_arg')

	      int argInt;

	      if (isKeyValue)
	        {
		  *isKeyValue = YES;
		}

	      switch (*(*s+1))
		{
		case '@':
		  argObj = va_arg(*args, id);

		  if (isKeyValue && *isKeyValue == YES && quoted == NO
		      && classString == nil)
		    {
		      *cFormat = *s = *s+2;
		      return argObj;
		    }
		  else
		    {
		      if (*cFormat != *s)
			[key appendString: [NSString stringWithCString: *cFormat
						     length: *s - *cFormat]];

		      [key appendString: [argObj description]];
		      *cFormat = *s+2;
		      (*s)++;
		    }
		  break;

		case 's':
		  argString = va_arg(*args, const char *);

		  if (isKeyValue && *isKeyValue == YES && quoted == NO
		      && classString == nil)
		    {
		      *cFormat = *s = *s + 2;
		      return [NSString stringWithCString: argString];
		    }
		  else
		    {
		      if (*cFormat != *s)
			[key appendString: [NSString stringWithCString: *cFormat
						     length: *s - *cFormat]];

		      [key appendString: [NSString
					   stringWithCString: argString]];
		      *cFormat = *s + 2;
		      (*s)++;
		    }
		  break;

		case 'd':
		  argInt = va_arg(*args, int);

		  if (isKeyValue && *isKeyValue == YES && quoted == NO
		      && classString == nil)
		    {
		      *cFormat = *s = *s + 2;
		      return [NSNumber numberWithInt: argInt];
		    }
		  else
		    {
		      if(*cFormat != *s)
			[key appendString: [NSString stringWithCString: *cFormat
						     length: *s - *cFormat]];

		      [key appendString: [NSString stringWithFormat: @"%d",
						   argInt]];
		      *cFormat = *s + 2;
		      (*s)++;
		    }
		  break;

		case 'f':
		  argFloat = va_arg(*args, double);// `float' is promoted to `double' when passed through `...' (so you should pass `double' not `float' to `va_arg')

		  if (isKeyValue && *isKeyValue == YES && quoted == NO
		      && classString == nil)
		    {
		      *cFormat = *s = *s + 2;
		      return [NSNumber numberWithFloat: argFloat];
		    }
		  else
		    {
		      if (*cFormat != *s)
			[key appendString: [NSString stringWithCString: *cFormat
						     length: *s - *cFormat]];

		      [key appendString: [NSString stringWithFormat: @"%f",
						   argFloat]];
		      *cFormat = *s + 2;
		      (*s)++;
		    }
		  break;

		case '%':
		  *cFormat = *s + 2;
		  (*s)++;
		  [key appendString: [NSString stringWithCString: *cFormat
					       length: *s - *cFormat]];
		  break;

		default:
		  [NSException raise: NSInvalidArgumentException
			       format: @"%@ -- %@: unrecognized character (%c) in the conversion specification", @"qualifierParser", @"EOQualifier", *(*s + 1)];
		  break;
		}
	    }

	  (*s)++;
        }

      if (*cFormat != *s)
	[key appendString: [NSString stringWithCString: *cFormat
				     length: *s - *cFormat]];
    }

  if (isKeyValue)
    {
      *isKeyValue = quoted;

      if (classString)
        {
          key = AUTORELEASE([[NSClassFromString(classString) alloc]
			      initWithString: key]);
        }
    }
    
  *cFormat = *s;

  return key;
}

static BOOL isNotQualifier(const char **cFormat, const char **s)
{
  while (**s && isspace(**s))
    (*s)++;

  *cFormat = *s;

  if (!strncasecmp(*s, "not", 3))
    {
      switch ((*s)[3])
        {
	case ' ':
	case '(':
	case 0:
	  *cFormat = *s = *s+3;
	  return YES;
        }
    }

  return NO;
}

static Class whichQualifier(const char **cFormat, const char **s)
{
  while (**s && isspace(**s))
    (*s)++;

  *cFormat = *s;

  if (!strncasecmp(*s, "and", 3))
    {
      switch ((*s)[3])
        {
	case ' ':
	case '(':
	case 0:
	  *cFormat = *s = *s+3;
	  return [EOAndQualifier class];
        }
    }
  else if (!strncasecmp(*s, "or", 2))
    {
      switch ((*s)[2])
        {
	case ' ':
	case '(':
	case 0:
	  *cFormat = *s = *s+2;
	  return [EOOrQualifier class];
        }
    }

  return Nil;
}

+ (EOQualifier *)qualifierWithQualifierFormat: (NSString *)format
				   varargList: (va_list)args
{
  const char *s;
  const char *cFormat;
  NSMutableArray *bracketStack = nil;
  NSMutableArray *qualifierArray = nil;
  NSMutableArray *parentQualifiers = nil;
  EOQualifier *qualifier = nil;
  NSString *leftKey;
  NSString *rightKey;
  NSString *operator;
  SEL operatorSelector = NULL;
  BOOL isKeyValue = NO;
  BOOL notQual;
  Class lastQualifierClass = Nil;
  Class qualifierClass = Nil;

  bracketStack = [NSMutableArray array];
  parentQualifiers = [NSMutableArray array];

  cFormat = s = [format cString];

  while (*s)
    {
      while (*s && isspace(*s))
        (s)++;

      while (*s == '(' )
      {
	NSMutableDictionary *state;

	state = [NSMutableDictionary dictionaryWithCapacity:4];
	if (lastQualifierClass != NULL)
	  {
	    [state setObject: lastQualifierClass forKey: @"lastQualifierClass"];
	    lastQualifierClass = NULL;
	  }
	if (qualifierArray != nil)
	  {
	    [state setObject: qualifierArray forKey: @"qualifierArray"];
	    qualifierArray = nil;
	  }
	if (qualifierClass != nil)
	  {
	    [state setObject: qualifierClass forKey: @"qualifierClass"];
	    qualifierClass = nil;
	  }
	[state setObject: parentQualifiers forKey: @"parentQualifiers"];
	parentQualifiers = [NSMutableArray new];

	[bracketStack addObject:state];

	(s)++; // skip '('
	while (*s && isspace(*s))
	  (s)++;
      }
      
      notQual = isNotQualifier(&cFormat, &s);
      leftKey = getKey(&cFormat, &s, NULL, &args);
      operator = getOperator(&cFormat, &s);
      rightKey = getKey(&cFormat, &s, &isKeyValue, &args);

      operatorSelector = [EOQualifier operatorSelectorForString: operator];
      if (!operatorSelector)
        [NSException raise: NSInvalidArgumentException
		     format: @"%@ -- %@ 0x%x: no operator or unknown operator: '%@'",
                     NSStringFromSelector(_cmd),
		     NSStringFromClass([self class]), self,
                     operator];

      EOFLOGObjectLevelArgs(@"EOQualifier",
			    @"leftKey=%@ operatorSelector=%s rightKey=%@ class=%@",
			    leftKey,
			    GSNameFromSelector(operatorSelector),
			    rightKey,
			    isKeyValue?@"EOKeyValueQualifier":@"EOKeyComparisonQualifier");

      if (isKeyValue)
	qualifier = [EOKeyValueQualifier qualifierWithKey: leftKey
                                         operatorSelector: operatorSelector
                                         value: rightKey];
      else
	qualifier = [EOKeyComparisonQualifier
		      qualifierWithLeftKey: leftKey
		      operatorSelector: operatorSelector
		      rightKey: rightKey];
      
      EOFLOGObjectLevelArgs(@"EOQualifier",
			    @"qualifier=%@",
			    qualifier);

      if (notQual)
	qualifier = [EONotQualifier qualifierWithQualifier: qualifier];

      EOFLOGObjectLevelArgs(@"EOQualifier",
			    @"qualifier=%@",
			    qualifier);

      while (*s && isspace(*s))
        (s)++;

      while (*s == ')' )
      {
        NSMutableDictionary *state;

        /* clean up inner qualifier */
        if (qualifierArray != nil)
	  {
	    [qualifierArray addObject:qualifier];
	    qualifier = AUTORELEASE([[qualifierClass alloc]
				      initWithQualifierArray: qualifierArray]);
	    qualifierArray = nil;
	  }

	while ([parentQualifiers count] != 0)
	  {
	    id       parent;
	    NSArray *quals;
	    
	    parent = [parentQualifiers lastObject];
	    quals = [[parent qualifiers] arrayByAddingObject: qualifier];
	    qualifier = AUTORELEASE([[[parent class] alloc]
					initWithQualifierArray: quals]);
	    [parentQualifiers removeLastObject];
	  }

	DESTROY(parentQualifiers);

	/* pop bracketStack */
	state = [bracketStack lastObject];
	qualifierArray = [state objectForKey:@"qualifierArray"];
	lastQualifierClass = [state objectForKey:@"lastQualifierClass"];
	qualifierClass = [state objectForKey:@"qualifierClass"];
	parentQualifiers = [state objectForKey:@"parentQualifiers"];

	[bracketStack removeLastObject];

	(s)++; // skip ')'
        while (*s && isspace(*s))
          (s)++;
      }

      qualifierClass = whichQualifier(&cFormat, &s);
      EOFLOGObjectLevelArgs(@"EOQualifier", @"qualifierClass=%@",
			    qualifierClass);

      if ([bracketStack count]==0)
        {
          if (qualifierClass == Nil)
            break;
        }
      if (lastQualifierClass == Nil)
        {
          qualifierArray = [NSMutableArray arrayWithObject: qualifier];
        }
      else if (lastQualifierClass == qualifierClass)
        {
	  [qualifierArray addObject: qualifier];
        }
      else /* lastQualifierClass set and != qualifierClass */
        {
	  [parentQualifiers addObject:
	     AUTORELEASE([[lastQualifierClass alloc]
			     initWithQualifierArray: qualifierArray])];

	  qualifierArray = [NSMutableArray arrayWithObject: qualifier];
        }

      lastQualifierClass = qualifierClass;
    }

  /* this is reached after the break */
  if (lastQualifierClass != Nil)
    {
      if (qualifier == nil)
        [NSException raise: NSInvalidArgumentException
		     format: @"%@ -- %@ 0x%x: missing qualifier",
                     NSStringFromSelector(_cmd),
		     NSStringFromClass([self class]), self];

      [qualifierArray addObject: qualifier];

      qualifier = AUTORELEASE([[lastQualifierClass alloc]
		     initWithQualifierArray: qualifierArray]);

      EOFLOGObjectLevelArgs(@"EOQualifier", 
			    @"qualifier=%@",
			    qualifier);
    }

  while ([parentQualifiers count] != 0)
    {
      id       parent;
      NSArray *quals;

      parent = [parentQualifiers lastObject];
      quals = [[parent qualifiers] arrayByAddingObject: qualifier];
      qualifier = AUTORELEASE([[[parent class] alloc]
				  initWithQualifierArray: quals]);
      [parentQualifiers removeLastObject];
    }

  return qualifier;
}

+ (EOQualifier *)qualifierToMatchAllValues: (NSDictionary *)values
{
  NSEnumerator *keyEnumerator;
  NSString *key;
  NSMutableArray *array;

  array = [NSMutableArray arrayWithCapacity: [values count]];

  keyEnumerator = [values keyEnumerator];
  while ((key = [keyEnumerator nextObject]))
    [array addObject: [EOKeyValueQualifier
			qualifierWithKey: key
			operatorSelector: EOQualifierOperatorEqual
			value: [values objectForKey: key]]];

  if ([array count] == 1)
    return [array objectAtIndex: 0];

  return [EOAndQualifier qualifierWithQualifierArray: array];
}

+ (EOQualifier *)qualifierToMatchAnyValue:(NSDictionary *)values
{
  NSEnumerator *keyEnumerator;
  NSString *key;
  NSMutableArray *array;

  array = [NSMutableArray arrayWithCapacity: [values count]];

  keyEnumerator = [values keyEnumerator];
  while ((key = [keyEnumerator nextObject]))
    [array addObject:[EOKeyValueQualifier
		       qualifierWithKey: key
		       operatorSelector: EOQualifierOperatorEqual
		       value: [values objectForKey: key]]];

  if ([array count] == 1)
    return [array objectAtIndex: 0];

  return [EOOrQualifier qualifierWithQualifierArray: array];
}

- (NSException *)_validateKey:(NSString*)key
     withRootClassDescription: (EOClassDescription *)classDescription
{
  if (!key)
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: nil key",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];
  else
    {
      NSArray* keyParts = [key componentsSeparatedByString:@"."];
      int keyPartsCount=[keyParts count];
      int i = 0;
      BOOL stop=NO;
      for(i=0;i<keyPartsCount && !stop; i++)
        {
          NSString* keyPart = [keyParts objectAtIndex:i];
          NSArray* attributeKeys = [classDescription attributeKeys];
          if ([attributeKeys containsObject:keyPart])
            {
              stop=(i!=(keyPartsCount-1));
            } 
          else
            {
              classDescription = [classDescription classDescriptionForDestinationKey:keyPart];
              stop=(classDescription==nil);
            };
        };

      if (stop)
        {
          [NSException raise: NSInternalInconsistencyException
                       format: @"%@ -- %@ 0x%x: invalid key '%@'",
                       NSStringFromSelector(_cmd),
                       NSStringFromClass([self class]),
                       key];
        } ;
    };
  //TODO
  return nil;
};
      
- (NSException *)validateKeysWithRootClassDescription: (EOClassDescription *)classDescription
{
  return [self subclassResponsibility: _cmd];
}

+ (NSArray *)allQualifierOperators
{ // rivedere
  return [NSArray arrayWithObjects: @"=", @"!=", @"<=", @"<", @">=", @">",
		  @"doesContain", @"like", @"caseInsensitiveLike", nil];
}

+ (NSArray *)relationalQualifierOperators
{ // rivedere
  return [NSArray arrayWithObjects:@"=", @"!=", @"<=", @"<", @">=", @">", nil];
}

+ (NSString *)stringForOperatorSelector: (SEL)selector
{
  if (sel_eq(selector, EOQualifierOperatorEqual))
    return @"=";
  else if (sel_eq(selector, EOQualifierOperatorNotEqual))
    return @"!=";
  else if (sel_eq(selector, EOQualifierOperatorLessThan))
    return @"<";
  else if (sel_eq(selector, EOQualifierOperatorGreaterThan))
    return @">";
  else if (sel_eq(selector, EOQualifierOperatorLessThanOrEqualTo))
    return @"<=";
  else if (sel_eq(selector, EOQualifierOperatorGreaterThanOrEqualTo))
    return @">=";
  else if (sel_eq(selector, EOQualifierOperatorContains))
    return @"doesContain";
  else if (sel_eq(selector, EOQualifierOperatorLike))
    return @"like";
  else if (sel_eq(selector, EOQualifierOperatorCaseInsensitiveLike))
    return @"caseInsensitiveLike";

  return nil;
}

+ (SEL)operatorSelectorForString: (NSString *)string
{
  if ([string isEqualToString: @"="])
    return EOQualifierOperatorEqual;
  else if ([string isEqualToString: @"=="])
    return EOQualifierOperatorEqual;
  else if ([string isEqualToString: @"<="])
    return EOQualifierOperatorLessThanOrEqualTo;
  else if ([string isEqualToString: @"<"])
    return EOQualifierOperatorLessThan;
  else if ([string isEqualToString: @">="])
    return EOQualifierOperatorGreaterThanOrEqualTo;
  else if ([string isEqualToString: @">"])
    return EOQualifierOperatorGreaterThan;
  else if ([string isEqualToString: @"<>"])
    return EOQualifierOperatorNotEqual;
  else if ([string isEqualToString: @"!="])
    return EOQualifierOperatorNotEqual;
  else if ([string isEqualToString: @"doesContain"])
    return EOQualifierOperatorContains;
  else if ([string isEqualToString: @"like"])
    return EOQualifierOperatorLike;
  else if ([string isEqualToString: @"caseInsensitiveLike"])
    return EOQualifierOperatorCaseInsensitiveLike;
  else 
    {
      NSWarnMLog(@"No operator selector for string '%@'.", string);
      return (SEL)nil; // ????
    }
}

/**
 * NSCopying protocol
 * EOQualifiers are immutable.  Returns the receiver after retaining it.<br\>
 * If you wish to gain memory locality, you should recrate the qualifier
 * from scratch insuring that all referenced objects are also local to the new
 * zone.
 */
- (id)copyWithZone: (NSZone *)zone
{
  return RETAIN(self);
}

- (EOQualifier *)qualifierByApplyingBindings: (id)bindings
{
  return [self qualifierWithBindings: bindings
	       requiresAllVariables: NO];
}

- (EOQualifier *)qualifierByApplyingBindingsAllVariablesRequired: (id)bindings
{
  return [self qualifierWithBindings: bindings
	       requiresAllVariables: YES];
}

- (EOQualifier *)qualifierWithBindings: (NSDictionary *)bindings
		  requiresAllVariables: (BOOL)requiresAll
{
  return [self subclassResponsibility: _cmd];
}

/** Returns binding keys **/
- (NSArray *)bindingKeys
{
  NSMutableDictionary* bindings = (NSMutableDictionary*)[NSMutableDictionary dictionary];
  [self _addBindingsToDictionary:bindings];
  return [bindings allKeys];
}

//NO
- (BOOL)evaluateWithObject: (id)object
{
  [self notImplemented: _cmd];
  return NO;
}

- (NSString *)keyPathForBindingKey: (NSString *)key
{
  NSMutableDictionary* bindings = (NSMutableDictionary*)[NSMutableDictionary dictionary];
  [self _addBindingsToDictionary:bindings];
  return [bindings objectForKey:key];
}

- (EOQualifier *)qualifierMigratedFromEntity: (EOEntity *)entity 
                            relationshipPath: (NSString *)relationshipPath
{
  return [self notImplemented: _cmd]; //TODO
}

- (BOOL) usesDistinct
{
  [self notImplemented: _cmd]; //TODO
  return NO;
}

@end

@implementation EOQualifier (Privat)

- (id) _qualifierMigratedToSubEntity: (id)param0
                    fromParentEntity: (id)param1
{
  return [self notImplemented: _cmd]; //TODO
}

- (void) _addBindingsToDictionary: (NSMutableDictionary*)dictionary
{
  [self notImplemented: _cmd]; //TODO
}

@end


@implementation EOQualifierVariable

+ (EOQualifierVariable *)variableWithKey: (NSString *)key
{
  return AUTORELEASE([[self alloc] initWithKey: key]);
}

- (EOQualifierVariable *)initWithKey: (NSString *)key
{
  if ((self = [super init]))
    {
      ASSIGN(_key, key);
    }

  return self;
}

- (NSString *)key
{
  return _key;
}

- (void)encodeWithCoder: (NSCoder *)coder
{
  [coder encodeObject: _key];
}

- (id)initWithCoder: (NSCoder *)coder
{
  if ((self = [super init]))
    {
      _key = RETAIN([coder decodeObject]);
    }

  return self;
}

- (id)valueByApplyingBindings: (id)bindings
{
  return [self notImplemented: _cmd]; //TODO
}

- (id)requiredValueByApplyingBindings: (id)bindings
{
  return [self notImplemented: _cmd]; //TODO
}

- (id) initWithKeyValueUnarchiver: (EOKeyValueUnarchiver *)unarchiver
{
  return [self notImplemented: _cmd]; //TODO
}

- (void)encodeWithKeyValueArchiver: (EOKeyValueArchiver *)archiver
{
  [self notImplemented: _cmd]; //TODO
}

@end

/*
  This declaration is needed by the compiler to state that
  eventhough we know not all objects respond to -compare:,
  we want the compiler to generate code for the given
  prototype when calling -compare: in the following methods.
  We do not put this declaration in a header file to avoid
  the compiler seeing conflicting prototypes in user code.
*/
@interface NSObject (Comparison)
- (NSComparisonResult)compare: (id)other;
@end


@implementation NSObject (EORelationalSelectors)

- (BOOL)isEqualTo: (id)object
{
  return [self isEqual: object];
}

- (BOOL)isLessThanOrEqualTo: (id)object
{
  NSComparisonResult res = [self compare: object];

  return (res == NSOrderedAscending || res == NSOrderedSame ? YES : NO);
}

- (BOOL)isLessThan: (id)object
{
  return ([self compare:object] == NSOrderedAscending ? YES : NO);
}

- (BOOL)isGreaterThanOrEqualTo: (id)object
{
  NSComparisonResult res = [self compare:object];

  return (res == NSOrderedDescending || res == NSOrderedSame ? YES : NO);
}

- (BOOL)isGreaterThan: (id)object
{
  return ([self compare: object] == NSOrderedDescending ? YES : NO);
}

- (BOOL)isNotEqualTo: (id)object
{
  return ([self isEqualTo: object] ? NO : YES);
}

- (BOOL)doesContain: (id)object
{
  if ([self isKindOfClass: [NSArray class]])
    return [(NSArray *)self containsObject: object];

  return NO;
}

- (BOOL)isLike: (NSString *)object
{
  return NO;
}

- (BOOL)isCaseInsensitiveLike: (NSString *)object
{
  return NO;
}

@end


@implementation NSString (EORelationalSelectors)

static NSCharacterSet *isLikeWildCardSet = nil;
static NSString *isLikeWildCardTokenQ = @"?";
static NSString *isLikeWildCardTokenS = @"*";

static inline BOOL
_isLike (NSString *self, NSString *regExpr, BOOL isCaseSensative)
{
  NSScanner *regExScanner;
  NSScanner *valueScanner;
  NSString *scanned;
  unsigned c = 0;
  unsigned i = 0;
  GDL2_BUFFER (tokens, [regExpr cStringLength], id);

  if ([self isEqual: regExpr])
    {
      return YES;
    }

  if (isLikeWildCardSet == nil)
    isLikeWildCardSet 
      = [[NSCharacterSet characterSetWithCharactersInString: @"?*"] retain];

  regExScanner = [NSScanner scannerWithString: regExpr];
  valueScanner = [NSScanner scannerWithString: self];
  [valueScanner setCaseSensitive: isCaseSensative];

  while ([regExScanner isAtEnd] == NO)
    {
      if ([regExScanner scanUpToCharactersFromSet: isLikeWildCardSet
			intoString: &scanned])
	{
	  tokens[c++] = scanned;
	}
      if ([regExScanner isAtEnd] == NO)
	{
	  if ([regExScanner scanCharactersFromSet: isLikeWildCardSet
			    intoString: &scanned])
	    {
	      const char *cScanned;

	      for (cScanned = [scanned cString]; *cScanned != 0; cScanned++)
		{
		  if (*cScanned == '?' 
		      && tokens[c - 1] != isLikeWildCardTokenS)
		    {
		      tokens[c++] = isLikeWildCardTokenQ; 
		    }
		  else if (*cScanned == '*'
		      && tokens[c - 1] != isLikeWildCardTokenS)
		    {
		      tokens[c++] = isLikeWildCardTokenS;
		    }
		}
	    }
	}
    }

  for (i = 0; i < c; i++)
    {
      if (tokens[i] == isLikeWildCardTokenQ)
	{
	  if ([valueScanner isAtEnd])
	    {
	      return NO;
	    }
	  [valueScanner setScanLocation: [valueScanner scanLocation] + 1];
	}
      else if (tokens[i] == isLikeWildCardTokenS)
	{
	  if (i == c - 1)
	    {
	      return YES;
	    }
	  [valueScanner scanUpToString: tokens[i + 1]
			intoString: 0];
	}
      else
	{
	  if ([valueScanner isAtEnd])
	    {
	      return NO;
	    }
	  if ([valueScanner scanString: tokens[i] intoString: 0] == NO)
	    {
	      return NO;
	    }
	}
    }
  
  return [valueScanner isAtEnd];
}

- (BOOL)isLike: (NSString *)object
{
  return _isLike(self, object, YES);
}

- (BOOL)isCaseInsensitiveLike: (NSString *)object
{
  return _isLike(self, object, NO);
}

@end

@implementation NSArray (EOQualifierExtras)

- (NSArray *)filteredArrayUsingQualifier: (EOQualifier *)qualifier
{
  unsigned    max = [self count];

  if (max != 0)
    {
      unsigned  i;
      id        object;
      SEL       oaiSEL = @selector(objectAtIndex:);
      IMP       oaiIMP = [self methodForSelector:oaiSEL];
      SEL       ewoSEL = @selector(evaluateWithObject:);
      BOOL      (*ewoIMP)(id, SEL, id);
      GDL2_BUFFER(objP, max, id);

      ewoIMP = (BOOL (*)(id, SEL, id))[qualifier methodForSelector:ewoSEL];

      for(i=0; i < max; i++)
	{
	  object = (*oaiIMP)(self, oaiSEL, i);

	  if((*ewoIMP)(qualifier, ewoSEL, object))
	    {
	      *objP++=object;
	    }
	}
      return [NSArray arrayWithObjects: objP_base count: objP - objP_base];
    }
  else
    {
      return self;
    }
}


@end
