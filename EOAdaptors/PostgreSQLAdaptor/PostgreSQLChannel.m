/** 
   PostgreSQLChannel.m <title>PostgreSQLChannel</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   based on the PostgreSQL adaptor written by
         Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

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


#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSCalendarDate.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSString.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSTimeZone.h>
#include <Foundation/NSUtilities.h>
#else
#include <Foundation/Foundation.h>
#include <GNUstepBase/GSCategories.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EONull.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOSQLExpression.h>

#include "PostgreSQLAdaptor.h"
#include "PostgreSQLChannel.h"
#include "PostgreSQLContext.h"

#include "PostgreSQLPrivate.h"

@interface EOAttribute (private)
- (Class)_valueClass;
- (char)_valueTypeCharacter;
@end

static BOOL attrRespondsToValueClass = NO;
static BOOL attrRespondsToValueTypeChar = NO;

#define EOAdaptorDebugLog(format, args...) \
  do { if ([self isDebugEnabled]) { NSLog(format , ## args); } } while (0)

static NSDictionary *
pgResultDictionary(PGresult *pgResult)
{
  int nfields, ntuples;
  int i, j;
  NSMutableArray *fields;
  NSMutableArray *tuples;
  ExecStatusType statusType;

  nfields = PQnfields(pgResult);
  ntuples = PQntuples(pgResult);

  fields = [NSMutableArray arrayWithCapacity: nfields];
  tuples = [NSMutableArray arrayWithCapacity: ntuples];

  for (i = 1; i <= nfields; i++)
    {
      NSString *fname;
      NSNumber *fnumber;
      NSNumber *ftype;
      NSNumber *fsize;
      NSNumber *fmod;
      NSDictionary *dict;
      char *cfname;

      cfname = PQfname(pgResult, i);

      fname = [NSString stringWithCString: cfname];
      fnumber = [NSNumber numberWithInt: PQfnumber(pgResult, cfname)];
      ftype = [NSNumber numberWithUnsignedInt: PQftype(pgResult, i)];
      fsize = [NSNumber numberWithInt: PQfsize(pgResult, i)];
      fmod = [NSNumber numberWithInt: PQfmod(pgResult, i)];

      dict = [NSDictionary dictionaryWithObjectsAndKeys:
			     fname, @"PQfname",
			   fnumber, @"PQfnumber",
			   ftype, @"PQftype",
			   fsize, @"PQfsize",
			   fmod, @"PQfmod",
			   nil];

      [fields addObject: dict];
    }

  for (i = 1; i <= ntuples; i++)
    {
      NSMutableDictionary *tuple;
      tuple = [NSMutableDictionary dictionaryWithCapacity: nfields];
      for (j = 1; j <= nfields; j++)
	{
	  NSString *tupleInfo;
	  NSString *tupleKey;

	  tupleKey = [NSString stringWithCString: PQfname(pgResult, j)];

	  if (PQgetisnull(pgResult, i, j))
	    {
	      tupleInfo = @"NULL";
	    }
	  else
	    {
	      NSString *fmt;
	      fmt = [NSString stringWithFormat: @"%%%ds", PQgetlength(pgResult, i, j)];
	      tupleInfo = [NSString stringWithFormat: fmt, PQgetvalue(pgResult, i, j)];
	    }
	  [tuple setObject: tupleInfo forKey: tupleKey];
	}
      [tuples addObject: tuple];
    }

  statusType = PQresultStatus(pgResult);

  return [NSDictionary dictionaryWithObjectsAndKeys:
    [NSString stringWithFormat:@"%d",  statusType], @"PQresultStatus",
    [NSString stringWithFormat:@"%s",  PQresStatus(statusType)], @"PQresStatus",
    [NSString stringWithFormat:@"%s",  PQresultErrorMessage(pgResult)], @"PQresultErrorMessage",
    [NSString stringWithFormat:@"%d",  ntuples], @"PQntuples",
    [NSString stringWithFormat:@"%d",  nfields], @"PQnfields",
    [NSString stringWithFormat:@"%d",  PQbinaryTuples(pgResult)], @"PQbinaryTuples",
    [NSString stringWithFormat:@"%s",  PQcmdStatus(pgResult)], @"PQcmdStatus",
    [NSString stringWithFormat:@"%s",  PQoidStatus(pgResult)], @"PQoidStatus",
    [NSString stringWithFormat:@"%d",  PQoidValue(pgResult)], @"PQoidValue",
    [NSString stringWithFormat:@"%s",  PQcmdTuples(pgResult)], @"PQcmdTuples",
    tuples, @"tuples",
    fields, @"fields",
    nil];
}

/*
 * read up to the specified number of characters, terminating at a non-digit
 * except for leading whitespace characters.
 */
static inline int
getDigits(const char *from, char *to, int limit, BOOL *error)
{
  int	i = 0;
  int	j = 0;

  BOOL	foundDigit = NO;

  while (i < limit)
    {
      if (isdigit(from[i]))
	{
	  to[j++] = from[i];
	  foundDigit = YES;
	}
      else if (isspace(from[i]))
	{
	  if (foundDigit == YES)
	    {
	      break;
	    }
	}
      else
	{
	  break;
	}
      i++;
    }
  to[j] = '\0';
  if (j == 0)
    {
      *error = YES;	// No digits read
    }
  return i;
}

static id
newValueForNumberTypeLengthAttribute(const void *bytes,
				     int length,
				     EOAttribute *attribute,
				     NSStringEncoding encoding)
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
        NSCAssert1(NO, @"Bad boolean: %@",
		   AUTORELEASE([[NSString alloc] initWithBytes: bytes
						 length: length
						 encoding: encoding]));
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
          char valueTypeChar = '\0';
	  if (attrRespondsToValueTypeChar)
	    {
	      valueTypeChar = [attribute _valueTypeCharacter];
	    }
	  else
	    {
	      NSString *vt = [attribute valueType];
	      if (vt) valueTypeChar = [[attribute valueType] UTF8String][0];
	    }
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
              value = [PSQLA_alloc(NSNumber) initWithFloat: (float)strtod(bytes,NULL)];
              break;
            case 'd':
            case '\0':
              value = [PSQLA_alloc(NSNumber) initWithDouble: strtod(bytes,NULL)];
              break;
            default:
              NSCAssert2(NO,@"Unknown attribute valueTypeChar: %c for attribute: %@",
			 valueTypeChar,attribute);
            };
        };
    };

  return value;
}

static id
newValueForCharactersTypeLengthAttribute (const void *bytes,
					  int length,
					  EOAttribute *attribute,
					  NSStringEncoding encoding)
{
  return [attribute newValueForBytes: bytes
		    length: length
		    encoding: encoding];
}

static id
newValueForBytesTypeLengthAttribute (const void *bytes,
				     int length,
				     EOAttribute *attribute,
				     NSStringEncoding encoding)
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

static id
newValueForDateTypeLengthAttribute (const void *bytes,
				    int length,
				    EOAttribute *attribute,
				    NSStringEncoding encoding)
{
  int year = 0;
  unsigned month = 0;
  unsigned day = 0;
  unsigned hour = 0;
  unsigned minute = 0;
  unsigned second = 0;
  unsigned millisecond = 0;
  int tz = 0;
  NSTimeZone *timezone = nil;
  NSCalendarDate *date = nil;
  const char *str = bytes;
  BOOL error;
  char tmpString[8];

  /* We assume ISO date format:
     2006-12-31 00:45:21.2531419+01 
     012345678911234567892123456789
     where the milliseconds have variable length.  */
  if (length > 3)
    {
      getDigits(&str[0],tmpString,4,&error);
      year = atoi(tmpString);

  if (length > 6)
    {
      getDigits(&str[5],tmpString,2,&error);
      month = atoi(tmpString);

  if (length > 9)
    {
      getDigits(&str[8],tmpString,2,&error);
      day = atoi(tmpString);

  if (length > 12)
    {
      getDigits(&str[11],tmpString,2,&error);
      hour = atoi(tmpString);

  if (length > 15)
    {
      getDigits(&str[14],tmpString,2,&error);
      minute = atoi(tmpString);

  if (length > 18)
    {
      getDigits(&str[17],tmpString,2,&error);
      second = atoi(tmpString);

  if (length > 19)
    {
      tz = getDigits(&str[17],tmpString,7,&error);
      millisecond = atoi(tmpString);
    }
    }
    }
    }
    }
    }
    }
  if (tz)
    {
      int sign = (str[tz]) == '-' ? -1 : 1;
      getDigits(&str[tz+1],tmpString,2,&error);
      tz = atoi(tmpString);
      if (tz < 100) tz *= 100;
      tz = sign * ((tz / 100) * 60 + (tz % 100)) * 60;
      timezone = [NSTimeZone timeZoneForSecondsFromGMT: tz];
    }

  date = [attribute newDateForYear: year
		    month: month
		    day: day
		    hour: hour
		    minute: minute
		    second: second
		    millisecond: millisecond
		    timezone: timezone
		    zone: 0];

  return date;
}

