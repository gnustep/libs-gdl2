/** -*-ObjC-*-
   EOAssociation.h

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: David Ayers <d.ayers@inode.at>

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 2, 
   or (at your option) any later version.

   The GNUstep Database Library is distributed in the hope that it will be 
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License 
   along with the GNUstep Database Library; see the file COPYING. If not, 
   write to the Free Software Foundation, Inc., 
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 
*/

#ifndef __EOInterface_EOAssociation_h__
#define __EOInterface_EOAssociation_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#include <Foundation/NSMapTable.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EOObserver.h>

@class NSString;
@class NSArray;

@class EODisplayGroup;

@interface EOAssociation : EODelayedObserver <NSCoding>
{
  id _object;

  unsigned int _refs:8;
  unsigned int _isConnected:1;
  unsigned int _extras:7;
  unsigned int subclassFlags:16;

@private
  NSMapTable *_displayGroupMap;
  NSMapTable *_displayGroupKeyMap;
}

/* Defining capabilities of concete class.  */
+ (NSArray *)aspects;
+ (NSArray *)aspectSignatures;

+ (NSArray *)objectKeysTaken;
+ (BOOL)isUsableWithObject: (id)object;

+ (NSArray *)associationClassesSuperseded;

+ (NSString *)displayName;

+ (NSString *)primaryAspect;

+ (NSArray *)associationClassesForObject: (id)object;

/* Creation and configuration.  */
- (id)initWithObject: (id)object;
- (void)bindAspect: (NSString *)aspectName
      displayGroup: (EODisplayGroup *)displayGroup
	       key: (NSString *)key;
- (void)establishConnection;
- (void)breakConnection;

- (void)copyMatchingBindingsFromAssociation: (EOAssociation *)association;

/* Defining capabilities of concrete instance.  */
- (BOOL)canBindAspect: (NSString *)aspectName
	 displayGroup: (EODisplayGroup *)displayGroup
		  key: (NSString *)key;

/* Display object access.  */
- (id)object;

/* Bindings access.  */
- (EODisplayGroup *)displayGroupForAspect: (NSString *)aspectName;
- (NSString *)displayGroupKeyForAspect: (NSString *)aspectName;

/* Display object value manipulation.  */
- (void)subjectChanged;
- (BOOL)endEditing;

/* Enterprise object value manipulation.  */
- (id)valueForAspect: (NSString *)aspectName;
- (BOOL)setValue: (id)value forAspect: (NSString *)aspectName;

- (id)valueForAspect: (NSString *)aspectName 
	     atIndex: (unsigned int)index;
- (BOOL)setValue: (id)value
       forAspect: (NSString *)aspectName
	 atIndex: (unsigned int)index;

/* Handling of validation errors.  */
- (BOOL)shouldEndEditingForAspect: (NSString *)aspectName 
		     invalidInput: (NSString *)input
		 errorDescription: (NSString *)description;
- (BOOL)shouldEndEditingForAspect: (NSString *)aspectName
		     invalidInput: (NSString *)input
		 errorDescription: (NSString *)description
			    index: (unsigned int)index;


@end

#endif
