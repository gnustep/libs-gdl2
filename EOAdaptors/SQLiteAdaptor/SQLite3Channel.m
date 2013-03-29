/* 
   SQLite3Channel.m

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author: Matt Rice <ratmice@gmail.com>
   Date: 2006

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

#include "SQLite3Channel.h"
#include "SQLite3Adaptor.h"
#include "SQLite3Context.h"
#include "SQLite3Expression.h"

#include <Foundation/Foundation.h>

#include <EOControl/EONull.h>

#include <EOAccess/EOAttribute.h>

#include <GNUstepBase/GNUstep.h>

#define EOAdaptorDebugLog(format, args...) \
  do { if ([self isDebugEnabled]) { NSLog(format , ## args); } } while (0)

@interface SQLite3Channel (Private)
-(void) _raise;
- (void) _raiseWith:(id)statement;
- (void)_describeBasicEntityWithName:(NSString *)tableName
                            forModel:(EOModel *)model;
- (void)_describeForeignKeysForEntity:(EOEntity *) entity
                             forModel:(EOModel *) model;
@end

@implementation SQLite3Channel

static id newNumberValue(const char *data, EOAttribute *attrib)
{
  id ret = nil;
  char t = '\0';
  Class valueClass = NSClassFromString([attrib valueClassName]);
  NSString *valueType = [attrib valueType];

  if ([valueType length])
    t = [valueType characterAtIndex:0];
  if (valueClass == [NSDecimalNumber class])
    {
      NSString *tmp = [[NSString alloc] initWithCString:data];
      return [[NSDecimalNumber alloc] initWithString:tmp];
    }
  switch (t)
  {
	  case 'i':
		ret = [[NSNumber alloc]  initWithInt:atoi(data)];
		break;
	  case 'I':
		ret = [[NSNumber alloc]  initWithUnsignedInt:(unsigned int)atoi(data)];
		break;
	  case 'c':
		ret = [[NSNumber alloc]  initWithChar:atoi(data)];
		break;
	  case 'C':
		ret = [[NSNumber alloc]  initWithUnsignedChar:(unsigned char)atoi(data)];
		break;
	  case 's':
		ret = [[NSNumber alloc]  initWithShort:(short)atoi(data)];
		break;
	  case 'S':
		ret = [[NSNumber alloc]  initWithUnsignedShort:(unsigned short)atoi(data)];
		break;
	  case 'l':
		ret = [[NSNumber alloc]  initWithLong:atol(data)];
		break;
	  case 'L':
		ret = [[NSNumber alloc]  initWithUnsignedLong:strtoul(data,NULL,10)];
		break;
	  case 'u':
		ret = [[NSNumber alloc]  initWithLongLong:atoll(data)];
		break;
	  case 'U':
		ret = [[NSNumber alloc]  initWithUnsignedLongLong:strtoul(data, NULL, 10)];
		break;
	  case 'f':
		ret = [[NSNumber alloc]  initWithFloat:(float)strtod(data, NULL)];
		break;
	  case 'd':
	  case '\0':
		ret = [[NSNumber alloc]  initWithDouble:strtod(data, NULL)];
		break;
  	default:
 	  [[NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Unknown attribute valueTypeChar: %c for attribute: %@", t, attrib] userInfo:nil] raise];
  }
  return ret; 
}

- (BOOL) isOpen
{
  return _sqlite3Conn != NULL;
}

- (void) openChannel
{
  NSString *filename;
  EOAdaptor *adaptor = [[self adaptorContext] adaptor];
  
  [adaptor assertConnectionDictionaryIsValid];
  filename = [[adaptor connectionDictionary] objectForKey:@"databasePath"];
  if (sqlite3_open([filename cString], &_sqlite3Conn) != SQLITE_OK)
    {
      _sqlite3Conn = NULL;
      [self _raise];
    }
}

- (void) closeChannel
{
  [self cancelFetch];
  NSAssert((sqlite3_close(_sqlite3Conn) == SQLITE_OK),
	   [NSString stringWithCString:sqlite3_errmsg(_sqlite3Conn)]);
  _sqlite3Conn = NULL;
}


- (BOOL) isFetchInProgress
{
  return _isFetchInProgress;
}

- (void) cancelFetch
{
  if (_isFetchInProgress && _currentStmt)
    {
      sqlite3_finalize(_currentStmt);
      _currentStmt = NULL;
    }
  _isFetchInProgress = NO;
}

- (NSArray *)attributesToFetch
{
  return _attributesToFetch;
}

- (void) setAttributesToFetch:(NSArray *)attributes
{
  ASSIGN(_attributesToFetch, attributes);
}

- (void) selectAttributes:(NSArray *)attributes
       fetchSpecification:(EOFetchSpecification *)fetchSpec
		     lock:(BOOL)flag
		   entity:(EOEntity *)entity
{
  EOSQLExpression *expr;
  
  NSAssert([self isOpen], @"Channel not open");
  NSAssert(!_isFetchInProgress, @"Fetch already in progress");
  
  ASSIGN(_attributesToFetch,attributes);
  expr = [SQLite3Expression selectStatementForAttributes:attributes
					lock:flag
	  			fetchSpecification:fetchSpec
					entity:entity];
  [self evaluateExpression:expr];
}

- (void) insertRow:(NSDictionary *)row forEntity:(EOEntity *)entity
{
  EOSQLExpression *expr;
  NSAssert([self isOpen], @"channel not open");
  NSAssert(!_isFetchInProgress, @"called while fetch is in progress");
  NSAssert(row && entity, @"row and entity arguments must not be nil");
  
  expr = [SQLite3Expression insertStatementForRow:row entity:entity]; 

  [self evaluateExpression:expr];
}

- (NSUInteger)deleteRowsDescribedByQualifier: (EOQualifier *)qualifier
                                    entity: (EOEntity *)entity
{
  EOSQLExpression *sqlexpr = nil;
  NSUInteger rows = 0;
  SQLite3Context *adaptorContext;

  NSAssert([self isOpen], @"channel is not open");
  NSAssert((qualifier || entity), @"qualifier and entity arguments are nil");
  NSAssert((![self isFetchInProgress]), @"fetch is in progress");
  
  adaptorContext = (SQLite3Context *)[self adaptorContext];

  sqlexpr = [[[adaptorContext adaptor] expressionClass]
              deleteStatementWithQualifier: qualifier
              entity: entity];

  [self evaluateExpression: sqlexpr];
	  
  rows = (NSUInteger)sqlite3_changes(_sqlite3Conn);
  return rows;
}

- (void) evaluateExpression:(EOSQLExpression *)sqlExpr
{
  
  NSString *statement = [sqlExpr statement];
  int length = [statement length];
  const char *sql = [statement cString];
  const char *pzTail = NULL;

  if ([_delegate respondsToSelector:@selector(adaptorChannel:shouldEvaluateExpression:)])
    if (![_delegate adaptorChannel:self shouldEvaluateExpression:sqlExpr])
      return;	
 
  if (![self isOpen]) return;

  if (_currentStmt)
    {
      NSAssert(!_currentStmt,
	       @"unfinalized statement found when executing expression");
      sqlite3_finalize(_currentStmt);
      _currentStmt = NULL;
    }
 
  while (sql != NULL && (_isFetchInProgress == NO))
    {
      _status = sqlite3_prepare(_sqlite3Conn, sql, length, &_currentStmt, &pzTail);
      if (_currentStmt == NULL)
        {
	  sql = NULL;
	}

      _isFetchInProgress = sqlite3_column_count(_currentStmt) != 0;
  
      if (_status != SQLITE_OK)
        {
          _status = sqlite3_finalize(_currentStmt);
          _currentStmt = NULL;
          [self _raiseWith:statement];
        }
      else 
        {
          while ((_status = sqlite3_step(_currentStmt)) == SQLITE_BUSY)
	    {
	      // FIXME sleep?
            }
        }
  
      if (_status != SQLITE_ROW)
        {
          sqlite3_finalize(_currentStmt);
          _currentStmt = NULL;
      
          if (_status == SQLITE_ERROR)
            [self _raiseWith:statement]; 
        }
      
      if (sql)
        sql = pzTail;
      pzTail = NULL;
    }
}

- (void) _raise
{
  [self _raiseWith:nil];
}

- (void) _raiseWith:(id)statement
{
  NSDictionary *userInfo = nil;
  
  if (statement)
    [NSDictionary dictionaryWithObject:statement forKey:@"statement"];
  
  [[NSException exceptionWithName:SQLite3AdaptorExceptionName
              reason:[NSString stringWithCString:sqlite3_errmsg(_sqlite3Conn)]
	    userInfo:userInfo] raise];
}

- (void)_describeBasicEntityWithName:(NSString *)tableName
                            forModel:(EOModel *)model
{
  EOEntity *entity;
  NSString *stmt;
  EOAttribute *attribute;
  NSString *valueClass = @"NSString";
  NSString *valueType = nil;
  unsigned int col, row;
  int count = 0;
  int nRows, nCols;
  char **results, *errMsg;
  NSMutableArray *columnNames;
  NSMutableArray *primaryKeyNames;
  
#warning may probably leak memory

  entity = AUTORELEASE([[EOEntity alloc] init]);
  [entity setName: tableName];
  [entity setExternalName: tableName];
  [entity setClassName: @"EOGenericRecord"];
  [model addEntity: entity];
  primaryKeyNames = AUTORELEASE([[NSMutableArray alloc] init]);

  stmt = [NSString stringWithFormat: @"PRAGMA table_info([%@])", tableName];

  EOAdaptorDebugLog(@"SQLite3Adaptor: execute command:\n%@", stmt);
  sqlite3_get_table(_sqlite3Conn,
		    [stmt cString],
		    &results,
		    &nRows,
		    &nCols,
		    &errMsg);

  if (nRows == 0)
    {   
      [NSException raise: SQLite3AdaptorExceptionName
                   format: @"Table %@ doesn't exist", tableName];
    }

  // get the column headers
  columnNames = AUTORELEASE([[NSMutableArray alloc] initWithCapacity:nCols]);
  for (col=0;col<nCols;col++)
    {
      [columnNames addObject:[NSString stringWithFormat:@"%s", results[col]]];
    }

  // enumerate each row describing a table, starting after the header
  // nRows doesn't include the header row 
  for (row=1;row<=nRows;row++)
    {
      NSString *columnName;
      NSString *externalType;
      BOOL allowsNull;
      for (col=0;col<nCols;col++)
	{ 
	  // count keeps track of the current field
	  count = row * nCols + col;
	  NSString *tmpHeader;
	  tmpHeader = [columnNames objectAtIndex:col];
	  attribute = [[EOAttribute alloc] init];
	  if ([tmpHeader isEqual:@"name"])
	    {
	      columnName = [NSString stringWithFormat:@"%s", results[count]];
	    }
	  else if ([tmpHeader isEqual:@"type"])
	    {
               NSRange range;
               range = [[NSString stringWithFormat:@"%s", results[count]] rangeOfString:@"("];
               if (range.location != NSNotFound)
                 {
                   externalType = [[NSString stringWithFormat:@"%s", results[count]] substringToIndex:range.location];
                 }
               else
                 {
                   externalType = [NSString stringWithFormat:@"%s", results[count]];
                 }
               valueClass = [SQLite3Adaptor internalTypeForExternalType: externalType model:nil];
               if (valueClass == nil)
                 {
                   valueClass = @"NSString";
                   // TODO: should also set the valueType here???
                 }
	    }
	  else if ([tmpHeader isEqual:@"notnull"])
	    {
             if ([[NSString stringWithFormat:@"%s", results[count]] isEqual:@"1"])
               allowsNull = NO;
             else
               allowsNull = YES;
	    }
	  else if ([tmpHeader isEqual:@"dflt_value"])
	    {
	      // do nothing yet
	    }
	  else if ([tmpHeader isEqual:@"pk"])
	    {
		if ([[NSString stringWithFormat:@"%s", results[count]] isEqual:@"1"])
		  {
		    [primaryKeyNames addObject:columnName];
		  }
	    }
	}
      [attribute setName: columnName];
      [attribute setColumnName: columnName];
      [attribute setAllowsNull: allowsNull];
      [attribute setExternalType: externalType];
      [attribute setValueType: valueType];
      [attribute setValueClassName: valueClass];
      [entity addAttribute: attribute];

      //RELEASE(externalType);
      RELEASE(attribute);
      //RELEASE(columnName);
    }

  if ([primaryKeyNames count] > 0)
    {
      NSEnumerator *keyEnum = [primaryKeyNames objectEnumerator];
      NSMutableArray *pkeys;
      NSString *pkeyName;
      pkeys = [[NSMutableArray alloc] init];
      while (pkeyName = [keyEnum nextObject])
        {
          attribute = [entity attributeNamed: pkeyName];
          [pkeys addObject: attribute];
        }
      [entity setPrimaryKeyAttributes: pkeys];
      RELEASE(pkeys);
    } 
}

- (void)_describeForeignKeysForEntity:(EOEntity *) entity
                             forModel:(EOModel *) model
{
#warning implement me: _describeForeignKeysForEntity: forModel:
}

- (NSMutableDictionary *) fetchRowWithZone:(NSZone *)zone
{
  if ([self isFetchInProgress])
    {  
      /* the docs say nothing about this but the postgres adaptor does it. */
      if (!_attributesToFetch)
        {
          _attributesToFetch = [self describeResults];
        } 
      
      if (_status == SQLITE_DONE)
        {
	  if ([_delegate respondsToSelector:@selector(adaptorChannelDidFinishFetching:)])
	    {
	      [_delegate adaptorChannelDidFinishFetching:self];
	    }
	  [self cancelFetch];
	  return nil;
        }
      else if (_status == SQLITE_ROW)
        {
          NSMutableDictionary *ret;
	  unsigned i, c = [_attributesToFetch count];
	  id *values;
	  
	  values = NSZoneMalloc(zone, c * sizeof(id));
	 
	  for (i = 0; i < c; i++)
	    {
	      EOAttribute *attr = [_attributesToFetch objectAtIndex:i];
	      
       	      switch ([attr adaptorValueType])
		{
		  case EOAdaptorNumberType:
			{
			  const char *text;
			  text = (const char*)sqlite3_column_text(_currentStmt, i);
			  if (text == NULL) text = "0";

			  values[i] = newNumberValue(text, attr);
			}
			break;
		     case EOAdaptorCharactersType:
			{
			  const unsigned char *text = sqlite3_column_text(_currentStmt, i);
			  int bytes = sqlite3_column_bytes(_currentStmt, i);
			  values[i] = bytes
				    ? [attr newValueForBytes:text
							length:bytes
				     encoding:[NSString defaultCStringEncoding]]
				    : [EONull null];
			}
			break;
		     case EOAdaptorDateType:
			 {
			   const char *text;
			   text = (const char *)sqlite3_column_text(_currentStmt, i);
			   if (text)
			     {
			       NSString *tmp = [[NSString alloc] initWithCString:text];
			       values[i] = [[NSCalendarDate alloc] initWithString:tmp];
			       RELEASE(tmp);
			     }
			   else values[i] = [EONull null];
			 }
			 break;
		      case EOAdaptorBytesType:
			 {
			   int bytes = sqlite3_column_bytes(_currentStmt, i);
			   const void *blob = sqlite3_column_blob(_currentStmt, i);
			   values[i] = blob ? [attr newValueForBytes:blob
				 		length:bytes]
					  : [EONull null];
			 }
			 break;
		     default:
			[[NSException exceptionWithName:SQLite3AdaptorExceptionName reason:@"unsupported adaptor value type" userInfo:nil] raise];
			break;
		}
	    }
			  
          ret = [self dictionaryWithObjects:values
		  	      forAttributes:_attributesToFetch zone:zone];
	  NSZoneFree(zone, values);
	  if ([_delegate respondsToSelector:@selector(adaptorChannel:didFetchRow:)])
	    [_delegate adaptorChannel:self didFetchRow:ret];

	   
	    while ((_status = sqlite3_step(_currentStmt)) == SQLITE_BUSY)
	      {
		// FIXME sleep?		   
	      }

	  if (_status != SQLITE_ROW)
	    {
	      sqlite3_finalize(_currentStmt);
	      _currentStmt = NULL;
	    }
	  return ret;
	}
    }
   return nil;
}