static id
newValueForBytesLengthAttribute (const void *bytes, 
				 int length, 
				 EOAttribute *attribute,
				 NSStringEncoding encoding)
{
  switch ([attribute adaptorValueType])
    {
    case EOAdaptorNumberType:
      return newValueForNumberTypeLengthAttribute(bytes, length, attribute, encoding);
    case EOAdaptorCharactersType:
      return newValueForCharactersTypeLengthAttribute(bytes, length, attribute, encoding);
    case EOAdaptorBytesType:
      return newValueForBytesTypeLengthAttribute(bytes, length, attribute, encoding);
    case EOAdaptorDateType:
      return newValueForDateTypeLengthAttribute(bytes, length, attribute, encoding);
    default:
      NSCAssert2(NO,
                @"Bad (%d) adaptor type for attribute : %@",
                (int)[attribute adaptorValueType],attribute);
      return nil;
    }
}

@implementation PostgreSQLChannel

+ (void) initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      PSQLA_PrivInit();

      attrRespondsToValueClass
	= [EOAttribute instancesRespondToSelector: @selector(_valueClass)];
      attrRespondsToValueTypeChar
	= [EOAttribute instancesRespondToSelector: @selector(_valueTypeCharacter)];

      initialized = YES;
    };
};

/* Set DateStyle to use ISO format.  */
- (void)_setDateStyle
{
  _pgResult = PQexec(_pgConn, 
		     "SET DATESTYLE TO ISO");

  if (_pgResult == NULL || PQresultStatus(_pgResult) != PGRES_COMMAND_OK)
    {
      _pgResult = NULL;
      [NSException raise: PostgreSQLException
		   format: @"cannot set date style to ISO."];
    }
  
  PQclear(_pgResult);
  _pgResult = NULL;
}

- (id) initWithAdaptorContext: (EOAdaptorContext *)adaptorContext
{
  if ((self = [super initWithAdaptorContext: adaptorContext]))
    {
      EOAttribute *attr = nil;

      ASSIGN(_adaptorContext, adaptorContext);//TODO NO

//verify
      _oidToTypeName = [[NSMutableDictionary alloc] initWithCapacity: 101];

      attr = [[EOAttribute alloc] init];
      [attr setName: @"nextval"];
      [attr setColumnName: @"nextval"];
      [attr setValueType: @"i"];
      [attr setValueClassName: @"NSNumber"];

      ASSIGN(_pkAttributeArray, [NSArray arrayWithObject: attr]);
      RELEASE(attr);
      //TODO: set encoding via connection dictionary and use throught adaptor.
      encoding = [NSString defaultCStringEncoding];
    }

  return self;
}

- (void)dealloc
{
  if ([self isOpen])
    [self closeChannel];

  DESTROY(_adaptorContext);
  DESTROY(_sqlExpression);
  DESTROY(_oidToTypeName);
  DESTROY(_pkAttributeArray);

  [super dealloc];
}

- (BOOL)isOpen
{
  return (_pgConn ? YES : NO);
}

- (void)openChannel
{
  //OK
  NSAssert(!_pgConn, @"Channel already opened");

  _pgConn = [(PostgreSQLAdaptor *)[[self adaptorContext] adaptor] newPGconn];

  if (_pgConn)
    {
      [self _setDateStyle];
      [self _readServerVersion];
      [self _describeDatabaseTypes];
    }
}

- (void)closeChannel
{
  NSAssert(_pgConn, @"Channel not opened");

  [self _cancelResults];
  [(PostgreSQLAdaptor *)[[self adaptorContext] adaptor] releasePGconn: _pgConn
			force: NO];
  _pgConn = NULL;
}

- (BOOL)isFetchInProgress
{
  return _isFetchInProgress;
}

- (PGconn *)pgConn
{
  return _pgConn;
}

- (PGresult *)pgResult
{
  return _pgResult;
}

- (void)cancelFetch
{
  EOAdaptorContext *adaptorContext = nil;

  EOFLOGObjectFnStart();

  adaptorContext = [self adaptorContext];
  [self cleanupFetch];

//NO ??  [self _cancelResults];//Done in cleanup fetch
//  [_adaptorContext autoCommitTransaction];//Done in cleanup fetch
  EOFLOGObjectFnStop();
}

- (void)_cancelResults
{
  EOFLOGObjectFnStart();

  _fetchBlobsOid = NO;

  DESTROY(_attributes);
  DESTROY(_origAttributes);

  if (_pgResult)
    {
      PQclear(_pgResult);
      _pgResult = NULL;
      _currentResultRow = -2;
    }

  _isFetchInProgress = NO;

  EOFLOGObjectFnStop();
}

- (BOOL)advanceRow
{
  BOOL advanceRow = NO;

  // fetch results where read then freed
  EOFLOGObjectFnStart();

  if (_pgResult)
    {    
      // next row
      _currentResultRow++;
      
      // check if result set is finished
      if (_currentResultRow >= PQntuples(_pgResult))
        {
          [self _cancelResults];
        }
      else
        advanceRow = YES;
    }

  EOFLOGObjectFnStop();

  return advanceRow;	
}

- (NSArray*)lowLevelResultFieldNames: (PGresult*)res
{
  int nb = PQnfields(res);
  NSMutableArray *names 
    = AUTORELEASE([PSQLA_alloc(NSMutableArray) initWithCapacity: nb]);
  int i;
  IMP namesAO=NULL; //addObject:

  for (i = 0; i < nb; i++)
    {
      char *szName = PQfname(res,i);
      unsigned length = szName ? strlen(szName) : 0;
      NSString *name = [(PSQLA_alloc(NSString)) initWithBytes: szName
						length: length
						encoding: encoding];
      PSQLA_AddObjectWithImpPtr(names,&namesAO,name);
      RELEASE(name);
    }

  return names;
}

- (NSMutableDictionary *)fetchRowWithZone: (NSZone *)zone
{
//TODO
/*
//self cleanupFetch quand plus de row !!
valueClassName...externaltype on each attr
self adaptorContext
context adaptor
adaptor databaseEncoding//2


self dictionaryWithObjects:??? 
forAttributes:_attributes
zone:zone
//end
*/
  NSMutableDictionary *dict = nil;

  EOFLOGObjectFnStart();

  if (_delegateRespondsTo.willFetchRow)
    [_delegate adaptorChannelWillFetchRow: self];
  
  NSDebugMLLog(@"gsdb",@"[self isFetchInProgress]: %s",
	       ([self isFetchInProgress] ? "YES" : "NO"));

  if ([self isFetchInProgress])
    {
      NSDebugMLLog(@"gsdb", @"ATTRIBUTES=%@", _attributes);

      if (!_attributes)
        [self _describeResults];

      if ([self advanceRow] == NO)
        {
          NSDebugMLLog(@"gsdb", @"No Advance Row", "");

          // Return nil to indicate that the fetch operation was finished      
          if (_delegateRespondsTo.didFinishFetching)
            [_delegate adaptorChannelDidFinishFetching: self];
      
          [self _cancelResults];
        }
      else
        {    
          int i;
          int count = [_attributes count];
          id valueBuffer[100];
          id *values = NULL;
          IMP attributesOAI=NULL; // objectAtIndex:

          NSDebugMLLog(@"gsdb", @"count=%d", count);

          if (count > PQnfields(_pgResult))
            {
              NSDebugMLog(@"attempt to read %d attributes when the result set has only %d columns",
                          count, PQnfields(_pgResult));
              NSDebugMLog(@"_attributes=%@", _attributes);
              NSDebugMLog(@"result=%@", [self lowLevelResultFieldNames:
						_pgResult]);
              [NSException raise: PostgreSQLException
                           format: @"attempt to read %d attributes "
                           @"when the result set has only %d columns",
                           count, PQnfields(_pgResult)];
            }

          if (count > 100)
            values = (id *)NSZoneMalloc(zone, count * sizeof(id));
          else
            values = valueBuffer;

          for (i = 0; i < count; i++)
            {
              EOAttribute *attr = PSQLA_ObjectAtIndexWithImpPtr(_attributes,&attributesOAI,i);
              int length = 0;
              const char *string = NULL;

              // If the column has the NULL value insert EONull in row

              if (PQgetisnull(_pgResult, _currentResultRow, i))
                {
                  values[i] = RETAIN(PSQLA_EONull); //to be compatible with others returned values
                }
              else
                {
                  string = PQgetvalue(_pgResult, _currentResultRow, i);
                  length = PQgetlength(_pgResult, _currentResultRow, i);
                  
                  // if external type for this attribute is "inversion" then this
                  // column represents an Oid of a large object

                  if ([[attr externalType] isEqual: @"inversion"])
                    {
                      if (!_fetchBlobsOid)
                        {
                          string = [self _readBinaryDataRow: (Oid)atol(string)
                                         length:&length zone: zone];

                          values[i] = newValueForBytesLengthAttribute(string,length,attr,encoding);
                        }
                      else
                        {
                          // The documentatin states that for efficiency
			  // reasons, the returned value is NOT autoreleased
			  // yet in the case of GNUstep-base it would be more
			  // efficient if the numberWithLong: method would be
			  // used as we could often skip alloc / dealloc
			  // and get a cached value.  We could use it and
			  // send retain, or we could start maintaing our
			  // own cache.
                          values[i] = [PSQLA_alloc(NSNumber) initWithLong: atol(string)];
                        }
                    }
                  else
                    {
                      //For efficiency reasons, the returned value is NOT autoreleased !
                      values[i] = newValueForBytesLengthAttribute(string,length,attr,encoding);
                    }
                }

              NSDebugMLLog(@"gsdb", @"value[%d] (%p)=%@ of class: %@", 
                           i, values[i], values[i], [values[i] class]);

              // We don't want to add nil value to dictionary !
              NSAssert1(values[i],@"No value for attribute: %@",attr);
            }

          NSDebugMLLog(@"gsdb", @"values count=%d values=%p", count, values);
          NSDebugMLLog(@"gsdb", @"_attributes=%@", _attributes);

          dict = [self dictionaryWithObjects: values
                       forAttributes: _attributes
                       zone: zone];

	  /* The caller of newValue methods/funnction is
	     responsible for releasing the values.  An adaptor can
	     optimize allocation by taking that into account yet
	     the retain balance must be kept.  */
          for (i = 0; i < count; i++)
	    {
	      [values[i] release];
	    }

          if (values != valueBuffer)
            NSZoneFree(zone, values);

          if (_delegateRespondsTo.didFetchRow)
            [_delegate adaptorChannel: self didFetchRow: dict];
        }
    }

  NSDebugMLLog(@"gsdb", @"row: %@", dict);

  EOFLOGObjectFnStop();

  return dict; //an EOMutableKnownKeyDictionary
}

