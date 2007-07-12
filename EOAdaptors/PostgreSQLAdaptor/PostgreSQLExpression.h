/* 
   PostgreSQLExpression.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

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

#ifndef __PostgreSQLExpression_h__
#define __PostgreSQLExpression_h__

#include <EOAccess/EOSQLExpression.h>


@class NSString;


@interface PostgreSQLExpression : EOSQLExpression

+ (NSString *)formatValue: (id)value
             forAttribute: (EOAttribute *)attribute;
- (NSString *)lockClause;
- (NSString *)assembleSelectStatementWithAttributes: (NSArray *)attributes
                                               lock: (BOOL)lock
                                          qualifier: (EOQualifier *)qualifier
                                         fetchOrder: (NSArray *)fetchOrder
                                       selectString: (NSString *)selectString
                                         columnList: (NSString *)columnList
                                          tableList: (NSString *)tableList
                                        whereClause: (NSString *)whereClause
                                         joinClause: (NSString *)joinClause
                                      orderByClause: (NSString *)orderByClause
                                         lockClause: (NSString *)lockClause;

@end


#endif /* __PostgreSQLExpression_h__ */
