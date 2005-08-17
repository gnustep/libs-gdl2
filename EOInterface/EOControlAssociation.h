/** -*-ObjC-*-
   EOControlAssociation.h

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
*/

#ifndef __EOInterface_EOControlAssociation_h__
#define __EOInterface_EOControlAssociation_h__

#ifdef GNUSTEP
#include <AppKit/NSImage.h>
#else
#include <AppKit/AppKit.h>
#endif

#include <EOInterface/EOAssociation.h>

#include <EOInterface/EOAssociation.h>

@class NSString;
@class NSArray;

@class NSControl;
@class NSText;

@interface EOGenericControlAssociation : EOAssociation
{
  BOOL _didChange;
  id _lastValue;
}

/* Defining capabilities of concete class.  */
+ (NSArray *)aspects;
+ (NSArray *)aspectSignatures;

+ (NSArray *)objectKeysTaken;
+ (BOOL)isUsableWithObject: (id)object;

/* Creation and configuration.  */
- (void)establishConnection;
- (void)breakConnection;

/* Display object value manipulation.  */
- (void)subjectChanged;
- (BOOL)endEditing;

/* EOControlAssociation methods.  */
- (NSControl *)control;
- (EOGenericControlAssociation *)editingAssociation;

/* NSControl delegate methods.  */
- (BOOL)control: (NSControl *)control
didFailToFormatString: (NSString *)string
errorDescription: (NSString *)description;

- (BOOL)control: (NSControl *)control
  isValidObject: (id)object;

- (BOOL)control: (NSControl *)control
textShouldBeginEditing: (NSText *)fieldEditor;

@end

@interface EOControlAssociation : EOGenericControlAssociation
{

}

/* Defining capabilities of concete class.  */
+ (BOOL)isUsableWithObject: (id)object;

+ (NSString *)displayName;

/* Creation and configuration.  */
- (void)establishConnection;
- (void)breakConnection;

/* EOControlAssociation methods */
- (NSControl *)control;
- (EOGenericControlAssociation *)editingAssociation;

@end

@interface EOActionCellAssociation : EOGenericControlAssociation
{

}

/* Defining capabilities of concete class.  */
+ (BOOL)isUsableWithObject: (id)object;

+ (NSString *)displayName;

/* Creation and configuration.  */
- (void)establishConnection;
- (void)breakConnection;

/* EOActionCellAssociation methods */
- (NSControl *)control;
- (EOGenericControlAssociation *)editingAssociation;

@end

@interface NSImage (EOImageFactory)

+ (id)imageWithData:(NSData *)data;

@end

#endif