- (BOOL)_evaluateCommandsUntilAFetch
{
  BOOL ret = NO;
  ExecStatusType status;

  EOFLOGObjectFnStart();

  // Check results
  status = PQresultStatus(_pgResult);

  NSDebugMLLog(@"gsdb",@"status=%d (%s)",
              (int)status,
              PQresStatus(status));

  switch (status)
    {
    case PGRES_EMPTY_QUERY:
      _isFetchInProgress = NO;
      ret = YES;
      break;
    case PGRES_COMMAND_OK:
      _isFetchInProgress = NO;
      ret = YES;
      break;
    case PGRES_TUPLES_OK:
      _isFetchInProgress = YES;
      _currentResultRow = -1;
      ret = YES;
      break;
    case PGRES_COPY_OUT:
      _isFetchInProgress = NO;
      ret = YES;
      break;
    case PGRES_COPY_IN:
      _isFetchInProgress = NO;
      ret = YES;
      break;
    case PGRES_BAD_RESPONSE:
    case PGRES_NONFATAL_ERROR:
    case PGRES_FATAL_ERROR: 
      {
        NSString* errorString=[NSString stringWithCString:PQerrorMessage(_pgConn)];
        if ([self isDebugEnabled])
          NSLog(@"SQL expression '%@' caused %@",
                [_sqlExpression statement], errorString);
        NSDebugMLLog(@"SQL expression '%@' caused %@",
                     [_sqlExpression statement], errorString);
        [NSException raise: PostgreSQLException
		     format: @"unexpected result returned by PQresultStatus(): %@",errorString];

        EOFLOGObjectFnStop();

        return NO;
      }
    default:
      {        
        NSString* errorString=[NSString stringWithCString:PQerrorMessage(_pgConn)];
        if ([self isDebugEnabled])
          NSLog(@"SQL expression '%@' returned status %d: %@",
                [_sqlExpression statement], status, errorString);
        NSDebugMLLog(@"SQL expression '%@' returned status %d: %@",
                     [_sqlExpression statement], status, errorString);
        [NSException raise: PostgreSQLException
		     format: @"unexpected result returned by PQresultStatus(): status %d: %@",
                     status,errorString];

        break;
      }
    }

  NSDebugMLLog(@"gsdb", @"ret=%s", (ret ? "YES" : "NO"));
  NSDebugMLLog(@"gsdb", @"_isFetchInProgress=%s", (_isFetchInProgress ? "YES" : "NO"));

  if (ret == YES)
    {
      PGnotify *notify = PQnotifies(_pgConn);
      const char *insoid = NULL;

      if (notify)
        {
          if (_postgresDelegateRespondsTo.postgresNotification)
            [_delegate postgresChannel: self
                       receivedNotification:
                         [NSString stringWithCString: notify->relname]];

          free(notify);
        }
        
      insoid = PQoidStatus(_pgResult);

      if (*insoid && _postgresDelegateRespondsTo.postgresInsertedRowOid)
        {
          Oid oid = atol(insoid);

          [_delegate postgresChannel: self insertedRowWithOid: oid];
        }
    }

  NSDebugMLLog(@"gsdb",@"_isFetchInProgress=%s",
	       (_isFetchInProgress ? "YES" : "NO"));

  if ([self isFetchInProgress])// Mirko: TODO remove this !
    [self _describeResults];

  if ([self isDebugEnabled])
    {
      NSString *message = [NSString stringWithCString: PQcmdStatus(_pgResult)];

      if (status == PGRES_TUPLES_OK)
        message = [NSString stringWithFormat:
                              @"Command status %@. Returned %d rows with %d columns ",
                            message, PQntuples(_pgResult), PQnfields(_pgResult)];
      NSLog (@"PostgreSQLAdaptor: %@", message);
    }
  
  NSDebugMLLog(@"gsdb", @"ret=%s", (ret ? "YES" : "NO"));

  EOFLOGObjectFnStop();

  return ret;
}

- (BOOL)_evaluateExpression: (EOSQLExpression *)expression
             withAttributes: (NSArray*)attributes
{
  BOOL result = NO;
  EOAdaptorContext *adaptorContext = nil;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"expression=%@", expression);

  ASSIGN(_sqlExpression, expression);
  ASSIGN(_origAttributes, attributes);

//  NSDebugMLLog(@"gsdb",@"EE _origAttributes=%@",_origAttributes);
//  NSDebugMLLog(@"gsdb",@"EE _attributes=%@",_attributes);
  NSDebugMLLog(@"gsdb", @"PostgreSQLAdaptor: execute command:\n%@\n",
	       [expression statement]);

  if ([self isDebugEnabled] == YES)
    NSLog(@"PostgreSQLAdaptor: execute command:\n%@\n",
	  [expression statement]);
//call PostgreSQLChannel numberOfAffectedRows
  /* Send the expression to the SQL server */

  _pgResult = PQexec(_pgConn, (char *)[[[expression statement] stringByAppendingString:@";"] cStringUsingEncoding: encoding]);
  NSDebugMLLog(@"gsdb", @"_pgResult=%p", (void*)_pgResult);

  if (_pgResult == NULL)
    {
      if ([self isDebugEnabled])
        {
          adaptorContext = [self adaptorContext];
          [(PostgreSQLAdaptor *)[adaptorContext adaptor]
                                privateReportError: _pgConn];
        }
    }
  else
    {
      /* Check command results */
      if ([self _evaluateCommandsUntilAFetch] != NO)
        result = YES;
    }

//self numberOfAffectedRows
  NSDebugMLLog(@"gsdb", @"result: %s", (result ? "YES" : "NO"));
//  NSDebugMLLog(@"gsdb",@"FF attributes=%@",_attributes);

  EOFLOGObjectFnStop();

  return result;
}

