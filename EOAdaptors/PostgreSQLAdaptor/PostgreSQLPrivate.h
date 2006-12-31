/* -*-objc-*-
   PostgreSQLPrivate.h

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: Jan 2005

   This file is part of the GNUstep Database Library.

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
*/

#ifndef __PostgreSQLPrivate_h__
#define __PostgreSQLPrivate_h__

@class NSNumber;
@class EONull;

// ==== Classes ====
extern Class PSQLA_NSStringClass;
extern Class PSQLA_NSNumberClass;
extern Class PSQLA_NSDecimalNumberClass;
extern Class PSQLA_NSCalendarDateClass;
extern Class PSQLA_NSDateClass;
extern Class PSQLA_NSMutableArrayClass;
extern Class PSQLA_EOAttributeClass;

// ==== IMPs ====
extern IMP PSQLA_NSNumber_allocWithZoneIMP;
extern IMP PSQLA_NSDecimalNumber_allocWithZoneIMP;
extern IMP PSQLA_NSString_allocWithZoneIMP;
extern IMP PSQLA_NSCalendarDate_allocWithZoneIMP;
extern IMP PSQLA_NSMutableArray_allocWithZoneIMP;
extern IMP PSQLA_EOAttribute_allocWithZoneIMP;

// ==== Constants ====
extern NSNumber *PSQLA_NSNumberBool_Yes;
extern NSNumber *PSQLA_NSNumberBool_No;

extern EONull   *PSQLA_EONull;
extern NSArray  *PSQLA_NSArray;
extern NSString *PSQLA_postgresCalendarFormat;

// ==== Init Method ====
extern void PSQLA_PrivInit(void);

// ==== IMP Helpers ====

static inline BOOL
_isNilOrEONull(id obj) __attribute__ ((unused));
static inline BOOL
_isNilOrEONull(id obj)
{
  if (PSQLA_EONull == nil) PSQLA_PrivInit();
  return (obj == nil || obj == PSQLA_EONull) ? YES : NO;
}


// ---- NSEnumerator nextObject ----
static inline id
PSQLA_NextObjectWithImpPtr(id object,IMP* impPtr)
{
  if (object)
    {
      if (!*impPtr)
	*impPtr=[object methodForSelector:@selector(nextObject)];
      return (**impPtr)(object,@selector(nextObject));
    }
  else
    return nil;
};

// ---- NSMutableString appendString: ----
#define PSQLA_AppendStringWithImp(string,methodIMP,aString) \
	(*(methodIMP))((string),@selector(appendString:),(aString))

// ---- NSMutableArray addObject: ----
static inline void
PSQLA_AddObjectWithImpPtr(id object,IMP* impPtr,id objectToAdd)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(addObject:)];
      (**impPtr)(object,@selector(addObject:),objectToAdd);
    };
};

// ---- NSArray objectAtIndex: ----
static inline id
PSQLA_ObjectAtIndexWithImpPtr(id object,IMP* impPtr,unsigned index)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(objectAtIndex:)];
      return (**impPtr)(object,@selector(objectAtIndex:),index);
    }
  else
    return nil;
};


// ---- Dictionary objectForKey: ----
static inline id
PSQLA_ObjectForKeyWithImpPtr(id object,IMP* impPtr,id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(objectForKey:)];
      return (**impPtr)(object,@selector(objectForKey:),key);
    }
  else
    return nil;
};

// ---- Dictionary setObject:forKey: ----
static inline void
PSQLA_SetObjectForKeyWithImpPtr(id object,IMP* impPtr,id value, id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(setObject:forKey:)];
      (**impPtr)(object,@selector(setObject:forKey:),value,key);
    }
};

// ---- +alloc/+allocWithZone: ----
#define PSQLA_alloc(CLASS_NAME) \
	(*PSQLA_##CLASS_NAME##_allocWithZoneIMP) \
	(PSQLA_##CLASS_NAME##Class,@selector(allocWithZone:),NULL) 


#endif /* __PostgreSQLPrivate_h__ */

