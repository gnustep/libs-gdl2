/* 
   EOGenericRecord.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: June 2000

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef __EOGenericRecord_h__
#define __EOGenericRecord_h__

#import <Foundation/NSObject.h>


@class NSString;
@class NSMutableDictionary;

@class EOClassDescription;
@class EOEditingContext;
@class EOGlobalID;
@class EOMutableKnownKeyDictionary;


@interface EOGenericRecord : NSObject
{
  EOClassDescription *classDescription;
  EOMutableKnownKeyDictionary *dictionary;
}

// Initializing new instances

- initWithEditingContext: (EOEditingContext *)context
        classDescription: (EOClassDescription *)classDesc
                globalID: (EOGlobalID *)globalID;

#if !FOUNDATION_HAS_KVC
- (id)valueForKey: (NSString *)key;
- (void)takeValue: (id)value
           forKey: (NSString *)key;
#endif

+ (void)eoCalculateAllSizeWith: (NSMutableDictionary*)dict;
- (unsigned int)eoCalculateSizeWith: (NSMutableDictionary*)dict;
+ (unsigned int)eoCalculateSizeWith: (NSMutableDictionary *)dict
			   forArray: (NSArray *)array;

- (NSString *)debugDictionaryDescription;

@end /* EOGenericRecord */


#endif /* __EOGenericRecord_h__ */