- (void)evaluateExpression: (EOSQLExpression *)expression // OK quasi
{
  PostgreSQLContext *adaptorContext = nil;

  EOFLOGObjectFnStart();

//_evaluationIsDirectCalled=1
  adaptorContext = (PostgreSQLContext *)[self adaptorContext];
//call expression statement
//call adaptorContext adaptor
//call adaptor databaseEncoding
//call self setErrorMessage
//call expre statement

  NSDebugMLLog(@"gsdb", @"expression=%@", expression);

  if (_delegateRespondsTo.shouldEvaluateExpression)
    {
      BOOL response
	= [_delegate adaptorChannel: self
		     shouldEvaluateExpression: expression];

      if (response == NO)
	return;
    }

  if ([self isOpen] == NO)
    [NSException raise: PostgreSQLException
		 format: @"cannot execute SQL expression. Channel is not opened."];

  [self _cancelResults];
  [adaptorContext autoBeginTransaction: NO/*YES*/]; //TODO: shouldbe yes ??

  if (![self _evaluateExpression: expression
	     withAttributes: nil])
    {
      NSDebugMLLog(@"gsdb", @"_evaluateExpression:withAttributes: return NO", "");
      [self _cancelResults];
    }
  else
    {
      NSDebugMLLog(@"gsdb", @"expression=%@ [self isFetchInProgress]=%d",
                   expression,
                   [self isFetchInProgress]);
      if (![self isFetchInProgress])//If a fetch is in progress, we don't want to commit because 
        //it will cancel fetch. I'm not sure it the 'good' way to do
        [adaptorContext autoCommitTransaction];

      if (_delegateRespondsTo.didEvaluateExpression)
        [_delegate adaptorChannel: self didEvaluateExpression: expression];
    }

  EOFLOGObjectFnStop();
}

- (void)insertRow: (NSDictionary *)row
        forEntity: (EOEntity *)entity
{
  EOSQLExpression *sqlexpr = nil;
  NSMutableDictionary *nrow = nil;
  NSEnumerator *enumerator = nil;
  NSString *attrName = nil;
  PostgreSQLContext *adaptorContext = nil;
  IMP attrEnumNO=NULL; // nextObject
  IMP rowOFK=NULL; // objectForKey:
  IMP nrowSOFK=NULL; // setObject:forKey:
  IMP nrowOFK=NULL; // objectForKey:

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"row=%@", row);

  if (![self isOpen])
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x: attempt to insert rows with no open channel",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  if (!row || !entity)
    [NSException raise: NSInvalidArgumentException 
		 format: @"row and entity arguments for insertRow:forEntity:"
		 @" must not be nil objects"];

  if ([self isFetchInProgress])
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x: attempt to insert rows with fetch in progress",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  /* Before creating the SQL INSERT expression we have to replace in the
     row the large objects as Oids and to insert them with the large
     object file-like interface */

  nrow = AUTORELEASE([row mutableCopy]);

  adaptorContext = (PostgreSQLContext *)[self adaptorContext];

  [self _cancelResults]; //No done by WO

  NSDebugMLLog(@"gsdb", @"autoBeginTransaction", "");
  [adaptorContext autoBeginTransaction: YES];
/*:
 row allKeys
 allkey sortedArrayUsingSelector:compare:
each key
*/

  enumerator = [row keyEnumerator];
  while ((attrName = PSQLA_NextObjectWithImpPtr(enumerator,&attrEnumNO)))
    {
      EOAttribute *attribute = nil;
      NSString *externalType = nil;
      id value = nil;

      NSDebugMLLog(@"gsdb", @"attrName=%@", attrName);

      attribute=[entity attributeNamed: attrName];
      NSDebugMLLog(@"gsdb", @"attribute=%@", attribute);

      if (!attribute)
	return; //???????????

      value = PSQLA_ObjectForKeyWithImpPtr(row,&rowOFK,attrName);
      NSDebugMLLog(@"gsdb", @"value=%@", value);

      externalType = [attribute externalType];
      NSDebugMLLog(@"gsdb", @"externalType=%@", externalType);

      /* Insert the binary value into the binaryDataRow dictionary */
      if ([externalType isEqual: @"inversion"])
        {
	  id binValue = PSQLA_ObjectForKeyWithImpPtr(nrow,&nrowOFK,attrName);
	  Oid binOid = [self _insertBinaryData: binValue 
			     forAttribute: attribute];
	  value = [NSNumber numberWithLong: binOid];
        }
      else if ([externalType isEqual: @"NSString"]) //??
        {
          //TODO: database encoding
          // [[adaptorContext adaptor] databaseEncoding]
        }

      PSQLA_SetObjectForKeyWithImpPtr(nrow,&nrowSOFK,value,attrName);
    }
  
  NSDebugMLLog(@"gsdb", @"nrow=%@", nrow);

  if ([nrow count] > 0)
    {
      sqlexpr = [[[_adaptorContext adaptor] expressionClass]
		  insertStatementForRow: nrow
		  entity: entity];
      NSDebugMLLog(@"gsdb", @"sqlexpr=%@", sqlexpr);

      if ([self _evaluateExpression: sqlexpr withAttributes: nil] == NO) //call evaluateExpression:
	[NSException raise: EOGeneralAdaptorException
                     format: @"%@ -- %@ 0x%x: cannot insert row for entity '%@'",
                     NSStringFromSelector(_cmd),
                     NSStringFromClass([self class]), 
                     self,
                     [entity name]];
    }

  [_adaptorContext autoCommitTransaction];

  EOFLOGObjectFnStop();
}

- (unsigned)deleteRowsDescribedByQualifier: (EOQualifier *)qualifier
                                    entity: (EOEntity *)entity
{
  EOSQLExpression *sqlexpr = nil;
  unsigned long rows = 0;
  PostgreSQLContext *adaptorContext;

  EOFLOGObjectFnStart();

  if (![self isOpen])
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x: attempt to delete rows with no open channel",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  if (!qualifier || !entity)
    [NSException raise: NSInvalidArgumentException
		 format: @"%@ -- %@ 0x%x: qualifier and entity arguments "
		 @" must not be nil objects",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  if ([self isFetchInProgress])
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x: attempt to delete rows with fetch in progress",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  adaptorContext = (PostgreSQLContext *)[self adaptorContext];

  [self _cancelResults];
  [_adaptorContext autoBeginTransaction: NO];

  sqlexpr = [[[_adaptorContext adaptor] expressionClass]
	      deleteStatementWithQualifier: qualifier
	      entity: entity];

  if ([self _evaluateExpression: sqlexpr withAttributes: nil])
    rows = strtoul(PQcmdTuples(_pgResult), NULL, 10);

  [adaptorContext autoCommitTransaction];

  EOFLOGObjectFnStop();
  return rows;
}

- (void)selectAttributes: (NSArray *)attributes
      fetchSpecification: (EOFetchSpecification *)fetchSpecification
                    lock: (BOOL)flag
                  entity: (EOEntity *)entity
{
  EOSQLExpression *sqlExpr = nil;

//objectForKey:EOAdaptorQuotesExternalNames ret: nil
//lastObject ret NSRegistrationDomain
//objectForKey:NSRegistrationDomain ret dict 
//objectForKey:EOAdaptorQuotesExternalNames 
//attr count
//PostgreSQLExpression initWithEntity:
  //setUseliases:YES
//prepareSelectExpressionWithAttributes:lock:fetchSpecification:
//statement
//adaptorContext
//a con autoBeginTransaction
//end

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb",@"%@ -- %@ 0x%x: isFetchInProgress=%s",
	       NSStringFromSelector(_cmd),
	       NSStringFromClass([self class]),
	       self,
	       ([self isFetchInProgress] ? "YES" : "NO"));

  if (![self isOpen])
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x: attempt to select attributes with no open channel",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];
  
  if ([self isFetchInProgress])
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x: attempt to select attributes with fetch in progress",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];
  
  if (_delegateRespondsTo.shouldSelectAttributes)
    if (![_delegate adaptorChannel: self
		    shouldSelectAttributes: attributes
		    fetchSpecification: fetchSpecification
		    lock: flag
		    entity: entity])
      return;

  NSDebugMLLog(@"gsdb", @"%@ -- %@ 0x%x: isFetchInProgress=%s",
	       NSStringFromSelector(_cmd),
	       NSStringFromClass([self class]),
	       self,
	       ([self isFetchInProgress] ? "YES" : "NO"));

  [self _cancelResults];

  NSDebugMLLog(@"gsdb", @"%@ -- %@ 0x%x: isFetchInProgress=%s",
	       NSStringFromSelector(_cmd),
	       NSStringFromClass([self class]),
	       self,
	       ([self isFetchInProgress] ? "YES" : "NO"));

  [_adaptorContext autoBeginTransaction: NO];

  ASSIGN(_attributes, attributes);
//  NSDebugMLLog(@"gsdb",@"00 attributes=%@",_attributes);


  NSAssert([attributes count] > 0, @"No Attributes");

  sqlExpr = [[[_adaptorContext adaptor] expressionClass]
	      selectStatementForAttributes: attributes
	      lock: flag
	      fetchSpecification: fetchSpecification
	      entity: entity];

  NSDebugMLLog(@"gsdb", @"sqlExpr=%@", sqlExpr);
//  NSDebugMLLog(@"gsdb",@"AA attributes=%@",_attributes);

  [self _evaluateExpression: sqlExpr
        withAttributes: attributes];

  NSDebugMLLog(@"gsdb", @"After _evaluate", "");
//  NSDebugMLLog(@"gsdb",@"BB attributes=%@",_attributes);
  [_adaptorContext autoCommitTransaction];
  NSDebugMLLog(@"gsdb", @"After autoCommitTransaction", "");

  if (_delegateRespondsTo.didSelectAttributes)
    [_delegate adaptorChannel: self
	       didSelectAttributes: attributes
	       fetchSpecification: fetchSpecification
	       lock: flag
	       entity: entity];
//  NSDebugMLLog(@"gsdb",@"CC attributes=%@",_attributes);

  EOFLOGObjectFnStop();
}