- (NSDictionary *) primaryKeyForNewRowWithEntity:(EOEntity *)ent
{
  NSMutableDictionary *ret = [NSMutableDictionary dictionary];
  NSArray *pk = [ent primaryKeyAttributes];
  int i;
  int nRows;
  int nCols;
  char **results;
  
  // FIXME should probably stop using sqlite3_get_table..
  for (i = 0; i < [pk count]; i++)
    {
      NSString *tableName = [ent externalName];
      NSString *keyName = [[pk objectAtIndex:i] name];
      NSString *stmt = [NSString stringWithFormat:@"select key from SQLiteEOAdaptorKeySequences where tableName = '%@' AND attributeName = '%@'", tableName, keyName];
      id pkVal;
      char *errMsg;
      
      sqlite3_get_table(_sqlite3Conn,
                        [stmt cString],
                        &results,
                        &nRows,
                        &nCols,
                        &errMsg);
      if (nRows > 0)
        {
	  pkVal = [NSNumber numberWithInt:atoi(results[1]) + 1];
          stmt = [NSString stringWithFormat:@"UPDATE " \
		 	@"SQLiteEOAdaptorKeySequences " \
			@"SET key = %i "
			@"WHERE tableName = '%@' AND attributeName = '%@'",
	       		[pkVal intValue], tableName, keyName];
        }
      else
	{
	  pkVal = [NSNumber numberWithInt:1];
          stmt = [NSString stringWithFormat:@"INSERT into " \
	  		@"SQLiteEOAdaptorKeySequences " \
			@"(key, tableName, attributeName) " \
			@"VALUES(%i, '%@', '%@')",
	       		[pkVal intValue], tableName, keyName];
	}
      
      sqlite3_get_table(_sqlite3Conn,
		        [stmt cString],
		      	&results,
			&nRows,
			&nCols,
			&errMsg);
      
      [ret setObject: pkVal
	      forKey:keyName];
    }
  return AUTORELEASE([ret copy]);
}

