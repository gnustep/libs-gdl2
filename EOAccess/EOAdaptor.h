/* -*-objc-*-
   EOAdaptor.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

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

#ifndef __EOAdaptor_h__
#define __EOAdaptor_h__

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOAccess/EODefines.h>


@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSNumber;
@class NSException;
@class NSCalendarDate;
@class NSData;
@class NSTimeZone;

@class EOModel;
@class EOAttribute;
@class EOAdaptorContext;
@class EOLoginPanel;
@class EOEntity;

GDL2ACCESS_EXPORT NSString *EOGeneralAdaptorException;


@interface EOAdaptor : NSObject
{
  EOModel *_model;//Not in EOFD

  NSString *_name;
  NSDictionary *_connectionDictionary;
  NSMutableArray *_contexts;	// values with contexts
  // Strictly speaking, the _context array is not API compatible
  // with WO4.5 as the objects in the array are GC-wrappers.
  // Subclasses should access this array via accessor method.

  NSString *_expressionClassName;
  Class _expressionClass;
  id _delegate;	// not retained
  
  struct {
    unsigned processValue:1;
  } _delegateRespondsTo;
}

/* Creating an EOAdaptor */
+ (id)adaptorWithModel: (EOModel *)model;
+ (id)adaptorWithName: (NSString *)name;

+ (void)setExpressionClassName: (NSString *)sqlExpressionClassName
              adaptorClassName: (NSString *)adaptorClassName;
+ (EOLoginPanel *)sharedLoginPanelInstance;

+ (NSArray *)availableAdaptorNames;
- (NSArray *)prototypeAttributes;

- (id)initWithName: (NSString *)name;

/* Getting an adaptor's name */
- (NSString *)name;

/* Creating and removing an adaptor context */
- (EOAdaptorContext *)createAdaptorContext;
- (NSArray *)contexts;

/* Setting the model */
- (void)setModel: (EOModel *)model;//Not in EOFD
- (EOModel *)model;//Not in EOFD

/* Checking connection status */
- (BOOL)hasOpenChannels;

/* Getting adaptor-specific information */
- (Class)expressionClass;
- (Class)defaultExpressionClass;

/* Reconnection to database */
- (void)handleDroppedConnection;
- (BOOL)isDroppedConnectionException: (NSException *)exception;

/* Setting connection information */
- (void)setConnectionDictionary: (NSDictionary *)dictionary;
- (NSDictionary *)connectionDictionary;
- (void)assertConnectionDictionaryIsValid;

- (BOOL)canServiceModel: (EOModel *)model;

- (NSStringEncoding)databaseEncoding;

- (id)fetchedValueForValue: (id)value
                 attribute: (EOAttribute *)attribute;
- (NSString *)fetchedValueForStringValue: (NSString *)value
			       attribute: (EOAttribute *)attribute;
- (NSNumber *)fetchedValueForNumberValue: (NSNumber *)value
                               attribute: (EOAttribute *)attribute;
- (NSCalendarDate *)fetchedValueForDateValue: (NSCalendarDate *)value
                                   attribute: (EOAttribute *)attribute;
- (NSData *)fetchedValueForDataValue: (NSData *)value
                           attribute: (EOAttribute *)attribute;

/* Setting the delegate */
- (id)delegate;
- (void)setDelegate: (id)delegate;

- (BOOL)isValidQualifierType: (NSString *)attribute
		       model: (EOModel *)model;

@end /* EOAdaptor */


@interface EOAdaptor (EOAdaptorLoginPanel)

- (BOOL)runLoginPanelAndValidateConnectionDictionary;
- (NSDictionary *)runLoginPanel;

@end


@interface EOAdaptor (EOExternalTypeMapping)

+ (NSString *)internalTypeForExternalType: (NSString *)extType
                                    model: (EOModel *)model;
+ (NSArray *)externalTypesWithModel: (EOModel *)model;
+ (void)assignExternalTypeForAttribute: (EOAttribute *)attribute;
+ (void)assignExternalInfoForAttribute: (EOAttribute *)attribute;
+ (void)assignExternalInfoForEntity: (EOEntity *)entity;
+ (void)assignExternalInfoForEntireModel: (EOModel *)model;

@end


@interface EOAdaptor (EOSchemaGenerationExtensions)

- (void)dropDatabaseWithAdministrativeConnectionDictionary: (NSDictionary *)administrativeConnectionDictionary;
- (void)createDatabaseWithAdministrativeConnectionDictionary: (NSDictionary *)administrativeConnectionDictionary;

@end


@interface EOLoginPanel : NSObject

- (NSDictionary *)runPanelForAdaptor: (EOAdaptor *)adaptor
                            validate: (BOOL)yn 
                      allowsCreation: (BOOL)allowsCreation;
- (NSDictionary *)administrativeConnectionDictionaryForAdaptor: (EOAdaptor *)adaptor;

@end


@interface NSObject (EOAdaptorDelegate)

- (id)adaptor: (EOAdaptor *)adaptor
fetchedValueForValue: (id)value
    attribute: (EOAttribute *)attribute;
- (NSDictionary *)reconnectionDictionaryForAdaptor: (EOAdaptor *)adaptor;

@end /* NSObject (EOAdaptorDelegate) */

/* GDL2 Extensions */
GDL2ACCESS_EXPORT NSString *EOAdministrativeConnectionDictionaryNeededNotification;
GDL2ACCESS_EXPORT NSString *EOAdaptorKey;
GDL2ACCESS_EXPORT NSString *EOModelKey;
GDL2ACCESS_EXPORT NSString *EOConnectionDictionaryKey;
GDL2ACCESS_EXPORT NSString *EOAdministrativeConnectionDictionaryKey;


#endif /* __EOAdaptor_h__*/
