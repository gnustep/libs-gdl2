/** 
   Postgres95Values.m

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSData.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSDecimalNumber.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif


#include <EOAccess/EOAttribute.h>

#include "Postgres95EOAdaptor/Postgres95Adaptor.h"
#include "Postgres95EOAdaptor/Postgres95Channel.h"
#include "Postgres95EOAdaptor/Postgres95Values.h"

#include "Postgres95Compatibility.h"
#include "Postgres95Private.h"

#include <stdlib.h>

void __postgres95_values_linking_function (void)
{
}

static BOOL attrRespondsToValueClass = NO;
static BOOL attrRespondsToValueTypeChar = NO;
static NSStringEncoding LPSQLA_StringDefaultCStringEncoding;

@interface EOAttribute (private)
- (Class)_valueClass;
- (char)_valueTypeChar;
@end

@implementation Postgres95Values

+ (void) initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      PSQLA_PrivInit();

      attrRespondsToValueClass
	= [EOAttribute instancesRespondToSelector: @selector(_valueClass)];
      attrRespondsToValueTypeChar
	= [EOAttribute instancesRespondToSelector: @selector(_valueTypeChar)];
      LPSQLA_StringDefaultCStringEncoding = [NSString defaultCStringEncoding];
    }
};

+ (id)newValueForBytes: (const void *)bytes
                length: (int)length
             attribute: (EOAttribute *)attribute
{
  switch ([attribute adaptorValueType])
    {
    case EOAdaptorNumberType:
      return [self newValueForNumberType: bytes
		   length: length
		   attribute: attribute];
    case EOAdaptorCharactersType:
      return [self newValueForCharactersType: bytes
		   length: length
		   attribute: attribute];
    case EOAdaptorBytesType:
      return [self newValueForBytesType: bytes
		   length: length
		   attribute: attribute];
    case EOAdaptorDateType:
      return [self newValueForDateType: bytes
		   length: length
		   attribute: attribute];
    default:
      NSAssert2(NO,
                @"Bad (%d) adaptor type for attribute : %@",
                (int)[attribute adaptorValueType],attribute);
      return nil;
    }
}

/**
For efficiency reasons, the returned value is NOT autoreleased !
bytes is null terminated (cf Postgresql doc) and length is equivalent 
to strlen(bytes)
**/
+ (id)newValueForNumberType: (const void *)bytes
                     length: (int)length
                  attribute: (EOAttribute *)attribute
{  
  id value = nil;
  NSString* externalType=nil;
  
  externalType=[attribute externalType];

  if (length==1 // avoid -isEqualToString if we can :-)
      && [externalType isEqualToString: @"bool"])
    {
      if (((char *)bytes)[0] == 't' && ((char *)bytes)[1] == 0)
	value=RETAIN(PSQLA_NSNumberBool_Yes);
      else if (((char *)bytes)[0] == 'f' && ((char *)bytes)[1] == 0)
	value=RETAIN(PSQLA_NSNumberBool_No);
      else
        NSAssert1(NO,@"Bad boolean: %@",[NSString stringWithCString:bytes
                                                  length:length]);
    }
  else
    {
      Class valueClass = attrRespondsToValueClass 
	? [attribute _valueClass] 
	: NSClassFromString ([attribute valueClassName]);

      if (valueClass==PSQLA_NSDecimalNumberClass)
        {
	  //TODO: Optimize without creating NSString instance
          NSString* str = [PSQLA_alloc(NSString) initWithCString:bytes
				                 length:length];
          
          value = [PSQLA_alloc(NSDecimalNumber) initWithString: str];

          RELEASE(str);
        }
      else
        {
          char valueTypeChar = attrRespondsToValueTypeChar
	    ? [attribute _valueTypeChar]
	    : [[attribute valueType] cString][0];
          switch(valueTypeChar)
            {
            case 'i':
              value = [PSQLA_alloc(NSNumber) initWithInt: atoi(bytes)];
              break;
            case 'I':
              value = [PSQLA_alloc(NSNumber) initWithUnsignedInt:(unsigned int)atol(bytes)];
              break;
            case 'c':
              value = [PSQLA_alloc(NSNumber) initWithChar: atoi(bytes)];
              break;
            case 'C':
              value = [PSQLA_alloc(NSNumber) initWithUnsignedChar: (unsigned char)atoi(bytes)];
              break;
            case 's':
              value = [PSQLA_alloc(NSNumber) initWithShort: (short)atoi(bytes)];
              break;
            case 'S':
              value = [PSQLA_alloc(NSNumber) initWithUnsignedShort: (unsigned short)atoi(bytes)];
              break;
            case 'l':
              value = [PSQLA_alloc(NSNumber) initWithLong: atol(bytes)];
              break;
            case 'L':
              value = [PSQLA_alloc(NSNumber) initWithUnsignedLong:strtoul(bytes,NULL,10)];
              break;
            case 'u':
              value = [PSQLA_alloc(NSNumber) initWithLongLong:atoll(bytes)];
              break;
            case 'U':
              value = [PSQLA_alloc(NSNumber) initWithUnsignedLongLong:strtoull(bytes,NULL,10)];
              break;
            case 'f':
              value = [PSQLA_alloc(NSNumber) initWithFloat: strtof(bytes,NULL)];
              break;
            case 'd':
            case '\0':
              value = [PSQLA_alloc(NSNumber) initWithDouble: strtod(bytes,NULL)];
              break;
            default:
              NSAssert2(NO,@"Unknown attribute valueTypeChar: %c for attribute: %@",
                        valueTypeChar,attribute);
            };
        };
    };

  return value;
}

