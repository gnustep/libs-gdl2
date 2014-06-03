/* -*-objc-*-
   EOSQLExpressionFactory.h

   Copyright (C) 2014 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: Jun 2014

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

#ifndef __EOSQLExpressionFactory_h__
#define __EOSQLExpressionFactory_h__

@interface EOSQLExpressionFactory: NSObject
{
    EOAdaptor* _adaptor;
    Class _expressionClass;

}
+(EOSQLExpressionFactory*)sqlExpressionFactoryWithAdaptor:(EOAdaptor*)adaptor;
-(id)initWithAdaptor:(EOAdaptor*)adaptor;

-(EOAdaptor*)adaptor;
-(Class)expressionClass;

-(EOSQLExpression*)createExpressionWithEntity:(EOEntity*)entity;
-(EOSQLExpression*)expressionForString:(NSString*)string;
-(EOSQLExpression*)expressionForEntity:(EOEntity*)entity;

-(EOSQLExpression*)insertStatementForRow:(NSDictionary*)row
				withEntity:(EOEntity*)entity;

-(EOSQLExpression*) updateStatementForRow:(NSDictionary*)row
				qualifier:(EOQualifier*)qualifier
			       withEntity:(EOEntity*)entity;

-(EOSQLExpression*)deleteStatementWithQualifier:(EOQualifier*)qualifier
					 entity:(EOEntity*)entity;

-(EOSQLExpression*)selectStatementForAttributes:(NSArray*)attributes
					   lock:(BOOL)lock
			     fetchSpecification:(EOFetchSpecification*)fetchSpec
					 entity:(EOEntity*)entity;
@end

#endif // __EOSQLExpressionFactory_h__
