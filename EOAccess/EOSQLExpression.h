/* 
   EOSQLExpression.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef __EOSQLExpression_h__
#define __EOSQLExpression_h__

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

#import <EOAccess/EOJoin.h>
#import <EOAccess/EORelationship.h>


@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;

@class EOAttribute;
@class EOEntity;
@class EOQualifier;
@class EOKeyValueQualifier;
@class EOKeyComparisonQualifier;
@class EOSortOrdering;
@class EOFetchSpecification;


extern NSString *EOBindVariableNameKey;
extern NSString *EOBindVariableAttributeKey;
extern NSString *EOBindVariableValueKey;
extern NSString *EOBindVariablePlaceHolderKey;
extern NSString *EOBindVariableColumnKey;


@interface EOSQLExpression : NSObject
{
  NSMutableDictionary *_aliasesByRelationshipPath;
  EOEntity *_entity;
  NSMutableString *_listString;
  NSMutableString *_valueListString;
  NSString *_whereClauseString;
  NSMutableString *_joinClauseString;
  NSMutableString *_orderByString;
  NSMutableArray *_bindings;
  NSMutableArray *_contextStack;
  NSString *_statement;
  BOOL _useAliases;
@private
  int _alias;
}

+ (EOSQLExpression *)expressionForString: (NSString *)string;

+ (EOSQLExpression *)insertStatementForRow: (NSDictionary *)row
				    entity: (EOEntity *)entity;

+ (EOSQLExpression *)updateStatementForRow: (NSDictionary *)row
				 qualifier: (EOQualifier *)qualifier
				    entity: (EOEntity *)entity;

+ (EOSQLExpression *)deleteStatementWithQualifier: (EOQualifier *)qualifier
					   entity: entity;

+ (EOSQLExpression *)selectStatementForAttributes: (NSArray *)attributes
					     lock: (BOOL)yn
			       fetchSpecification: (EOFetchSpecification *)fetchSpecification
					   entity: (EOEntity *)entity;

+ (id)sqlExpressionWithEntity: (EOEntity *)entity;

- initWithEntity: (EOEntity *)entity;

- (NSMutableDictionary *)aliasesByRelationshipPath;
- (EOEntity *)entity;

- (NSMutableString *)listString;
- (NSMutableString *)valueList;
- (NSMutableString *)joinClauseString;
- (NSMutableString *)orderByString;
- (NSString *)whereClauseString;
- (NSString *)statement;
- (void)setStatement:(NSString *)statement;
- (NSString *)lockClause;

- (NSString *)tableListWithRootEntity: (EOEntity *)entity;


- (void)prepareInsertExpressionWithRow: (NSDictionary *)row;
	
- (void)prepareUpdateExpressionWithRow: (NSDictionary *)row
			     qualifier: (EOQualifier *)qualifier;

- (void)prepareDeleteExpressionForQualifier: (EOQualifier *)qualifier;

- (void)prepareSelectExpressionWithAttributes: (NSArray *)attributes
					 lock: (BOOL)yn
			   fetchSpecification: (EOFetchSpecification *)fetchSpecification;

- (NSString *)assembleJoinClauseWithLeftName: (NSString *)leftName
				   rightName: (NSString *)rightName
				joinSemantic: (EOJoinSemantic)semantic;

- (void)addJoinClauseWithLeftName: (NSString *)leftName
			rightName: (NSString *)rightName
		     joinSemantic: (EOJoinSemantic)semantic;

- (void)joinExpression;

- (NSString *)assembleInsertStatementWithRow: (NSDictionary *)row
				   tableList: (NSString *)tableList
				  columnList: (NSString *)columnList
				   valueList: (NSString *)valueList;

- (NSString *)assembleUpdateStatementWithRow: (NSDictionary *)row
				   qualifier: (EOQualifier *)qualifier
				   tableList: (NSString *)tableList
				  updateList: (NSString *)updateList
				 whereClause: (NSString *)whereClause;

- (NSString *)assembleDeleteStatementWithQualifier: (EOQualifier *)qualifier
					 tableList: (NSString *)tableList
				       whereClause: (NSString *)whereClause;

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

- (void)addSelectListAttribute: (EOAttribute *)attribute;

- (void)addInsertListAttribute: (EOAttribute *)attribute
			 value: (NSString *)value;

- (void)addUpdateListAttribute: (EOAttribute *)attribute
			 value: (NSString *)value;

+ (NSString *)formatStringValue: (NSString *)string;

+ (NSString *)formatValue: (id)value forAttribute: (EOAttribute *)attribute;

+ (NSString *)formatSQLString: (NSString *)sqlString
		       format: (NSString *)format;

- (NSString *)sqlStringForConjoinedQualifiers: (NSArray *)qualifiers;
- (NSString *)sqlStringForDisjoinedQualifiers: (NSArray *)qualifiers;
- (NSString *)sqlStringForNegatedQualifier: (EOQualifier *)qualifier;
- (NSString *)sqlStringForKeyValueQualifier: (EOKeyValueQualifier *)qualifier;
- (NSString *)sqlStringForKeyComparisonQualifier: (EOKeyComparisonQualifier *)qualifier;
- (NSString *)sqlStringForValue: (NSString *)valueString
	 caseInsensitiveLikeKey: (NSString *)keyString;

- (void)addOrderByAttributeOrdering: (EOSortOrdering *)sortOrdering;

+ (BOOL)useQuotedExternalNames;
+ (void)setUseQuotedExternalNames: (BOOL)yn;
- (NSString *)externalNameQuoteCharacter;

- (void)setUseAliases: (BOOL)useAliases;
- (BOOL)useAliases;

- (NSString *)sqlStringForSchemaObjectName: (NSString *)name;

- (NSString *)sqlStringForAttributeNamed: (NSString *)name;

- (NSString *)sqlStringForSelector: (SEL)selector value: (id)value;

- (NSString *)sqlStringForValue: (id)value attributeNamed: (NSString *)string;

- (NSString *)sqlStringForAttribute: (EOAttribute *)anAttribute;

- (NSString *)sqlStringForAttributePath: (NSArray *)path;

- (void)appendItem: (NSString *)itemString
      toListString: (NSMutableString *)listString;

+ (NSString *)sqlPatternFromShellPattern: (NSString *)pattern;
+ (NSString *)sqlPatternFromShellPattern: (NSString *)pattern
		     withEscapeCharacter: (unichar)escapeCharacter;


- (NSMutableDictionary *)bindVariableDictionaryForAttribute: (EOAttribute *)attribute
						      value: value;

- (BOOL)shouldUseBindVariableForAttribute: (EOAttribute *)att;

- (BOOL)mustUseBindVariableForAttribute: (EOAttribute *)att;

+ (BOOL)useBindVariables;
+ (void)setUseBindVariables: (BOOL)yn;

- (NSArray *)bindVariableDictionaries;

- (void)addBindVariableDictionary: (NSMutableDictionary *)binding;

@end

@interface NSString (EOSQLFormatting)

- (NSString *)sqlString;

@end

@interface NSNumber (EOSQLFormatting)

- (NSString *)sqlString;

@end

#endif /* __EOSQLExpression_h__ */