/**
For efficiency reasons, the returned value is NOT autoreleased !
**/
+ (id)newValueForCharactersType: (const void *)bytes
                         length: (int)length
                      attribute: (EOAttribute *)attribute
{
  return [attribute newValueForBytes: bytes
		    length: length
		    encoding: LPSQLA_StringDefaultCStringEncoding];
}

/**
For efficiency reasons, the returned value is NOT autoreleased !
**/
+ (id)newValueForBytesType: (const void *)bytes
                    length: (int)length
                 attribute: (EOAttribute *)attribute
{
  size_t newLength = length;
  unsigned char *decodedBytes = 0;
  id data = nil;

  if ([[attribute externalType] isEqualToString: @"bytea"])
    {
      decodedBytes = PQunescapeBytea((unsigned char *)bytes, &newLength);
      bytes = decodedBytes;
    }

  data = [attribute newValueForBytes: bytes
		    length: newLength];
  if (decodedBytes)
    {
      PQfreemem (decodedBytes);
    }
  return data;
}


/**
For efficiency reasons, the returned value is NOT autoreleased !
**/
+ (id)newValueForDateType: (const void *)bytes
                   length: (int)length
                attribute: (EOAttribute *)attribute
{
  id date=nil;
  NSString *str = [PSQLA_alloc(NSString) initWithCString:(const char *)bytes
                                         length:length];

  NSDebugMLLog(@"gsdb",@"str=%@ format=%@",str,PSQLA_postgresCalendarFormat);  

  date = [PSQLA_alloc(NSCalendarDate) initWithString: str
	       calendarFormat: PSQLA_postgresCalendarFormat];

  NSDebugMLLog(@"gsdb",@"str=%@ d=%@ dtz=%@ format=%@",
	       str,date,[date timeZone],PSQLA_postgresCalendarFormat);  

  //We may have some 'invalid' date so it's better to stop here
  NSAssert2(date,
            @"No date created for string '%@' for attribute: %@",
            str,attribute);

  RELEASE(str);

  return date;
}


@end
/*
@implementation NSString (Postgres95ValueCreation)


For efficiency reasons, the returned value is NOT autoreleased !

- stringValueForPostgres95Type:(NSString*)type
  attribute:(EOAttribute*)attribute
{
if ([type isEqual:@"bytea"])
    return [[NSData alloc]initWithBytes:[self cString]
      length:[self cStringLength]]
      stringValueForPostgres95Type:type
               attribute:attribute];
    else
      return [[[[EOQuotedExpression alloc]
                 initWithExpression:self
                 quote:@"'"
                 escape:@"\\'"]
                autorelease]
               expressionValueForContext:nil];
    return nil;
}

@end // NSString (Postgres95ValueCreation)



@implementation NSNumber (Postgres95ValueCreation)

- stringValueForPostgres95Type:(NSString*)type
  attribute:(EOAttribute*)attribute;
{
    if ([[attribute externalType] isEqualToString:@"bool"])
	return [self boolValue] ? @"'t'" : @"'f'";

    return [self description];
}

@end // NSNumber (Postgres95ValueCreation)


@implementation NSData (Postgres95ValueCreation)


- stringValueForPostgres95Type:(NSString*)type
  attribute:(EOAttribute*)attribute
{
    if ([[attribute externalType] isEqualToString:@"bytea"]) {
	const char* bytes = [self bytes];
	int length = [self length];
	int final_length;
	char *description, *temp;
	int i;
    
	if (!length)
	    return @"''";

	final_length = 4 + 2 * length + 1;
	description = Malloc (final_length);
	temp = description + 3;
    
	description[0] = 0;
	strcat (description, "'0x");
	for (i = 0; i < length; i++, temp += 2)
	    sprintf (temp, "%02X", (unsigned char)bytes[i]);
	temp[0] = '\'';
	temp[1] = 0;
	
	return [[[NSString alloc] 
		initWithCStringNoCopy:description
		length:final_length-1
		freeWhenDone:YES]
	    autorelease];
    }
    
    return [[NSString stringWithCString:[self bytes] length:[self length]]
	    stringValueForPostgres95Type:type attribute:attribute];
}

@end // NSData (Postgres95ValueCreation)

*/

@implementation NSCalendarDate (Postgres95ValueCreation)

+ (NSString*)postgres95Format
{
  NSLog(@"%@ - is deprecated.  The adaptor always uses ISO format.",
        NSStringFromSelector(_cmd));
  return PSQLA_postgresCalendarFormat;
}

@end // NSCalendarDate (Postgres95ValueCreation)


/*
@implementation EONull (Postgres95ValueCreation)

- stringValueForPostgres95Type:(NSString*)type
  attribute:(EOAttribute*)attribute
{
    return @"NULL";
}

@end


@implementation NSObject (Postgres95ValueCreation)

- stringValueForPostgres95Type:(NSString*)type
  attribute:(EOAttribute*)attribute
{
    if ([self respondsToSelector:@selector(stringForType:)])
	return [[self stringForType:[attribute valueType]]
		    stringValueForPostgres95Type:type attribute:attribute];
    else if ([self respondsToSelector:@selector(dataForType:)])
	return [[self dataForType:[attribute valueType]]
		    stringValueForPostgres95Type:type attribute:attribute];
    else
	THROW([[DataTypeMappingNotSupportedException alloc]
		initWithFormat:@"Postgres95 cannot map value class %@ "
		@"because its instances does not responds to either "
		@" `stringForType:' or `dataForType:'. ",
		NSStringFromClass([self class])]);
    return nil;
}

@end // NSObject (Postgres95ValueCreation)
*/