- (unsigned int)updateValues: (NSDictionary *)values
  inRowsDescribedByQualifier: (EOQualifier *)qualifier
                      entity: (EOEntity *)entity
{
//autoBeginTransaction
//entity attributes
//externaltype on each attr
//adaptor expressionClass
//exprclass alloc initwithentity
//expr setUseAliases:NO
//exp prepareUpdateExpressionWithRow:qualifier:
//self evaluateExpression:
//autoCommitTransaction
//return number of affeted rows
//end

  EOSQLExpression *sqlExpr = nil;
  NSMutableDictionary *mrow = nil;
  NSMutableArray *invAttributes = nil;
  NSEnumerator *enumerator = nil;
  NSString *attrName = nil;
  NSString *externalType = nil;
  EOAttribute *attr = nil;
  PostgreSQLContext *adaptorContext = nil;
  unsigned long rows = 0;
  IMP valuesOFK=NULL; // objectForKey:

  EOFLOGObjectFnStart();
  
  if (![self isOpen])
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x: attempt to update values with no open channel",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  if ([self isFetchInProgress])
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x: attempt to update values with fetch in progress",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  if ([values count] > 0)
    {
      IMP valueEnumNO=NULL; // nextObject
      IMP mrowSOFK=NULL; // setObject:forKey;

      mrow = AUTORELEASE([values mutableCopyWithZone: [values zone]]);

      // Get EOAttributes involved in update operation
      // Modify "inversion" attributes to NSNumber type with the Oid

      invAttributes = AUTORELEASE([[NSMutableArray alloc] initWithCapacity: [mrow count]]);

      enumerator = [values keyEnumerator];
      while ((attrName = PSQLA_NextObjectWithImpPtr(enumerator,&valueEnumNO)))
        {
          attr = [entity attributeNamed: attrName];
          externalType = [attr externalType];

          if (attr == nil)
            return 0; //???
/*
          [mrow setObject:[attr adaptorValueByConvertingAttributeValue://Not in WO
			      [values objectForKey:attrName]]
                forKey:attrName];
*/
          PSQLA_SetObjectForKeyWithImpPtr(mrow,&mrowSOFK,
                                        PSQLA_ObjectForKeyWithImpPtr(values,&valuesOFK,attrName),
                                        attrName);

          if ([externalType isEqual: @"inversion"])
            [invAttributes addObject: attr];
        }

      [self _cancelResults]; //Not in WO
      adaptorContext = (PostgreSQLContext *)[self adaptorContext];
      [adaptorContext autoBeginTransaction: YES];

      if ([invAttributes count])
        {
          IMP invAttributesNO=NULL; // nextObject
          // Select with update qualifier to see there is only one row
          // to be updated and to get the large objects (to be updatetd)
          // Oid from dataserver - there is a hack here based on the fact that
          // in update there in only one table and no flattened attributes

          NSDictionary *dbRow = nil;

          sqlExpr = [[[_adaptorContext adaptor] expressionClass]
                      selectStatementForAttributes: invAttributes
                      lock: NO
                      fetchSpecification:
                        [EOFetchSpecification
			  fetchSpecificationWithEntityName: [entity name]
                          qualifier: qualifier
                          sortOrderings: nil]
                      entity: entity];
          [self _evaluateExpression: sqlExpr withAttributes: nil];

          _fetchBlobsOid = YES;
          dbRow = [self fetchRowWithZone: NULL];
          _fetchBlobsOid = NO;

          [self _cancelResults];

          // Update the large objects and modify the row to update with Oid's

          enumerator = [invAttributes objectEnumerator];          
          while ((attr = PSQLA_NextObjectWithImpPtr(enumerator,&invAttributesNO)))
            {
              Oid oldOid;
              Oid newOid;
              NSData *data;

              attrName = [attr name];
              data = [mrow objectForKey: attrName];

              oldOid = [[dbRow objectForKey:attrName] longValue];
              newOid = [self _updateBinaryDataRow: oldOid data: data];

              PSQLA_SetObjectForKeyWithImpPtr(mrow,&mrowSOFK,
                                            [NSNumber numberWithUnsignedLong: newOid],
                                            attrName);
            }
        }

      // Now we have all: one and only row to update and binary rows
      // (large objects) where updated and their new Oid set in the row

      rows = 0;

      NSDebugMLLog(@"gsdb", @"[mrow count]=%d", [mrow count]);

      if ([mrow count] > 0)
        {
          sqlExpr = [[[_adaptorContext adaptor] expressionClass]
                      updateStatementForRow: mrow
                      qualifier: qualifier
                      entity: entity];

          //wo call evaluateExpression:
          if ([self _evaluateExpression: sqlExpr withAttributes: nil])
            rows = strtoul(PQcmdTuples(_pgResult), NULL, 10);
        }

      [adaptorContext autoCommitTransaction];
    }

  EOFLOGObjectFnStop();
  
  return rows;
}

/* The binaryDataRow should contain only one binary attribute */

- (char *)_readBinaryDataRow: (Oid)oid
                      length: (int *)length
                        zone: (NSZone *)zone;
{
  int fd;
  int len, wrt;
  char *bytes;

  if (oid == 0)
    {
      *length = 0;
      return NULL;
    }

  fd = lo_open(_pgConn, oid, INV_READ|INV_WRITE);
  if (fd < 0)
    [NSException raise: PostgreSQLException
		 format: @"cannot open large object Oid = %ld", oid];

  lo_lseek(_pgConn, fd, 0, SEEK_END);
  len = lo_tell(_pgConn, fd);
  lo_lseek(_pgConn, fd, 0, SEEK_SET);

  if (len < 0)
    [NSException raise: PostgreSQLException
		 format: @"error while getting size of large object Oid = %ld", oid];

  bytes = NSZoneMalloc(zone, len);
  wrt = lo_read(_pgConn, fd, bytes, len);

  if (len != wrt)
    {
      NSZoneFree(zone, bytes);
      [NSException raise: PostgreSQLException
		   format: @"error while reading large object Oid = %ld", oid];
    }
  lo_close(_pgConn, fd);

  *length = len;

  return bytes;
}

- (Oid)_insertBinaryData: (NSData *)binaryData
            forAttribute: (EOAttribute *)attr
{
  int len;
  const char* bytes;
  Oid oid;
  int fd, wrt;

  if ((id)binaryData == [EONull null] || binaryData == nil)
    return 0;

  len = [binaryData length];
  bytes = [binaryData bytes];

  oid = lo_creat(_pgConn, INV_READ|INV_WRITE);
  if (oid == 0)
    [NSException raise: PostgreSQLException
		 format: @"cannot create large object"];

  fd = lo_open(_pgConn, oid, INV_READ|INV_WRITE);
  if (fd < 0)
    [NSException raise: PostgreSQLException
		 format: @"cannot open large object Oid = %ld", oid];

  wrt = lo_write(_pgConn, fd, (char *)bytes, len);

  if (len != wrt)
    [NSException raise: PostgreSQLException
		 format: @"error while writing large object Oid = %ld", oid];

  lo_close(_pgConn, fd);

  return oid;
}

- (Oid)_updateBinaryDataRow: (Oid)oid
                       data: (NSData *)binaryData
{
  int len;
  const char* bytes;
  int wrt, fd;

  if (oid)
    lo_unlink(_pgConn, oid);

  if ((id)binaryData == [EONull null] || binaryData == nil)
    return 0;

  len = [binaryData length];
  bytes = [binaryData bytes];

  oid = lo_creat(_pgConn, INV_READ|INV_WRITE);
  if (oid == 0)
    [NSException raise: PostgreSQLException
		 format: @"cannot create large object"];

  fd = lo_open(_pgConn, oid, INV_READ|INV_WRITE);
  if (fd < 0)
    [NSException raise: PostgreSQLException
		 format: @"cannot open large object Oid = %ld", oid];

  wrt = lo_write(_pgConn, fd, (char*)bytes, len);

  if (len != wrt)
    [NSException raise: PostgreSQLException
		 format: @"error while writing large object Oid = %ld", oid];

  lo_close(_pgConn, fd);

  return oid;
}

