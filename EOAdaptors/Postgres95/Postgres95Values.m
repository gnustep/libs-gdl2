/** 
   Postgres95Values.m

   Copyright (C) 2000-2003 Free Software Foundation, Inc.

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
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
#include <EOAccess/EOAttributePriv.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EOPriv.h>

#include "Postgres95EOAdaptor/Postgres95Adaptor.h"
#include "Postgres95EOAdaptor/Postgres95Channel.h"
#include "Postgres95EOAdaptor/Postgres95Values.h"

#include "Postgres95Compatibility.h"

void __postgres95_values_linking_function (void)
{
}

Class Postgres95ValuesClass=Nil;

static SEL postgres95FormatSEL=NULL;
SEL Postgres95Values_newValueForBytesLengthAttributeSEL=NULL;

static IMP GDL2NSCalendarDate_postgres95FormatIMP=NULL;
IMP Postgres95Values_newValueForBytesLengthAttributeIMP=NULL;

@implementation Postgres95Values

+ (void) initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      GDL2PrivInit();

      ASSIGN(Postgres95ValuesClass,([Postgres95Values class]));

      postgres95FormatSEL=@selector(postgres95Format);
      Postgres95Values_newValueForBytesLengthAttributeSEL=@selector(newValueForBytes:length:attribute:);

      GDL2NSCalendarDate_postgres95FormatIMP=[GDL2NSCalendarDateClass 
                                          methodForSelector:postgres95FormatSEL];

      Postgres95Values_newValueForBytesLengthAttributeIMP=[Postgres95ValuesClass
                                                            methodForSelector:Postgres95Values_newValueForBytesLengthAttributeSEL];
    };
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
    case EOAdaptorUnknownType:
      NSAssert1(NO,
                @"Bad (EOAdaptorUnknownType) adaptor type for attribute : %@",
                attribute);
      return nil;
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
	value=RETAIN(GDL2NSNumberBool_Yes);
      else if (((char *)bytes)[0] == 'f' && ((char *)bytes)[1] == 0)
	value=RETAIN(GDL2NSNumberBool_No);
      else
        NSAssert1(NO,@"Bad boolean: %@",[NSString stringWithCString:bytes
                                                  length:length]);
    }
  else
    {
      Class valueClass=[attribute _valueClass];

      if (valueClass==GDL2NSDecimalNumberClass)
        {
          NSString* str = [GDL2NSString_alloc() initWithCString:bytes
                                             length:length];
          
          value = [GDL2NSDecimalNumber_alloc() initWithString: str];

          RELEASE(str);
        }
      else
        {
          char valueTypeChar=[attribute _valueTypeChar];
          switch(valueTypeChar)
            {
            case 'i':
              value = [GDL2NSNumber_alloc() initWithInt: atoi(bytes)];
              break;
            case 'I':
              value = [GDL2NSNumber_alloc() initWithUnsignedInt:(unsigned int)atol(bytes)];
              break;
            case 'c':
              value = [GDL2NSNumber_alloc() initWithChar: atoi(bytes)];
              break;
            case 'C':
              value = [GDL2NSNumber_alloc() initWithUnsignedChar: (unsigned char)atoi(bytes)];
              break;
            case 's':
              value = [GDL2NSNumber_alloc() initWithShort: (short)atoi(bytes)];
              break;
            case 'S':
              value = [GDL2NSNumber_alloc() initWithUnsignedShort: (unsigned short)atoi(bytes)];
              break;
            case 'l':
              value = [GDL2NSNumber_alloc() initWithLong: atol(bytes)];
              break;
            case 'L':
              value = [GDL2NSNumber_alloc() initWithUnsignedLong:strtoul(bytes,NULL,10)];
              break;
            case 'u':
              value = [GDL2NSNumber_alloc() initWithLongLong:atoll(bytes)];
              break;
            case 'U':
              value = [GDL2NSNumber_alloc() initWithUnsignedLongLong:strtoull(bytes,NULL,10)];
              break;
            case 'f':
              value = [GDL2NSNumber_alloc() initWithFloat: strtof(bytes,NULL)];
              break;
            case 'd':
            case '\0':
              value = [GDL2NSNumber_alloc() initWithDouble: strtod(bytes,NULL)];
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
		    encoding: GDL2StringDefaultCStringEncoding()];
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
  NSString *str = [GDL2NSString_alloc() initWithCString:(const char *)bytes
                                     length:length];
  NSString *format = (*GDL2NSCalendarDate_postgres95FormatIMP)
    (GDL2NSCalendarDateClass,postgres95FormatSEL);

  NSDebugMLLog(@"gsdb",@"str=%@ format=%@",str,format);  

  date = [GDL2NSCalendarDate_alloc() initWithString: str
                                  calendarFormat: format];

  NSDebugMLLog(@"gsdb",@"str=%@ d=%@ dtz=%@ format=%@",str,date,[date timeZone],format);  

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
/*
- stringValueForPostgres95Type:(NSString*)type
  attribute:(EOAttribute*)attribute
{
    NSString* externalType = [attribute externalType];
	if (!CALENDAR_FORMAT)
	  [NSCalendarDate setPostgres95Format:[NSString stringWithCString:"%b %d %Y %I:%M%p %Z"]];
  
    if ([externalType isEqualToString:@"abstime"]) {
	id tz = [attribute serverTimeZone];
	id date;

	if (tz) {
	    date = [[self copy] autorelease];
	    [date setTimeZone:tz];
	}
	else
	    date = self;

	return [NSString stringWithFormat:@"'%@'",
		    [date descriptionWithCalendarFormat:CALENDAR_FORMAT]];
    }

    THROW([[DataTypeMappingNotSupportedException alloc]
	    initWithFormat:@"Postgres95 cannot map NSCalendarDate in "
			    @"attribute %@ to external type %@",
			    [attribute name], externalType]);
    return nil;
}
*/

+ (NSString*)postgres95Format
{
  return @"%Y-%m-%d %H:%M:%S%z";
}

+ (void)setPostgres95Format: (NSString*)dateFormat
{
  NSLog(@"%@ - is deprecated.  The adaptor always uses ISO format.",
        NSStringFromSelector(_cmd));
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
