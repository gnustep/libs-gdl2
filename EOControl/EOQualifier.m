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

static char rcsId[] = "$Id$";

#include <stdio.h>
#include <string.h>

#import <Foundation/NSDictionary.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSUtilities.h>

#import <Foundation/NSException.h>

#import <EOControl/EOControl.h>
#import <EOControl/EOQualifier.h>
#import <EOControl/EODebug.h>

@implementation NSNumber (EOQualifierExtras)
- (id)initWithString:(NSString *)string
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

@implementation EOQualifier

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
	  NSDebugLog(@"avoid gcc 3.1.1 bug which optimizes to segfault");
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
          key = [[[NSClassFromString(classString) alloc] initWithString: key] autorelease];
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

      EOFLOGObjectLevelArgs(@"EOQualifier",
			    @"leftKey=%@ operatorSelector=%s rightKey=%@ class=%@",
			    leftKey,
			    GSObjCSelectorName(operatorSelector),
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
	    qualifier = AUTORELEASE([[qualifierClass alloc] initWithQualifierArray:qualifierArray]);
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

- (NSException *)validateKeysWithRootClassDescription: (EOClassDescription *)classDesc
{
  return [self notImplemented: _cmd]; //TODO
}

+ (NSArray *)allQualifierOperators
{ // rivedere
  return [NSArray arrayWithObjects:@"=", @"!=", @"<=", @"<", @">=", @">", @"contains", @"like", @"caseInsensitiveLike"];
}

+ (NSArray *)relationalQualifierOperators
{ // rivedere
  return [NSArray arrayWithObjects:@"=", @"!=", @"<=", @"<", @">=", @">"];
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
    return @"contains";
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
  else if ([string isEqualToString: @"contains"])
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

- (id)copyWithZone: (NSZone *)zone
{
  return NSCopyObject(self, 0, zone);
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
  // TODO
  [self notImplemented: _cmd];
  return nil;
}

- (NSArray *)bindingKeys
{
  // TODO
  [self notImplemented: _cmd];
  return nil;
}

//NO
- (BOOL)evaluateWithObject: (id)object
{
  [self notImplemented: _cmd];
  return NO;
}

- (NSString *)keyPathForBindingKey: (NSString *)key
{
  // TODO
  [self notImplemented: _cmd];
  return nil;
}

- (void) _addBindingsToDictionary: (id)param0
{
  [self notImplemented: _cmd]; //TODO
}

- (EOQualifier *)qualifierMigratedFromEntity: (EOEntity *)entity 
                            relationshipPath: (NSString *)relationshipPath
{
  return [self notImplemented: _cmd]; //TODO
}

- (id) _qualifierMigratedToSubEntity: (id)param0
                    fromParentEntity: (id)param1
{
  return [self notImplemented: _cmd]; //TODO
}

- (BOOL) usesDistinct
{
  [self notImplemented: _cmd]; //TODO
  return NO;
}

@end


@implementation EOQualifierVariable

+ (EOQualifierVariable *)variableWithKey: (NSString *)key
{
  return [EOQualifierVariable variableWithKey: key];
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
      _key = [[coder decodeObject] retain];
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
  return ([self isEqual: object] ? NO : YES);
}

- (BOOL)doesContain: (id)object
{
  if ([self isKindOfClass: [NSArray class]]
      || [self isKindOfClass: [NSMutableArray class]])
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

- (BOOL)isLike: (NSString *)object
{
  NSEmitTODO();  //TODO
  return [self isEqual: object] == NSOrderedSame;
}

- (BOOL)isCaseInsensitiveLike: (NSString *)object
{
  NSEmitTODO();  //TODO
  return [[self uppercaseString]
	   isEqual: [object uppercaseString]] == NSOrderedSame;
}

@end