/* Read type oid and names from the database server. 
   Called on each openChannel to refresh info. */
- (void)_describeDatabaseTypes
{
  int i, count;

  _pgResult = PQexec(_pgConn, 
		     "SELECT oid, typname FROM pg_type WHERE typrelid = 0");

  if (_pgResult == NULL || PQresultStatus(_pgResult) != PGRES_TUPLES_OK)
    {
      _pgResult = NULL;
      [NSException raise: PostgreSQLException
		   format: @"cannot read type name informations from database. "
		   @"bad response from server"];
    }
  
  if (PQnfields(_pgResult) != 2)
    {
      _pgResult = NULL;
      [NSException raise: PostgreSQLException
		   format: @"cannot read type name informations from database. "
		   @"results should have two columns"];
    }

  [_oidToTypeName removeAllObjects];
  count = PQntuples(_pgResult);

  for (i = 0; i < count; i++)
    {
      char* oid = PQgetvalue(_pgResult, i, 0);
      char* typ = PQgetvalue(_pgResult, i, 1);

      [_oidToTypeName setObject: [NSString stringWithCString: typ]
		      forKey: [NSNumber numberWithLong: atol(oid)]];
    }

  PQclear(_pgResult);
  _pgResult = NULL;
}

- (void)_readServerVersion
{
  NSString *version;

  _pgResult = PQexec(_pgConn, 
		     "SELECT version()");

  if (_pgResult == NULL || PQresultStatus(_pgResult) != PGRES_TUPLES_OK)
    {
      _pgResult = NULL;
      [NSException raise: PostgreSQLException
		   format: @"cannot read type name informations from database. "
		   @"bad response from server"];
    }

  version = [NSString stringWithCString: PQgetvalue(_pgResult, 0, 0)];
  _pgVersion = [version parsedFirstVersionSubstring];

  PQclear(_pgResult);
  _pgResult = NULL;
}

- (NSArray *)attributesToFetch
{
  return _attributes;
}

- (void)setAttributesToFetch: (NSArray *)attributes
{
  //call adaptorContext
  NSDebugMLLog(@"gsdb", @"PostgreSQLChannel: setAttributesToFetch %p:%@",
	       attributes, attributes);

  ASSIGN(_attributes, attributes);
}

- (NSArray *)describeResults
{
  NSArray *desc;

  EOFLOGObjectFnStart();

  if (![self isFetchInProgress])
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x: attempt to describe results with no fetch in progress",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  desc = [self attributesToFetch];

  EOFLOGObjectFnStop();

  return desc;
}

- (void)_describeResults
{
  int colsNumber;

  EOFLOGObjectFnStart();

  colsNumber=_pgResult ? PQnfields(_pgResult): 0;
  NSDebugMLLog(@"gsdb", @"colsNumber=%d", colsNumber);

  if (colsNumber == 0)
    {
      [self setAttributesToFetch: PSQLA_NSArray];
    }
  else if (!_attributes) //??
    {
      int i;
      id *attributes = NULL;      
      IMP origAttributesOAI=NULL;
      IMP oidToTypeNameOFK=NULL;

      attributes = alloca(colsNumber * sizeof(id));

      for (i = 0; i < colsNumber; i++)
        {
	  EOAttribute *attribute 
	    = AUTORELEASE([PSQLA_alloc(EOAttribute) init]);
          NSString *externalType;
          NSString *valueClass = @"NSString";
          NSString *valueType = nil;

          if (_origAttributes)
            {
              EOAttribute *origAttr = (EOAttribute *)
                PSQLA_ObjectAtIndexWithImpPtr(_origAttributes,&origAttributesOAI,i);

              [attribute setName: [origAttr name]];
              [attribute setColumnName: [origAttr columnName]];
              [attribute setExternalType: [origAttr externalType]];
              [attribute setValueType: [origAttr valueType]];
              [attribute setValueClassName: [origAttr valueClassName]];
            }
          else
            {
              NSNumber *externalTypeNumber;
	      externalTypeNumber 
		= [NSNumber numberWithLong: PQftype(_pgResult, i)];
              externalType = PSQLA_ObjectForKeyWithImpPtr(_oidToTypeName,
                                                        &oidToTypeNameOFK,externalTypeNumber);
              
              if (!externalType)
                [NSException raise: PostgreSQLException
                             format: @"cannot find type for Oid = %d",
                             PQftype(_pgResult, i)];

              [attribute setName: [NSString stringWithFormat: @"attribute%d", i]];
              [attribute setColumnName: @"unknown"];
              [attribute setExternalType: externalType];

              //TODO: Optimize ?
              if      ([externalType isEqual: @"bool"])
                valueClass = @"NSNumber", valueType = @"c";
              else if ([externalType isEqual: @"char"])
                valueClass = @"NSNumber", valueType = @"c";
              else if ([externalType isEqual: @"dt"])
                valueClass = @"NSCalendarDate", valueType = nil;
              else if ([externalType isEqual: @"date"])
                valueClass = @"NSCalendarDate", valueType = nil;
              else if ([externalType isEqual: @"time"])
                valueClass = @"NSCalendarDate", valueType = nil;
              else if ([externalType isEqual: @"float4"])
                valueClass = @"NSNumber", valueType = @"f";
              else if ([externalType isEqual: @"float8"])
                valueClass = @"NSNumber", valueType = @"d";
              else if ([externalType isEqual: @"int2"])
                valueClass = @"NSNumber", valueType = @"s";
              else if ([externalType isEqual: @"int4"])
                valueClass = @"NSNumber", valueType = @"i";
              else if ([externalType isEqual: @"int8"] || [externalType isEqual: @"bigint"])
                valueClass = @"NSNumber", valueType = @"u";
              else if ([externalType isEqual: @"oid"])
                valueClass = @"NSNumber", valueType = @"l";
              else if ([externalType isEqual: @"varchar"])
                valueClass = @"NSString", valueType = nil;
              else if ([externalType isEqual: @"bpchar"])
                valueClass = @"NSString", valueType = nil;
              else if ([externalType isEqual: @"text"])
                valueClass = @"NSString", valueType = nil;
              /*      else if ([externalType isEqual:@"cid"])
                      valueClass = @"NSNumber", valueType = @"";
                      else if ([externalType isEqual:@"tid"])
                      valueClass = @"NSNumber", valueType = @"";
                      else if ([externalType isEqual:@"xid"])
                      valueClass = @"NSNumber", valueType = @"";*/

              [attribute setValueType: valueType];
              [attribute setValueClassName: valueClass];
            }

          attributes[i] = attribute;
        }

      [self setAttributesToFetch: AUTORELEASE([[NSArray alloc]
				     initWithObjects: attributes
				     count: colsNumber])];
    }
//  NSDebugMLLog(@"gsdb",@"_attributes=%@",_attributes);

  EOFLOGObjectFnStop();
}

/* The methods used to generate an model from the meta-information kept by
   the database. */

- (NSArray *)describeTableNames
{
  int i, count;
  NSMutableArray *results = nil;
  char *tableSelect;
  IMP resultsAO=NULL; // addObject:

  if (_pgVersion < 70300)
    {
      tableSelect = "SELECT tablename FROM pg_tables WHERE tableowner != 'postgres' OR tablename NOT LIKE 'pg_%'";
    }
  else
    {
      tableSelect = "SELECT tablename FROM pg_tables WHERE pg_tables.schemaname = 'public'";
    }


  NSAssert(_pgConn, @"Channel not opened");

  _pgResult = PQexec(_pgConn, tableSelect);
		     

  if (_pgResult == NULL
      || PQresultStatus(_pgResult) != PGRES_TUPLES_OK)
    {
      _pgResult = NULL;
      [NSException raise: PostgreSQLException
		   format: @"cannot read list of tables from database. "
		   @"bad response from server"];
    }

  count = PQntuples(_pgResult);
  results= AUTORELEASE([PSQLA_alloc(NSMutableArray) initWithCapacity: count]);

  for (i = 0; i < count; i++)
    {
      char *oid = PQgetvalue(_pgResult, i, 0);

      PSQLA_AddObjectWithImpPtr(results,&resultsAO,
				[NSString stringWithUTF8String: oid]);
    }

  PQclear(_pgResult);
  _pgResult = NULL;

  return [NSArray arrayWithArray: results];
}

- (NSArray *)describeStoredProcedureNames
{
  // TODO
  [self notImplemented: _cmd];
  return nil;
}

