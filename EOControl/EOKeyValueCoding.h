/* -*-objc-*-
   EOKeyValueCoding.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   Modified: David Ayers <ayers@fsfe.org>
   Date: February 2003

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

#ifndef __EOKeyValueCoding_h__
#define __EOKeyValueCoding_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSKeyValueCoding.h>
#include <Foundation/NSDictionary.h>
#else
#include <Foundation/Foundation.h>
#endif

#include "EODefines.h"

/**
 * GDL2 aims to be compatible with EOF of WebObjects 4.5 and expects to be
 * compiled with gnustep-base or the current version Foundation of Mac OS X
 * together with gnustep-baseadd, the Additions subproject of gnustep-base.  
 * As many of the EOKeyValueCoding methods have moved to NSKeyValueCoding,
 * GDL2 merely implements those methods which are not part of NSKeyValueCoding
 * or reimplements those methods to insure WebObjects 4.5 compatibility or
 * augment the behavior for GDL2 specific features.
 */
@interface NSObject (EOKeyValueCoding)

/**
 * Unimplemented here.  Relies on NSKeyValueCoding.
 */
- (id)valueForKey: (NSString *)key;

/**
 * Overrides the implementation of gnustep-base/Foundation this method
 * is currently deprecated in favor of setValue:forKey: yet we aim
 * to maintain WebObjects 4.5 compatibility.
 */
- (void)takeValue: (id)value forKey: (NSString *)key;

/**
 * Unimplemented here.  Relies on NSKeyValueCoding.
 */
- (id)storedValueForKey: (NSString *)key;

/**
 * Unimplemented here.  Relies on NSKeyValueCoding.
 */
- (void)takeStoredValue: (id)value forKey: (NSString *)key;


/**
 * Unimplemented here.  Relies on NSKeyValueCoding.
 */
+ (BOOL)accessInstanceVariablesDirectly;

/**
 * Unimplemented here.  Relies on NSKeyValueCoding.
 */
+ (BOOL)useStoredAccessor;


/**
 * Does nothing.  Key bindings are currently not cached so there is no
 * need to flush them.  This method exists for API compatibility.
 */
+ (void)flushAllKeyBindings;


/**
 * Unimplemented here.  Relies on NSKeyValueCoding.
 */
- (id)handleQueryWithUnboundKey: (NSString *)key;

/**
 * Unimplemented here.  Relies on NSKeyValueCoding.
 */
- (void)handleTakeValue: (id)value forUnboundKey: (NSString *)key;

/**
 * This method is invoked by the EOKeyValueCoding mechanism when an attempt
 * is made to set an null value for a scalar attribute.
 * Contrary to the TOC of the documentation, this method is called
 * unableToSetNilForKey: and not unableToSetNullForKey:<br/>
 * This implementation raises an NSInvalidArgument exception. <br/>
 * The NSKeyValueCoding -setNilValueForKey: is overriden to invoke this
 * method instead.  We manipulate the runtime to insure that our implementation
 * of unableToSetNilForKey: is used in favor of the one in gnustep-base or
 * Foundation.
 */
- (void)unableToSetNilForKey: (NSString *)key;

@end

@interface NSObject (EOKeyValueCodingAdditions)

/**
 * Unimplemented here.  Relies on NSKeyValueCoding.
 */
- (id)valueForKeyPath: (NSString *)keyPath;

/**
 * Overrides the implementation of gnustep-base/Foundation this method
 * is currently deprecated in favor of setValue:forKeyPath: yet we aim
 * to maintain WebObjects 4.5 compatibility.
 */
- (void)takeValue: (id)value forKeyPath: (NSString *)keyPath;

/**
 * Unimplemented here.  Relies on NSKeyValueCoding.
 */
- (NSDictionary *)valuesForKeys: (NSArray *)keys;

/**
 * Overrides the implementation of gnustep-base/Foundation this method
 * is currently deprecated in favor of setValue:forKeyPath: yet we aim
 * to maintain WebObjects 4.5 compatibility.
 */
- (void)takeValuesFromDictionary: (NSDictionary *)dictionary; 

@end

@interface NSArray (EOKeyValueCoding)
- (id)valueForKey: (NSString *)key;
- (id)valueForKeyPath: (NSString *)keyPath;

- (id)computeSumForKey: (NSString *)key;
- (id)computeAvgForKey: (NSString *)key;
- (id)computeCountForKey: (NSString *)key;
- (id)computeMaxForKey: (NSString *)key;
- (id)computeMinForKey: (NSString *)key;
@end


@interface NSDictionary (EOKeyValueCoding)
/*
 * Overrides gnustep-base and Foundations implementation.
 * See documentation or source file for details on how it differs.
 */
- (id)valueForKey: (NSString *)key;
- (id)storedValueForKey: (NSString *)key;
- (id)valueForKeyPath: (NSString *)keyPath;
- (id)storedValueForKeyPath: (NSString *)keyPath;
@end


@interface NSMutableDictionary (EOKeyValueCoding)
/*
 * Overrides gnustep-base and Foundations implementation.
 * See documentation or source file for details on how it differs.
 */
- (void)takeValue: (id)value 
           forKey: (NSString *)key;
@end


@interface NSObject (EOKVCGDL2Additions)
/* These are hooks for EOGenericRecord KVC implementaion. */
- (void)smartTakeValue: (id)object 
                forKey: (NSString *)key;
- (void)smartTakeValue: (id)object 
            forKeyPath: (NSString *)keyPath;

- (void)takeStoredValue: (id)value 
             forKeyPath: (NSString *)key;
- (id)storedValueForKeyPath: (NSString *)key;

- (NSDictionary *)valuesForKeyPaths: (NSArray *)keyPaths;
- (NSDictionary *)storedValuesForKeyPaths: (NSArray *)keyPaths;
@end


#define EOUnknownKeyException NSUnknownKeyException;
GDL2CONTROL_EXPORT NSString *EOTargetObjectUserInfoKey;
GDL2CONTROL_EXPORT NSString *EOUnknownUserInfoKey;

/*
 * The following declaration is reportedly missing in Apple's headers,
 * yet are implemented.
 */
#ifndef GNUSTEP
@interface NSObject (MacOSX)
- (void)takeStoredValuesFromDictionary: (NSDictionary *)dictionary;
@end
#endif

#endif /* __EOKeyValueCoding_h__ */
