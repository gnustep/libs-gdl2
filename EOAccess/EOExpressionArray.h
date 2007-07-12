/* -*-objc-*-
   EOExpressionArray.h

   Copyright (C) 1996,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>
   Date: September 1996

   This file is part of the GNUstep Database Library.

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
*/

#ifndef __EOExpressionArray_h__
#define __EOExpressionArray_h__


#ifdef GNUSTEP
#include <Foundation/NSString.h>
#else
#include <Foundation/Foundation.h>
#endif

@class NSArray;

@class EOAttribute;
@class EOEntity;
@class EOSQLExpression;


@protocol EOExpressionContext <NSObject>

- (NSString *)expressionValueForAttribute: (EOAttribute *)attribute;
- (NSString *)expressionValueForAttributePath: (NSArray *)path;

@end


@interface EOExpressionArray : NSMutableArray
{
  NSString *_prefix;
  NSString *_infix;
  NSString *_suffix;
//    NSString *_definition; it's rebuilt
  EOAttribute *_realAttribute;
  void *_contents;

  struct
  {
    unsigned int isFlattened:1; //TODO Why ?
  } _flags;
}

+ (EOExpressionArray *)expressionArray;
+ (EOExpressionArray *)expressionArrayWithPrefix: (NSString *)prefix
                                          infix: (NSString *)infix
                                         suffix: (NSString *)suffix;

/* Initializing instances */
- (id)initWithPrefix: (NSString *)prefix
	       infix: (NSString *)infix
	      suffix: (NSString *)suffix;

- (NSString *)prefix;
- (NSString *)infix;
- (NSString *)suffix;

- (NSString *)definition;
- (BOOL)isFlattened;
- (EOAttribute *)realAttribute;

/* Accessing the components */
- (void)setPrefix: (NSString *)prefix;
- (void)setInfix: (NSString *)infix;
- (void)setSuffix: (NSString *)suffix;

/* Checking contents */
- (BOOL)referencesObject: (id)object;

- (NSString *)expressionValueForContext: (id<EOExpressionContext>)ctx;

/*+ (EOExpressionArray *)parseExpression: (NSString *)expression
                                entity: (EOEntity *)entity
				replacePropertyReferences: (BOOL)flag;*/

- (NSString *)valueForSQLExpression: (EOSQLExpression *)sqlExpression;

@end /* EOExpressionArray */


@interface NSObject (EOExpression)
- (NSString *)expressionValueForContext: (id<EOExpressionContext>)context;
@end


@interface NSString (EOAttributeTypeCheck)

- (BOOL)isNameOfARelationshipPath;

@end

#endif /* __EOExpressionArray_h__ */
