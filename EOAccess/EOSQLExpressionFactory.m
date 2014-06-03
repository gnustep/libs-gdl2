/* EOSQLExpressionFactory.m

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

#include "config.h"

#include <string.h>

#ifdef GNUSTEP
#include <Foundation/NSDebug.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#include <GNUstepBase/NSObject+GNUstepBase.h>
#endif

#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOSQLExpression.h>

#include <EOAccess/EOSQLExpressionFactory.h>
/*
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOSortOrdering.h>
#include <EOControl/EODebug.h>
#include <EOControl/EONull.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOEntityPriv.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOAdaptorContext.h>
#include <EOAccess/EOAdaptorChannel.h>
#include <EOAccess/EOJoin.h>
#include <EOAccess/EOSQLExpression.h>
#include <EOAccess/EOSQLQualifier.h>
#include <EOAccess/EOExpressionArray.h>

#include "EOPrivate.h"
#include "EOEntityPriv.h"
#include "EOAttributePriv.h"
#include "EOSQLExpressionPriv.h"
*/

@implementation EOSQLExpressionFactory

+(EOSQLExpressionFactory*)sqlExpressionFactoryWithAdaptor:(EOAdaptor*)adaptor
{
  return AUTORELEASE([[self alloc]initWithAdaptor:adaptor]);
}

-(id)initWithAdaptor:(EOAdaptor*)adaptor
{
  if ((self=[self init]))
    {
      ASSIGN(_adaptor,adaptor);
      ASSIGN(_expressionClass,[adaptor expressionClass]);
    }
  return self;
}

-(void)dealloc
{
  DESTROY(_adaptor);
  DESTROY(_expressionClass);
  [super dealloc];
}

-(EOAdaptor*)adaptor
{
  return _adaptor;
}

-(Class)expressionClass;
{
  return _expressionClass;
}

-(EOSQLExpression*)createExpressionWithEntity:(EOEntity*)entity
{
  return [_expressionClass sqlExpressionWithEntity:entity];
}

-(EOSQLExpression*)expressionForString:(NSString*)string
{
  EOSQLExpression* sqlExpression = [self createExpressionWithEntity:nil];
  [sqlExpression setStatement:string];
  return sqlExpression;
}

    -(EOSQLExpression*)expressionForEntity:(EOEntity*)entity
{
  return [self createExpressionWithEntity:nil];
 }

-(EOSQLExpression*)insertStatementForRow:(NSDictionary*)row
			      withEntity:(EOEntity*)entity
{
  EOSQLExpression* sqlExpression = nil;
  if (entity == nil)
    {
      [NSException raise: @"NSIllegalArgumentException"
		   format:@"%s entity must not be nil",
		   __PRETTY_FUNCTION__];
    }
  else
    {
      sqlExpression = [self createExpressionWithEntity:entity];
      [sqlExpression setUseAliases:NO];
      [sqlExpression prepareInsertExpressionWithRow:row];
    }
  return sqlExpression;
}

-(EOSQLExpression*) updateStatementForRow:(NSDictionary*)row
				qualifier:(EOQualifier*)qualifier
			       withEntity:(EOEntity*)entity
{
  EOSQLExpression* sqlExpression = nil;
  if ([row count] == 0)
    {
      [NSException raise: @"NSIllegalArgumentException"
		   format:@"%s nothing to update",
		   __PRETTY_FUNCTION__];
    }
  else if (entity == nil)
    {
      [NSException raise: @"NSIllegalArgumentException"
		   format:@"%s entity must not be nil",
		   __PRETTY_FUNCTION__];
    }
  else if(qualifier == nil)
    {
      [NSException raise: @"NSIllegalArgumentException"
		   format:@"%s qualifier must not be nil",
		   __PRETTY_FUNCTION__];
    }
  else
    {
      sqlExpression = [self createExpressionWithEntity:entity];
      [sqlExpression setUseAliases:NO];
      [sqlExpression prepareUpdateExpressionWithRow:row
		     qualifier:qualifier];
    }
  return sqlExpression;
}

-(EOSQLExpression*)deleteStatementWithQualifier:(EOQualifier*)qualifier
					 entity:(EOEntity*)entity
{
  EOSQLExpression* sqlExpression = [self createExpressionWithEntity:entity];
  [sqlExpression setUseAliases:NO];
  [sqlExpression prepareDeleteExpressionForQualifier:qualifier];
  return sqlExpression;
}

-(EOSQLExpression*)selectStatementForAttributes:(NSArray*)attributes
					   lock:(BOOL)lock
			     fetchSpecification:(EOFetchSpecification*)fetchSpec
					 entity:(EOEntity*)entity
{
  EOSQLExpression* sqlExpression = nil;
  if ([attributes count] == 0)
    {
      [NSException raise: @"NSIllegalArgumentException"
		   format:@"%s nothing to select",
		   __PRETTY_FUNCTION__];
    }
  else if (fetchSpec == nil)
    {
      [NSException raise: @"NSIllegalArgumentException"
		   format:@"%s fetchSpecification must not be nil",
		   __PRETTY_FUNCTION__];
    }
  else if(entity == nil)
    {
      [NSException raise: @"NSIllegalArgumentException"
		   format:@"%s entity must not be nil",
		   __PRETTY_FUNCTION__];
    }
  else
    {
      sqlExpression = [self createExpressionWithEntity:entity];
      [sqlExpression setUseAliases:YES];
      [sqlExpression prepareSelectExpressionWithAttributes: attributes
					 lock: lock
			   fetchSpecification: fetchSpec];
    }
  return sqlExpression;
}

@end