- (void)_describeBasicEntityWithName:(NSString *)tableName
			    forModel:(EOModel *)model
{
  EOEntity *entity;
  NSString *stmt;
  EOAttribute *attribute;
  NSString *valueClass = @"NSString";
  NSString *valueType = nil;
  NSString *tableOid;
  unsigned int n, k;
  int count = 0;

  entity = AUTORELEASE([[EOEntity alloc] init]);
  [entity setName: tableName];
  [entity setExternalName: tableName];
  [entity setClassName: @"EOGenericRecord"];
  [model addEntity: entity];

  stmt = [NSString stringWithFormat: @"SELECT oid FROM pg_class "
		 @"WHERE relname = '%@' AND relkind = 'r'",tableName];

  EOAdaptorDebugLog(@"PostgreSQLAdaptor: execute command:\n%@", stmt);
  _pgResult = PQexec(_pgConn, [stmt cString]);

  if (_pgResult == NULL || PQresultStatus(_pgResult) != PGRES_TUPLES_OK)
    {
      _pgResult = NULL;
      [NSException raise: PostgreSQLException
		   format: @"cannot read type name information from database."
		   @"bad response from server"];
    }

  if (PQntuples(_pgResult) != 1)
    {
      _pgResult = NULL;
      [NSException raise: PostgreSQLException
		   format: @"Table %@ doesn't exist", tableName];
    }

  tableOid = [NSString stringWithCString: PQgetvalue(_pgResult,0,0)];
  [entity setUserInfo: [NSDictionary dictionaryWithObject:tableOid 
				     forKey: @"tableOid"]];
  stmt = [NSString stringWithFormat: @"SELECT attname,typname,attnum "
		 @"FROM pg_attribute LEFT JOIN pg_type ON atttypid = oid "
		 @"WHERE attnum > 0 AND attrelid=%@"
		 @"AND attisdropped IS FALSE", tableOid];

  EOAdaptorDebugLog(@"PostgreSQLAdaptor: execute command:\n%@", stmt);
  PQclear(_pgResult);

  _pgResult = PQexec(_pgConn, [stmt cString]);
  count = PQntuples(_pgResult);

  if (count>0)
    {
      for (n = 0; n < count; n++)
        {
          NSString *columnName;
          NSString *externalType;
	  char *name;
	  unsigned length;

	  name = PQgetvalue(_pgResult,n,1);
	  length = name ? strlen(name) : 0;
          
          externalType = [(PSQLA_alloc(NSString)) initWithCString: name
						  length: length];
          
          //TODO optimize ?
          if ([externalType isEqual: @"bool"])
            valueClass = @"NSNumber", valueType = @"c";
          else if ([externalType isEqual: @"char"])
            valueClass = @"NSNumber", valueType = @"c";
          else if ([externalType isEqual: @"dt"])
            valueClass = @"NSCalendarDate", valueType = nil;
          else if ([externalType isEqual: @"date"])
            valueClass = @"NSCalendarDate", valueType = nil;
          else if ([externalType isEqual: @"time"])
            valueClass = @"NSCalendarDate", valueType = nil;
          else if ([externalType isEqual: @"float4"])
            valueClass = @"NSNumber", valueType = @"f";
          else if ([externalType isEqual: @"float8"])
            valueClass = @"NSNumber", valueType = @"d";
          else if ([externalType isEqual: @"int2"])
            valueClass = @"NSNumber", valueType = @"i";
          else if ([externalType isEqual: @"int4"])
            valueClass = @"NSNumber", valueType = @"i";
          else if ([externalType isEqual: @"int8"])
            valueClass = @"NSNumber", valueType = @"l";
          else if ([externalType isEqual: @"oid"])
            valueClass = @"NSNumber", valueType = @"l";
          else if ([externalType isEqual: @"varchar"])
            valueClass = @"NSString", valueType = nil;
          else if ([externalType isEqual: @"bpchar"])
            valueClass = @"NSString", valueType = nil;
          else if ([externalType isEqual: @"text"])
            valueClass = @"NSString", valueType = nil;
          
	  name = PQgetvalue(_pgResult, n, 0);
	  length = name ? strlen(name) : 0;
          columnName = [(PSQLA_alloc(NSString)) initWithCString: name
						length: length];

	  attribute = [PSQLA_alloc(EOAttribute) init];
          [attribute setName: columnName];
          [attribute setColumnName: columnName];
          [attribute setExternalType: externalType];
          [attribute setValueType: valueType];
          [attribute setValueClassName: valueClass];
          [entity addAttribute: attribute];

	  RELEASE(externalType);
	  RELEASE(attribute);
	  RELEASE(columnName);
        }
    };

  PQclear(_pgResult);

  /* Determint primary key. */ 
  stmt = [NSString stringWithFormat: @"SELECT indkey FROM pg_index "
		 @"WHERE indrelid='%@' AND indisprimary = 't'",
		 tableOid];

  EOAdaptorDebugLog(@"PostgreSQLAdaptor: execute command:\n%@", stmt);
  _pgResult = PQexec(_pgConn,[stmt cString]);
  if (PQntuples(_pgResult))
    {
      NSString *pkAttNum 
	= [NSString stringWithCString: PQgetvalue(_pgResult,0,0)];
      pkAttNum = [pkAttNum stringByReplacingString:@" "
                           withString: @", "];

      stmt = [NSString stringWithFormat: @"SELECT attname FROM pg_attribute "
		     @"WHERE attrelid='%@' and attnum in (%@)",
		     tableOid, pkAttNum];
      PQclear(_pgResult);

      EOAdaptorDebugLog(@"PostgreSQLAdaptor: execute command:\n%@", stmt);
      _pgResult = PQexec(_pgConn,[stmt cString]);
 
      if (PQntuples(_pgResult))
	{
	  NSMutableArray *pkeys;
          count = PQntuples(_pgResult);
	  pkeys = [PSQLA_alloc(NSMutableArray) initWithCapacity: count];
	  for (k = 0; k < count; k++)
	    {
	      //TODO: Optimize, it's probably faster to use a mutable
	      // string here instead of alloc/dealloing new strings.
	      NSString *name;
	      const char *cName;
	      unsigned length;

	      cName = PQgetvalue(_pgResult,k,0);
	      length = cName ? strlen(cName) : 0;
	      name  = [(PSQLA_alloc(NSString)) initWithCString: cName
					       length: length];
	      attribute = [entity attributeNamed: name];
	      NSDebugMLLog(@"adaptor", @"pk(%d) name: %@", k, name); 

	      [pkeys addObject: attribute];
	      RELEASE(name);
	    }

	  NSDebugMLLog(@"adaptor", @"pkeys %@", pkeys);
	  [entity setPrimaryKeyAttributes: pkeys];
	  RELEASE(pkeys);
	}
    }
  /* </primary key stuff> */

}


- (void)_describeForeignKeysForEntity:(EOEntity *) entity
			     forModel:(EOModel *) model
{
  NSString  *stmt;
  NSString  *tableOid;
  unsigned int i, j, n, m;

  tableOid = [[entity userInfo] objectForKey: @"tableOid"];
  stmt = [NSString stringWithFormat: @"SELECT tgargs FROM pg_trigger "
		 @"WHERE tgtype=21 AND tgisconstraint='t' AND tgrelid=%@",
		 tableOid];

  PQclear(_pgResult);

  EOAdaptorDebugLog(@"PostgreSQLAdaptor: execute command:\n%@", stmt);
  _pgResult = PQexec(_pgConn, [stmt cString]);

  for (i = 0, n = PQntuples(_pgResult); i < n; i++)
    {
      NSString       *fkString;
      NSArray        *fkComp;
      NSString       *srcEntityName;
      NSString       *dstEntityName;
      EOEntity       *srcEntity;
      EOEntity       *dstEntity;
      NSString       *relationshipName;
      EORelationship *relationship;
      NSSet          *dstPKSet;
      NSMutableSet   *dstAttribNames;
      char           *name;
      unsigned        length;

      name = PQgetvalue(_pgResult,i,0);
      length = name ? strlen(name) : 0;
      fkString = AUTORELEASE([(PSQLA_alloc(NSString)) initWithCString: name
						      length: length]);
      NSDebugMLLog(@"adaptor", @"foreign key: %@\n",fkString);

      fkComp = [fkString componentsSeparatedByString: @"\\000"];

      NSAssert1([fkComp count]>6, @"Illformed constraint:%@", fkString);

      NSDebugMLLog(@"adaptor", @"constaint anme: %@", 
		   [fkComp objectAtIndex:0]);

      /* This assumes that entityName == tableName.  */
      srcEntityName = [fkComp objectAtIndex: 1];
      dstEntityName = [fkComp objectAtIndex: 2];

      srcEntity = [model entityNamed: srcEntityName];
      dstEntity = [model entityNamed: dstEntityName];

      relationshipName = [NSString stringWithFormat:@"to%@", dstEntityName];

      for (j = 1; 
	   ([srcEntity anyAttributeNamed: relationshipName] != nil || 
	    [srcEntity anyRelationshipNamed: relationshipName] != nil);
	   j++)
	{
	  relationshipName = [NSString stringWithFormat:@"to%@_%d", dstEntityName, j];
	}

      relationship = AUTORELEASE([EORelationship new]);
      [relationship setName: relationshipName];
      [srcEntity addRelationship: relationship];

      dstAttribNames = (id)[NSMutableSet set];

      for (j = 4, m = [fkComp count]; j < m; j = j + 2)
	{
	  NSString    *srcAttribName;
	  NSString    *dstAttribName;
	  EOAttribute *srcAttrib;
	  EOAttribute *dstAttrib;
	  EOJoin      *join;

	  srcAttribName = [fkComp objectAtIndex: j];
	  if ([srcAttribName length] == 0) break;
	  dstAttribName = [fkComp objectAtIndex: j + 1];
	  [dstAttribNames addObject: dstAttribName];

	  srcAttrib = [srcEntity attributeNamed: srcAttribName];
	  dstAttrib = [dstEntity attributeNamed: dstAttribName];

	  join 
	    = AUTORELEASE([[EOJoin alloc] initWithSourceAttribute: srcAttrib
					  destinationAttribute: dstAttrib]);
	  [relationship addJoin: join];
	}

      dstPKSet = [NSSet setWithArray: [dstEntity primaryKeyAttributeNames]];

      if ([dstPKSet isSubsetOfSet: dstAttribNames])
	{
	  [relationship setToMany: NO];
	}
      else
	{
	  [relationship setToMany: YES];
	}
      [relationship setJoinSemantic: EOInnerJoin];
    } 
}