- (NSUInteger) updateValues:(NSDictionary *)values
inRowsDescribedByQualifier:(EOQualifier *)qualifier
entity:(EOEntity *)ent
{
  EOAdaptorContext *ctxt;
  EOSQLExpression *expr;
  
  NSAssert([self isOpen], @"channel is not open");
  NSAssert(!_isFetchInProgress, @"called while fetch in progress");

  ctxt = [self adaptorContext];


  expr = [SQLite3Expression updateStatementForRow:values 
	  			qualifier:qualifier
				   entity:ent];
  [self evaluateExpression:expr];
  return (NSUInteger)sqlite3_changes(_sqlite3Conn);
}

- (EOModel *)describeModelWithTableNames: (NSArray *)tableNames
{
  EOModel   *model=nil;
  EOAdaptor *adaptor=nil;
  EOEntity  *entity=nil;
  NSArray   *entityNames=nil;
  NSUInteger i=0;
  NSUInteger tableNamesCount=[tableNames count];
  NSUInteger entityNamesCount=0;

  adaptor = [[self adaptorContext] adaptor];
  model = AUTORELEASE([[EOModel alloc] init]);

  [model setAdaptorName: [adaptor name]];
  [model setConnectionDictionary: [adaptor connectionDictionary]];

  for (i = 0; i < tableNamesCount; i++)
    {
      NSAutoreleasePool *pool = [NSAutoreleasePool new];
      NSString *name;

      NS_DURING
        name = [tableNames objectAtIndex: i];
        [self _describeBasicEntityWithName: name forModel: model];
      NS_HANDLER
        {
          RETAIN(localException);
          [pool release];
          [AUTORELEASE(localException) raise];
        }
      NS_ENDHANDLER

      [pool release];
    }

  /* <foreign key stuff> */
  entityNames = [model entityNames];
  entityNamesCount=[entityNames count];
  for (i = 0; i < entityNamesCount; i++)
    {
      NSAutoreleasePool *pool = [NSAutoreleasePool new];
      NSString *entityName;

      NS_DURING
        entityName = [entityNames objectAtIndex:i];
        entity = [model entityNamed: entityName];
        [self _describeForeignKeysForEntity: entity forModel: model];
      NS_HANDLER
        {
          RETAIN(localException);
          [pool release];
          [AUTORELEASE(localException) raise];
        }
      NS_ENDHANDLER

      [pool release];
    }

  for (i=0; i < entityNamesCount; i++)
    {
      NSAutoreleasePool *pool = [NSAutoreleasePool new];
      NSMutableArray *classProperties;

      entity = [model entityNamed:[entityNames objectAtIndex:i]];
      classProperties = [NSMutableArray arrayWithArray:[entity attributes]];
      [classProperties removeObjectsInArray: [entity primaryKeyAttributes]];
      [entity setClassProperties: classProperties];

      [pool release];
    }

  [model beautifyNames];
  return model;
}

- (NSArray *) describeTableNames
{
  NSString *stmt = @"select name from sqlite_master where type='table'";
  EOSQLExpression *expr = [SQLite3Expression expressionForString:stmt];
  EOAttribute *attrib = [[[EOAttribute alloc] init] autorelease];
  NSDictionary *val;
  NSMutableArray *arr = [[NSMutableArray alloc] init];

  [attrib setName:@"tableName"];
  [attrib setColumnName:@"name"];
  [attrib setExternalType:@"TEXT"];
  [attrib setValueClassName:@"NSString"];
  
   
  
  [self evaluateExpression:expr];
  [self setAttributesToFetch:[NSArray arrayWithObject:attrib]];
  while ((val = [self fetchRowWithZone:NULL]))
    {
      NSString *name = [val objectForKey:@"tableName"];
      if (!([name isEqual:@"SQLiteEOAdaptorKeySequences"]
          || [name isEqualToString:@"sqlite_sequence"]))
        [arr addObject:name];
      RELEASE(name);
    }
  return AUTORELEASE([AUTORELEASE(arr) copy]);
}


- (NSArray *)describeResults
{
  // FIXME
  return [NSArray array];
}
@end
