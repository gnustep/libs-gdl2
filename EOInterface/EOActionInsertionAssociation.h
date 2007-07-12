/** -*-ObjC-*-
   EOActionInsertionAssociation.h

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 3, 
   or (at your option) any later version.

   The GNUstep Database Library is distributed in the hope that it will be 
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License 
   along with the GNUstep Database Library; see the file COPYING. If not, 
   write to the Free Software Foundation, Inc., 
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
*/

#ifndef __EOInterface_EOActionInsertionAssociation_h__
#define __EOInterface_EOActionInsertionAssociation_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOInterface/EOAssociation.h>

@class NSString;
@class NSArray;

@interface EOActionInsertionAssociation : EOAssociation
{

}

/* Defining capabilities of concete class.  */
+ (NSArray *)aspects;
+ (NSArray *)aspectSignatures;

+ (NSArray *)objectKeysTaken;
+ (BOOL)isUsableWithObject: (id)object;

+ (NSString *)primaryAspect;

/* Creation and configuration.  */
- (void)establishConnection;
- (void)breakConnection;

/* Display object value manipulation.  */
- (void)subjectChanged;

- (void)action: (id)sender;

@end

#endif