- (EOModel *)describeModelWithTableNames: (NSArray *)tableNames
{
  EOModel   *model=nil;
  EOAdaptor *adaptor=nil;
  EOEntity  *entity=nil;
  NSArray   *entityNames=nil;
  unsigned int i=0;
  int tableNamesCount=[tableNames count];
  int entityNamesCount=0;

  adaptor = [[self adaptorContext] adaptor];
  model = AUTORELEASE([[EOModel alloc] init]);

  [model setAdaptorName: [adaptor name]];
  [model setConnectionDictionary: [adaptor connectionDictionary]];

  for (i = 0; i < tableNamesCount; i++)
    {
      NSAutoreleasePool *pool = [NSAutoreleasePool new];
      NSString *name;

      NS_DURING
	name = [tableNames objectAtIndex: i];
	[self _describeBasicEntityWithName: name forModel: model];
      NS_HANDLER
	{
	  RETAIN(localException);
	  [pool release];
	  [AUTORELEASE(localException) raise];
	}
      NS_ENDHANDLER

      [pool release];
    }

  /* <foreign key stuff> */
  entityNames = [model entityNames];
  entityNamesCount=[entityNames count];
  for (i = 0; i < entityNamesCount; i++)
    {
      NSAutoreleasePool *pool = [NSAutoreleasePool new];
      NSString *entityName;

      NS_DURING
	entityName = [entityNames objectAtIndex:i];
	entity = [model entityNamed: entityName];
	[self _describeForeignKeysForEntity: entity forModel: model];
      NS_HANDLER
	{
	  RETAIN(localException);
	  [pool release];
	  [AUTORELEASE(localException) raise];
	}
      NS_ENDHANDLER

      [pool release];
    }

  for (i=0; i < entityNamesCount; i++)
    {
      NSAutoreleasePool *pool = [NSAutoreleasePool new];
      NSMutableArray *classProperties;

      entity = [model entityNamed:[entityNames objectAtIndex:i]];
      classProperties = [NSMutableArray arrayWithArray:[entity attributes]]; 
      [classProperties removeObjectsInArray: [entity primaryKeyAttributes]];
      [entity setClassProperties: classProperties];

      [pool release];
    }

  [model beautifyNames];
  return model;
}

/* extensions for login panel */
- (NSArray *)describeDatabaseNames
{
  NSMutableArray *databaseNames = [NSMutableArray array]; 
  NSString *stmt = [NSString stringWithFormat:@"SELECT datname FROM pg_database LEFT JOIN pg_user "
                            @"ON datdba = usesysid ORDER BY 1"];
  int i; 
  _pgResult = PQexec(_pgConn, [stmt cString]);
  for (i=0; i < PQntuples(_pgResult); i++)
    {
      [databaseNames addObject: [NSString stringWithCString:PQgetvalue(_pgResult,i,0)]]; 
    }
  return (NSArray *)databaseNames;
}

- (BOOL) userNameIsAdministrative:(NSString *)userName
{
  NSString *stmt = [NSString stringWithFormat:@"SELECT usecreatedb FROM pg_user WHERE "
                            @"usename = '%@'",userName]; 
  _pgResult = PQexec(_pgConn, [stmt cString]);
  if (_pgResult != NULL)
    if (PQntuples(_pgResult))
      {
        const char *bytes;
	
	bytes = PQgetvalue(_pgResult,0,0); 
        if (((char *)bytes)[0] == 't' && ((char *)bytes)[1] == 0)
          return YES;
        if (((char *)bytes)[0] == 'f' && ((char *)bytes)[1] == 0)
          return NO;
     
      }
  return NO; 
}

- (void)setDelegate:delegate
{
  [super setDelegate: delegate];

  _postgresDelegateRespondsTo.postgresInsertedRowOid = 
    [delegate respondsToSelector:
		@selector(postgresChannel:insertedRowWithOid:)];
  _postgresDelegateRespondsTo.postgresNotification = 
    [delegate respondsToSelector:
		@selector(postgresChannel:receivedNotification:)];
}

- (NSDictionary *)primaryKeyForNewRowWithEntity:(EOEntity *)entity
{
//entity primaryKeyAttributes
//self adaptorContext
//on each attr attr: adaptorValueType
//entty externalName
//context autoBeginTransaction
//self cleanupFetch######
//attr name
//dictionary with...
  NSDictionary *pk = nil;
  NSString *sqlString;
  NSString *key = nil;
  NSNumber *pkValue = nil;
  const char *string = NULL;
  int length = 0;
  NSString *primaryKeySequenceNameFormat;
  NSString *sequenceName;
  EOSQLExpression *expr;

  EOFLOGObjectFnStart();

  primaryKeySequenceNameFormat 
    = [(PostgreSQLContext*)[self adaptorContext] primaryKeySequenceNameFormat];
  NSAssert(primaryKeySequenceNameFormat, @"No primary sequence name format");

  expr = AUTORELEASE([[[_adaptorContext adaptor] expressionClass] new]);
  sequenceName = [NSString stringWithFormat: primaryKeySequenceNameFormat,
			   [entity primaryKeyRootName]];
  sequenceName = [expr sqlStringForSchemaObjectName: sequenceName];
  sqlString = [NSString stringWithFormat: @"SELECT nextval('%@')",
			sequenceName];
  [expr setStatement: sqlString];

  [self _cancelResults];
  [_adaptorContext autoBeginTransaction: NO];

  [self _evaluateExpression: expr
	withAttributes: _pkAttributeArray];

  if ([self isFetchInProgress] == NO
      || [self advanceRow] == NO)
    {
      [self _cancelResults];
      [_adaptorContext autoCommitTransaction];
    }
  else
    {
      EOAttribute *attr;
      string = PQgetvalue(_pgResult, _currentResultRow, 0);
      length = PQgetlength(_pgResult, _currentResultRow, 0);
      
      attr = [_pkAttributeArray objectAtIndex: 0];
      pkValue = AUTORELEASE(newValueForBytesLengthAttribute(string,length,attr,encoding));

      NSAssert(pkValue, @"no pk value");
      key = [[entity primaryKeyAttributeNames] objectAtIndex: 0];
      NSAssert(key, @"pk key");
  
      [self _cancelResults];
      [_adaptorContext autoCommitTransaction];
      
      pk = [NSDictionary dictionaryWithObject: pkValue
			 forKey: key];
    }

  EOFLOGObjectFnStop();

  return pk;
}

- (void)cleanupFetch
{
  PostgreSQLContext *adaptorContext;

  EOFLOGObjectFnStart();

  adaptorContext = (PostgreSQLContext *)[self adaptorContext];

  NSDebugMLog(@"[self isFetchInProgress]=%s",
              ([self isFetchInProgress] ? "YES" : "NO"));

  if ([self isFetchInProgress])
    {
      BOOL ok;

      [self _cancelResults];

      ok = [adaptorContext autoCommitTransaction];
      //_isTransactionstarted to 0
      //_evaluationIsDirectCalled=0
    }

  EOFLOGObjectFnStop();
}

@end /* PostgreSQLChannel */
