/**
   EOAttribute.m <title>EOAttribute Class</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
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
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#include <ctype.h>
#include <string.h>

#ifdef GNUSTEP
#include <Foundation/NSUtilities.h>
#include <Foundation/NSArchiver.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSException.h>
#include <Foundation/NSTimeZone.h>
#include <Foundation/NSData.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSDecimalNumber.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSCalendarDate.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EONull.h>
#include <EOControl/EOObserver.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOStoredProcedure.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOExpressionArray.h>

#include <string.h>

#include "EOPrivate.h"
#include "EOEntityPriv.h"
#include "EOAttributePriv.h"


@implementation EOAttribute

+ (void)initialize
{
  static BOOL initialized=NO; 
  if (!initialized)
    {
      initialized=YES;

      GDL2_EOAccessPrivateInit();
    }
}

+ (id) attributeWithPropertyList: (NSDictionary *)propertyList
                           owner: (id)owner
{
  return [[[self alloc] initWithPropertyList: propertyList
			owner: owner] autorelease];
}

- (id) initWithPropertyList: (NSDictionary *)propertyList
                      owner: (id)owner
{
  if ((self = [self init]))
    {
      NSString *tmpString = nil;
      id tmpObject = nil;

      [self setName: [propertyList objectForKey: @"name"]];

      EOFLOGObjectLevelArgs(@"gsdb", @"Attribute parent=%p %@",
		   owner, [(EOEntity *)owner name]);

      [self setParent: owner];
//      EOFLOGObjectLevel(@"gsdb", @"Attribute Entity=%@", [self entity]);

      [self setExternalType: [propertyList objectForKey: @"externalType"]];

      tmpString = [propertyList objectForKey: @"allowsNull"];
      if (tmpString)
        [self setAllowsNull: [tmpString isEqual: @"Y"]];

      [self setValueType: [propertyList objectForKey: @"valueType"]];
      [self setValueClassName: [propertyList objectForKey: @"valueClassName"]];

      tmpString = [propertyList objectForKey: @"writeFormat"];
      if (tmpString)
        [self setWriteFormat: tmpString];
      else
        {
          tmpString = [propertyList objectForKey: @"updateFormat"];
          if (tmpString)
            [self setWriteFormat: tmpString];
          else
            {
              tmpString = [propertyList objectForKey: @"insertFormat"];
              if (tmpString)
                [self setWriteFormat: tmpString];
            }
        }

      tmpString = [propertyList objectForKey: @"readFormat"];
      if (tmpString)
        [self setReadFormat: tmpString];
      else
        {
          tmpString = [propertyList objectForKey: @"selectFormat"];
          [self setReadFormat: tmpString];
        }

      /*
        tmpString = [propertyList objectForKey: @"maximumLength"];
        if (tmpString)
        [self setMaximumLength: [tmpString intValue]];
      */

      tmpString = [propertyList objectForKey: @"width"];
      if (tmpString) 
        [self setWidth: [tmpString intValue]];

      tmpString = [propertyList objectForKey: @"valueFactoryMethodName"];
      if (tmpString)
        [self setValueFactoryMethodName: tmpString];

      tmpString = [propertyList objectForKey: @"adaptorValueConversionMethodName"];
      if (tmpString)
        [self setAdaptorValueConversionMethodName: tmpString];

      tmpString = [propertyList objectForKey: @"factoryMethodArgumentType"];
      if(tmpString)
        {
          EOFactoryMethodArgumentType argType = EOFactoryMethodArgumentIsBytes;

          if ([tmpString isEqual: @"EOFactoryMethodArgumentIsNSData"])
            argType = EOFactoryMethodArgumentIsNSData;
          else if ([tmpString isEqual: @"EOFactoryMethodArgumentIsNSString"])
            argType = EOFactoryMethodArgumentIsNSString;

          [self setFactoryMethodArgumentType: argType];
        }

      tmpString = [propertyList objectForKey: @"precision"];
      if (tmpString)
        [self setPrecision: [tmpString intValue]];

      tmpString = [propertyList objectForKey: @"scale"];
      if (tmpString)
        [self setScale: [tmpString intValue]];

      tmpString = [propertyList objectForKey: @"serverTimeZone"];
      if (tmpString)
        [self setServerTimeZone: [NSTimeZone timeZoneWithName: tmpString]];

      tmpString = [propertyList objectForKey: @"parameterDirection"];
      if (tmpString)
        {
	  if ([tmpString isKindOfClass: GDL2_NSNumberClass])
	    {
	      [self setParameterDirection: [tmpString intValue]];
	    }
	  else
	    {
	      EOParameterDirection eDirection = EOVoid;

	      if ([tmpString isEqual: @"in"])
		eDirection = EOInParameter;
	      else if ([tmpString isEqual: @"out"])
		eDirection = EOOutParameter;
	      else if ([tmpString isEqual: @"inout"])
		eDirection = EOInOutParameter;

	      [self setParameterDirection: eDirection];
	    }
        }

      tmpObject = [propertyList objectForKey: @"userInfo"];

      if (tmpObject)
        [self setUserInfo: tmpObject];
      else
        { 
          tmpObject = [propertyList objectForKey: @"userDictionary"];

          if (tmpObject)
            [self setUserInfo: tmpObject];
        }

      tmpObject = [propertyList objectForKey: @"internalInfo"];

      if (tmpObject)
        [self setInternalInfo: tmpObject];

      tmpString = [propertyList objectForKey: @"docComment"];

      if (tmpString)
        [self setDocComment: tmpString];

      EOFLOGObjectLevelArgs(@"gsdb", @"Attribute name=%@", _name);

      tmpString = [propertyList objectForKey: @"isReadOnly"];
      EOFLOGObjectLevelArgs(@"gsdb", @"tmpString=%@", tmpString);

      [self setReadOnly: [tmpString isEqual: @"Y"]];
      EOFLOGObjectLevelArgs(@"gsdb", @"tmpString=%@", tmpString);
    }

  return self;
}

- (void)awakeWithPropertyList: (NSDictionary *)propertyList
{
  //Seems OK
  NSString *definition;
  NSString *columnName;
  NSString *tmpString;

  definition = [propertyList objectForKey: @"definition"];

  if (definition)
    [self setDefinition: definition];

  columnName = [propertyList objectForKey: @"columnName"];

  if (columnName)
    [self setColumnName: columnName];

  tmpString = [propertyList objectForKey: @"prototypeName"];

  if (tmpString)
    {
      EOAttribute *attr = [[_parent model] prototypeAttributeNamed: tmpString];

      if (attr)
	[self setPrototype: attr];
    }

  EOFLOGObjectLevelArgs(@"gsdb", @"Attribute %@ awakeWithPropertyList:%@",
                        self, propertyList);
}

- (void)encodeIntoPropertyList: (NSMutableDictionary *)propertyList
{
  if (_name)
    [propertyList setObject: _name forKey: @"name"];
  if (_prototype)
    [propertyList setObject: [_prototype name] forKey: @"prototypeName"];
  if (_serverTimeZone)
    [propertyList setObject: [_serverTimeZone name]
		  forKey: @"serverTimeZone"];
  if (_columnName)
    [propertyList setObject: _columnName forKey: @"columnName"];
  if (_definitionArray)
    [propertyList setObject: [_definitionArray definition]
		  forKey: @"definition"];
  if (_externalType)
    [propertyList setObject: _externalType forKey: @"externalType"];
  if (_valueClassName)
    [propertyList setObject: _valueClassName forKey: @"valueClassName"];
  if (_valueType)
    [propertyList setObject: _valueType forKey: @"valueType"];

  if (_valueFactoryMethodName)
    {
      NSString *methodArg;

      [propertyList setObject: _valueFactoryMethodName
		    forKey: @"valueFactoryMethodName"];

      switch (_argumentType)
	{
	  case EOFactoryMethodArgumentIsNSData:
	    methodArg = @"EOFactoryMethodArgumentIsNSData";
	    break;
	  case EOFactoryMethodArgumentIsNSString:
	    methodArg = @"EOFactoryMethodArgumentIsNSString";
	    break;
	  case EOFactoryMethodArgumentIsBytes:
	    methodArg = @"EOFactoryMethodArgumentIsBytes";
	    break;
	  default:
	    methodArg = nil;
	    [NSException raise: NSInternalInconsistencyException
			 format: @"%@ -- %@ 0x%x: Invalid value for _argumentType:%d",
			 NSStringFromSelector(_cmd),
			 NSStringFromClass([self class]),
			 self, _argumentType];
	}

      [propertyList setObject: methodArg
		    forKey: @"factoryMethodArgumentType"];
    }

  if (_adaptorValueConversionMethodName)
    [propertyList setObject: _adaptorValueConversionMethodName
		  forKey: @"adaptorValueConversionMethodName"];

  if (_readFormat)
    [propertyList setObject: _readFormat forKey: @"readFormat"];
  if (_writeFormat)
    [propertyList setObject: _writeFormat forKey: @"writeFormat"];
  if (_width > 0)
    [propertyList setObject: [NSString stringWithFormat:@"%u", _width]
		  forKey: @"width"];
  if (_precision > 0)
    [propertyList setObject: [NSString stringWithFormat:@"%hu", _precision]
		  forKey: @"precision"];
  if (_scale != 0)
    [propertyList setObject: [NSString stringWithFormat:@"%hi", _scale]
		  forKey: @"scale"];

  if (_parameterDirection != 0)
    [propertyList setObject: [NSString stringWithFormat:@"%d",
				       (int)_parameterDirection]
		  forKey: @"parameterDirection"];

  if (_userInfo)
    [propertyList setObject: _userInfo forKey: @"userInfo"];
  if (_docComment)
    [propertyList setObject: _docComment forKey: @"docComment"];
  
  if (_flags.isReadOnly)
    [propertyList setObject: @"Y"
		  forKey: @"isReadOnly"];
  if (_flags.allowsNull)
    [propertyList setObject: @"Y"
		  forKey: @"allowsNull"];
}

- (void)dealloc
{
  DESTROY(_name);
  DESTROY(_prototype);
  DESTROY(_columnName);
  DESTROY(_externalType);
  DESTROY(_valueType);
  DESTROY(_valueClassName);
  DESTROY(_readFormat);
  DESTROY(_writeFormat);
  DESTROY(_serverTimeZone);
  DESTROY(_valueFactoryMethodName);
  DESTROY(_adaptorValueConversionMethodName);
  DESTROY(_sourceToDestinationKeyMap);
  DESTROY(_userInfo);
  DESTROY(_internalInfo);
  DESTROY(_docComment);

  [super dealloc];
}

- (void)gcDecrementRefCountOfContainedObjects
{
  EOFLOGObjectFnStart();

  [_parent gcDecrementRefCount];
  EOFLOGObjectLevel(@"gsdb", @"prototype gcDecrementRefCount");

  [_prototype gcDecrementRefCount];
  EOFLOGObjectLevel(@"gsdb", @"definitionArray gcDecrementRefCount");

  [(id)_definitionArray gcDecrementRefCount];
  EOFLOGObjectLevel(@"gsdb", @"realAttribute gcDecrementRefCount");

  [_realAttribute gcDecrementRefCount];

  EOFLOGObjectFnStop();
}

- (BOOL)gcIncrementRefCountOfContainedObjects
{
  if (![super gcIncrementRefCountOfContainedObjects])
    return NO;

  [_parent gcIncrementRefCount];
  [_prototype gcIncrementRefCount];
  [(id)_definitionArray gcIncrementRefCount];
  [_realAttribute gcIncrementRefCount];

  [_parent gcIncrementRefCountOfContainedObjects];
  [_prototype gcIncrementRefCountOfContainedObjects];
  [(id)_definitionArray gcIncrementRefCountOfContainedObjects];
  [_realAttribute gcIncrementRefCountOfContainedObjects];
  
  return YES;
}

- (unsigned)hash
{
  return [_name hash];
}

- (NSString *)description
{
  NSString *dscr = [NSString stringWithFormat: @"<%s %p - name=%@ entity=%@ columnName=%@ definition=%@ ",
			     object_get_class_name(self),
			     (void*)self,
			     [self name],
			     [[self entity] name],
			     [self columnName],
			     [self definition]];

  dscr = [dscr stringByAppendingFormat: @"valueClassName=%@ valueType=%@ externalType=%@ allowsNull=%s isReadOnly=%s isDerived=%s isFlattened=%s>",
	       [self valueClassName],
	       [self valueType],
               [self externalType],
	       ([self allowsNull] ? "YES" : "NO"),
	       ([self isReadOnly] ? "YES" : "NO"),
	       ([self isDerived] ? "YES" : "NO"),
	       ([self isFlattened] ? "YES" : "NO")];

  return dscr;
}

/* We override GCObjects default implementation
   as attributes cannot be copied */
- (id)copyWithZone:(NSZone *)zone
{
  [self notImplemented: _cmd];
  return nil;
}
 
- (EOEntity *)entity
{
  if (_flags.isParentAnEOEntity)
    return _parent;
  else
    return nil;
}

- (NSString *)name
{
  return _name;
}

- (NSString *)columnName
{
  if (_columnName)
    return _columnName;

  return [_prototype columnName];
}

- (NSString *)definition
{
  NSString *definition = nil;

//  EOFLOGObjectFnStart();
//  EOFLOGObjectLevel(@"gsdb",@"_definitionArray:%@",_definitionArray);

  definition = [_definitionArray valueForSQLExpression: nil];

//  EOFLOGObjectLevel(@"gsdb",@"definition:%@",definition);
//  EOFLOGObjectFnStop();

  return definition;
}

- (NSString *)readFormat
{
  if (_readFormat)
    return _readFormat;

  return [_prototype readFormat];
}

- (NSString *)writeFormat
{
  if (_writeFormat)
    return _writeFormat;

  return [_prototype writeFormat];
}

- (NSDictionary *)userInfo
{
  return _userInfo;
}

- (NSString *)docComment
{
  return _docComment;
}

- (int)scale
{
  if (_scale)
    return _scale;

  if (_prototype)
    return [_prototype scale];

  return 0;
}

- (unsigned)precision
{
  if (_precision)
    return _precision;

  if (_prototype)
    return [_prototype precision];

  return 0;
}

- (unsigned)width
{
  if (_width)
    return _width;

  if (_prototype)
    return [_prototype width];

  return 0;
}

- (id)parent
{
  return _parent;
}

- (EOAttribute *)prototype
{
  return _prototype;
}

- (NSString *)prototypeName
{
  return [_prototype name];
}

- (EOParameterDirection)parameterDirection
{
  return _parameterDirection;
}

- (BOOL)allowsNull
{
  if (_flags.allowsNull)
    return _flags.allowsNull;

  if (_prototype)
    return [_prototype allowsNull];

  return NO;
}

- (BOOL)isKeyDefinedByPrototype:(NSString *)key
{
  return NO; // TODO
}

- (EOStoredProcedure *)storedProcedure
{
  if ([_parent isKindOfClass: [EOStoredProcedure class]])
    return _parent;

  return nil;
}

- (BOOL)isReadOnly
{
//call isDerived
  if (_flags.isReadOnly)
    return _flags.isReadOnly;

  if (_prototype)
    return [_prototype isReadOnly];

  return NO;
}

/** 
 * Return NO when the attribute corresponds to one SQL column in its entity
 * associated table return YES otherwise. 
 * An attribute with a definition such as 
 * "anotherAttributeName * 2" is derived.
 * A Flattened attribute is also a derived attributes.
 **/
- (BOOL)isDerived
{
  //Seems OK
  if(_definitionArray)
    return YES;

  return NO;
}


/** 
 * Returns YES if the attribute is flattened, NO otherwise.  
 * A flattened attribute is an attribute with a definition
 * using a relationship to another entity.  
 * A Flattened attribute is also a derived attribute.
 **/
- (BOOL)isFlattened
{
  BOOL isFlattened = NO;
  // Seems OK

  if(_definitionArray)
    isFlattened = [_definitionArray isFlattened];

  return isFlattened;
}

- (NSString *)valueClassName
{
  if (_valueClassName)
    return _valueClassName;

  if ([self isFlattened])
    return [[_definitionArray realAttribute] valueClassName];

  return [_prototype valueClassName];
}

- (NSString *)externalType
{
  if (_externalType)
    return _externalType;

  if ([self isFlattened])
    return [[_definitionArray realAttribute] externalType];

  return [_prototype externalType];
}

- (NSString *)valueType
{
  if (_valueType)
    return _valueType;
  else if([self isFlattened])
    return [[_definitionArray realAttribute] valueType];
  else
    return [_prototype valueType];
}

@end

@implementation EOAttribute (EOAttributeSQLExpression)
/**
 * Returns the value to use in an EOSQLExpression. 
 **/
- (NSString *) valueForSQLExpression: (EOSQLExpression *)sqlExpression
{
  NSString *value=nil;

//  EOFLOGObjectLevel(@"gsdb",@"EOAttribute %p",self);
  NSEmitTODO();  //TODO

  if (_definitionArray)
    value = [_definitionArray valueForSQLExpression: sqlExpression];
  else
    value = [self name];

  return value;
}

@end
@implementation EOAttribute (EOAttributeEditing)

- (NSException *)validateName:(NSString *)name
{
  NSArray *storedProcedures;
  const char *p, *s = [name cString];
  int exc = 0;

  if (!name || ![name length]) exc++;

  if (!exc)
    {
      p = s;

      while (*p)
        {
	  if (!isalnum(*p) &&
	     *p != '@' && *p != '#' && *p != '_' && *p != '$')
            {
	      exc++;
	      break;
            }
	  p++;
        }

      if (!exc && *s == '$')
	exc++;
      
      if (exc)
        return [NSException exceptionWithName: NSInvalidArgumentException
			reason: [NSString stringWithFormat:@"%@ -- %@ 0x%x: argument \"%@\" contains invalid char '%c'",
					  NSStringFromSelector(_cmd),
					  NSStringFromClass([self class]),
					  self,
					  name,
					  *p]
			userInfo: nil];
      if ([[self entity] attributeNamed:name])
	exc++;
      else if ((storedProcedures = [[[self entity] model] storedProcedures]))
        {
	  NSEnumerator *stEnum = [storedProcedures objectEnumerator];
	  EOStoredProcedure *st;
	  
	  while ((st = [stEnum nextObject]))
            {
	      NSEnumerator *attrEnum;
	      EOAttribute  *attr;
	      
	      attrEnum = [[st arguments] objectEnumerator];

	      while ((attr = [attrEnum nextObject]))
                {
		  if ([name isEqualToString: [attr name]])
                    {
		      exc++;
		      break;
                    }
                }

	      if (exc) break;
            }
        }
    }

  if (exc)
    {
      return [NSException exceptionWithName: NSInvalidArgumentException
                         reason: [NSString stringWithFormat: @"%@ -- %@ 0x%x: \"%@\" already used in the model",
                                 NSStringFromSelector(_cmd),
                                 NSStringFromClass([self class]),
                                 self,
                                 name]
                        userInfo: nil];
    }
  
  return nil;
}

- (void)setName: (NSString *)name
{
  if ([_name isEqual: name]==NO)
    {
      NSString *oldName = nil;
      [[self validateName: name] raise];

      oldName = AUTORELEASE(RETAIN(_name));
      [self willChange];
      ASSIGN(_name, name);
      if (_flags.isParentAnEOEntity)
	{
	  [_parent _setIsEdited];
	  [_parent _attributeNameChangedFrom: oldName to: name];
	}
    }

}

- (void)setPrototype: (EOAttribute *)prototype 
{
  [self willChange];
  ASSIGN(_prototype, prototype);
}

- (void)setColumnName: (NSString *)columnName
{
  //seems OK
  [self willChange];

  ASSIGN(_columnName, columnName);
  DESTROY(_definitionArray);

  [_parent _setIsEdited];
  [self _setOverrideForKeyEnum:1];
}

- (void)_setDefinitionWithoutFlushingCaches: (NSString *)definition
{
  EOExpressionArray *expressionArray=nil;

  [self willChange];
  expressionArray = [_parent _parseDescription: definition
			     isFormat: NO
			     arguments: NULL];

  expressionArray = [self _normalizeDefinition: expressionArray
			  path: nil];
  /*
  //TODO finish
  l un est code 
  
  entity primaryKeyAttributes (code)
  ??

  [self _removeFromEntityArray:code selector:setPrimaryKeyAttributes:
  */

  ASSIGN(_definitionArray, expressionArray);
}

-(id)_normalizeDefinition: (EOExpressionArray*)definition
                     path: (id)path
{
//TODO
/*
definition _isPropertyPath //NO
count
object atindex
  self _normalizeDefinition:ret path:NSArray()
adddobject


if attribute
if isderived //NO
??
ret attr 

return nexexp
*/
  return definition;
}

- (void)setDefinition:(NSString *)definition
{
  if(definition)
    {
      [self willChange];
      [self _setDefinitionWithoutFlushingCaches: definition];
      [_parent _setIsEdited];
      DESTROY(_columnName);//??
    }
}

- (void)setReadOnly: (BOOL)yn
{
  if(!yn && ([self isDerived] && ![self isFlattened]))
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: cannot set to NO while the attribute is derived but not flattened.",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  [self willChange];
  _flags.isReadOnly = yn;
}

- (void)setExternalType: (NSString *)type
{
  //OK
  [self willChange];

  ASSIGN(_externalType, type);

  [_parent _setIsEdited];
  [self _setOverrideForKeyEnum: 0];//TODO
}

- (void)setValueType: (NSString *)type
{
  //OK
  [self willChange];

  ASSIGN(_valueType, type);

  if ([_valueType length]==1)
    _valueTypeChar=(char)[_valueType characterAtIndex:0];
  else
    _valueTypeChar='\0';

  [self _setOverrideForKeyEnum: 4];//TODO
}

- (void)setValueClassName: (NSString *)name
{
  [self willChange];

  ASSIGN(_valueClassName, name);

  _valueClass = NSClassFromString(_valueClassName);

  _flags.isAttributeValueInitialized = NO;

  [self _setOverrideForKeyEnum: 3];//TODO
}

- (void)setWidth: (unsigned)length
{
  [self willChange];
  _width = length;
}

- (void)setPrecision: (unsigned)precision
{
  [self willChange];
  _precision = precision;
}

- (void)setScale: (int)scale
{
  [self willChange];
  _scale = scale;
}

- (void)setAllowsNull: (BOOL)allowsNull
{
  //OK
  [self willChange];

  _flags.allowsNull = allowsNull;

  [self _setOverrideForKeyEnum: 15];//TODO
}

- (void)setWriteFormat: (NSString *)string
{
  [self willChange];
  ASSIGN(_writeFormat, string);
}

- (void)setReadFormat: (NSString *)string
{
  [self willChange];
  ASSIGN(_readFormat, string);
}

- (void)setParameterDirection: (EOParameterDirection)parameterDirection
{
  [self willChange];
  _parameterDirection = parameterDirection;
}

- (void)setUserInfo: (NSDictionary *)dictionary
{
  //OK
  [self willChange];

  ASSIGN(_userInfo, dictionary);

  [_parent _setIsEdited];
  [self _setOverrideForKeyEnum: 10];//TODO
}

- (void)setInternalInfo: (NSDictionary *)dictionary
{
  //OK
  [self willChange];
  ASSIGN(_internalInfo, dictionary);
  [_parent _setIsEdited];
  [self _setOverrideForKeyEnum: 10]; //TODO
}

- (void)setDocComment: (NSString *)docComment
{
  //OK
  [self willChange];
  ASSIGN(_docComment, docComment);
  [_parent _setIsEdited];
}

@end


@implementation EOAttribute (EOBeautifier)

/*+ Make the name conform to the Next naming style
    NAME -> name, FIRST_NAME -> firstName +*/
- (void)beautifyName
{
  NSArray  *listItems;
  NSString *newString=[NSMutableString string];
  int	    anz,i;
  
  EOFLOGObjectFnStartOrCond2(@"ModelingClasses", @"EOAttribute");
  
  // Makes the receiver's name conform to a standard convention. Names that conform to this style are all lower-case except for the initial letter of each embedded word other than the first, which is upper case. Thus, "NAME" becomes "name", and "FIRST_NAME" becomes "firstName".
  
  if ((_name) && ([_name length]>0))
    {
      listItems = [_name componentsSeparatedByString: @"_"];
      newString = [newString stringByAppendingString:
			       [[listItems objectAtIndex: 0] lowercaseString]];
      anz = [listItems count];

      for(i = 1; i < anz; i++)
	{
	  newString = [newString stringByAppendingString:
				   [[listItems objectAtIndex: i]
				     capitalizedString]];
	}
    
    //#warning ergÙnzen um alle components (attributes, ...)
    
    // Exception abfangen
    NS_DURING
      {
        [self setName: newString];
      }
    NS_HANDLER
      {
        NSLog(@"%@ in Class: EOAttribute , Method: beautifyName >> error : %@",
              [localException name], [localException reason]);
      }
    NS_ENDHANDLER;
  }
  
  EOFLOGObjectFnStopOrCond2(@"ModelingClasses", @"EOAttribute");
}

@end


@implementation EOAttribute (EOCalendarDateSupport)

- (NSTimeZone *)serverTimeZone
{
  if (_serverTimeZone)
    return _serverTimeZone;

  return [_prototype serverTimeZone];
}

@end


@implementation EOAttribute (EOCalendarDateSupportEditing)

- (void)setServerTimeZone: (NSTimeZone *)tz
{
  [self willChange];
  ASSIGN(_serverTimeZone, tz);
}

@end


@implementation EOAttribute (EOAttributeValueCreation)


/** 
 * Returns an NSData or a custom-class value object
 * from the supplied set of bytes. 
 * The Adaptor calls this method during value creation
 * when fetching objects from the database. 
 * For efficiency, the returned value is NOT autoreleased.
 *
 * NB: The documentation of the reference implementation 
 * mistakenly claims that it returns an NSString.
 **/
- (id)newValueForBytes: (const void *)bytes
                length: (int)length
{
  NSData *value = nil;
  Class valueClass = [self _valueClass];

  if (valueClass != Nil && valueClass != GDL2_NSDataClass)
    {
      switch (_argumentType)
        {
	case EOFactoryMethodArgumentIsNSData:
          {
            //For efficiency reasons, the returned value is NOT autoreleased !
            value = [GDL2_alloc(NSData) initWithBytes: bytes length: length];
            
            // If we have a value factiry method, call it to get the final value
            if(_valueFactoryMethod != NULL)
              {
                NSData* tmp = value;
                // valueFactoryMethod returns an autoreleased value
                value = [(id)valueClass performSelector: _valueFactoryMethod
                           withObject: value];
                if (value != tmp)
                  {
                    RETAIN(value);
                    RELEASE(tmp);
                  };
              };

            break;
          }

	case EOFactoryMethodArgumentIsBytes:          
          {
            NSMethodSignature *aSignature = nil;
            NSInvocation *anInvocation = nil;

            // TODO: verify with WO
            NSAssert2(_valueFactoryMethod,
                      @"No _valueFactoryMethod (valueFactoryMethodName=%@) in attribute %@",
                      _valueFactoryMethodName,self);

            // First find signature for method
            aSignature =
              [valueClass
                methodSignatureForSelector: _valueFactoryMethod];
            
            // Create the invocation object
            anInvocation 
              = [NSInvocation invocationWithMethodSignature: aSignature];
            
            // Put the selector
            [anInvocation setSelector: _valueFactoryMethod];
            
            // The target is the custom value class
            [anInvocation setTarget: valueClass];
            
            // arguments are buffer pointer and length
            [anInvocation setArgument: &bytes atIndex: 2];
            [anInvocation setArgument: &length atIndex: 3];
            
            // Let's invoke the method
            [anInvocation invoke];
            
            // Get the returned value
            [anInvocation getReturnValue: &value];
            
            //For efficiency reasons, the returned value is NOT autoreleased !
            // valueFactoryMethod returns an autoreleased value
            RETAIN(value);
            
            break;
          }
	case EOFactoryMethodArgumentIsNSString:
            // TODO: verify with WO
	  break;
        }
    }
    
  if(!value)
    {
      //For efficiency reasons, the returned value is NOT autoreleased !
      value = [GDL2_alloc(NSData) initWithBytes: bytes length: length];
    }

  return value;
}

/** 
 * Returns a NSString or a custom-class value object
 * from the supplied set of bytes using  encoding. 
 * The Adaptor calls this method during value creation
 * when fetching objects from the database. 
 * For efficiency, the returned value is NOT autoreleased.
 **/
- (id)newValueForBytes: (const void *)bytes
                length: (int)length
              encoding: (NSStringEncoding)encoding
{
  NSString* value = nil;
  Class valueClass = [self _valueClass];

  if (valueClass != Nil && valueClass != GDL2_NSStringClass)
    {
      switch (_argumentType)
        {
	case EOFactoryMethodArgumentIsNSString:
	  {
	    NSData *data = nil;
            NSString *string = nil;

	    data = AUTORELEASE([(GDL2_alloc(NSData)) initWithBytes: bytes
						     length: length]);

            string = [(GDL2_alloc(NSString)) initWithData: data
                                             encoding: encoding];

            // If we have a value factiry method, call it to get the final value
            if(_valueFactoryMethod != NULL)
              {                
                value = [((id)valueClass) performSelector: _valueFactoryMethod
                                          withObject: string];
                if ( value != string)
                  {
                    //For efficiency reasons, the returned value is NOT autoreleased !
                    RETAIN(value);
                    RELEASE(string);
                  };
              }
            else
              {
                //For efficiency reasons, the returned value is NOT autoreleased !
                value = string;
              };
	    break;
	  }

	case EOFactoryMethodArgumentIsBytes:
	  {
            NSMethodSignature *aSignature = nil;
            NSInvocation *anInvocation = nil;
            
            // TODO: verify with WO
            NSAssert2(_valueFactoryMethod,
                      @"No _valueFactoryMethod (valueFactoryMethodName=%@) in attribute %@",
                      _valueFactoryMethodName,self);

            // First find signature for method            
	    aSignature 
	      = [valueClass methodSignatureForSelector: _valueFactoryMethod];
            
            // Create the invocation object
	    anInvocation 
	      = [NSInvocation invocationWithMethodSignature: aSignature];
            
            // Put the selector
	    [anInvocation setSelector: _valueFactoryMethod];

            // The target is the custom value class
            [anInvocation setTarget: valueClass];

            // arguments are buffer pointer, length and encoding
	    [anInvocation setArgument: &bytes atIndex: 2];
	    [anInvocation setArgument: &length atIndex: 3];
	    [anInvocation setArgument: &encoding atIndex: 4];

            // Let's invoke the method
            [anInvocation invoke];
            
            // Get the returned value
            [anInvocation getReturnValue: &value];
            
            //For efficiency reasons, the returned value is NOT autoreleased !
            // valueFactoryMethod returns an autoreleased value
            RETAIN(value);

            break;
	  }

	case EOFactoryMethodArgumentIsNSData:
          // TODO: verify with WO
	  break;
        }
    }
    
  if(!value)
    {
      NSData *data;
      data = AUTORELEASE([(GDL2_alloc(NSData)) initWithBytes: bytes
					       length: length]);

      //For efficiency reasons, the returned value is NOT autoreleased !
      value = [(GDL2_alloc(NSString)) initWithData: data
				      encoding: encoding];
    }
  
  return value;
}

/**
 * Returns an NSCalendarDate object
 * from the supplied time information. 
 * The Adaptor calls this method during value creation
 * when fetching objects from the database. 
 * For efficiency, the returned value is NOT autoreleased.
 * Milliseconds are dropped since they cannot be easily be stored in 
 * NSCalendarDate.
 **/
- (NSCalendarDate *)newDateForYear: (int)year
                             month: (unsigned)month
                               day: (unsigned)day
                              hour: (unsigned)hour
                            minute: (unsigned)minute
                            second: (unsigned)second
                       millisecond: (unsigned)millisecond
                          timezone: (NSTimeZone *)timezone
                              zone: (NSZone *)zone
{
  NSCalendarDate *date = nil;

  // FIXME: extend initializer to include Milliseconds

  //For efficiency reasons, the returned value is NOT autoreleased !
  date = [(GDL2_allocWithZone(NSCalendarDate,zone))
           initWithYear: year
           month: month
           day: day
           hour: hour
           minute: minute
           second: second
           timeZone: timezone];

  return date;
}

/** Returns the name of the method to use for creating a custom class 
value for this attribute.

See Also: - valueFactoryMethod, -newValueForBytes:length:
**/
- (NSString *)valueFactoryMethodName
{
  return _valueFactoryMethodName;
}

/** Returns the selector of the method to use for creating a custom class 
value for this attribute.
Default implementation returns selector for name returned by 
-valueFactoryMethodName or NULL if no selector is found.

See Also: - valueFactoryMethodName, -newValueForBytes:length:
**/
- (SEL)valueFactoryMethod
{
  return _valueFactoryMethod;
}

/**
 * Depending on -adaptorValueType this method checks whether the value
 * is a NSNumber, NSString, NSData or NSDate instance respectively.
 * If not, it attempts to retrieve the -adaptorValueConversionMethod
 * which should be used to convert the value accordingly.  If none
 * has been specified and the -adaptorValueType is EOAdaptorBytesType,
 * it tries to convert the value by invoking -archiveData.
 * The EONull instance is not converted.
 * Returns the converted value.
 * Note: This implementation currently raises if -adaptorValueType is of
 * an unknown type or if conversion is necessary but not possible.  This
 * maybe contrary to the reference implementation but it seems like useful
 * behavior.  If this is causing problems please submit a bug report.
 */
- (id)adaptorValueByConvertingAttributeValue: (id)value
{
  EOAdaptorValueType adaptorValueType = [self adaptorValueType];

  // No conversion for an EONull value
  if (value != GDL2_EONull)
    {
      BOOL convert = NO;

      // Find if we need a conversion
      switch (adaptorValueType)
        {
        case EOAdaptorNumberType:
	  convert = [value isKindOfClass: GDL2_NSNumberClass] ? NO : YES;
	  break;
        case EOAdaptorCharactersType:
	  convert = [value isKindOfClass: GDL2_NSStringClass] ? NO : YES;
	  break;
        case EOAdaptorBytesType:
	  convert = [value isKindOfClass: GDL2_NSDataClass] ? NO : YES;
	  break;
        case EOAdaptorDateType:
	  convert = [value isKindOfClass: GDL2_NSDateClass] ? NO : YES;
	  break;
	default:
	  [NSException raise: NSInvalidArgumentException
		       format: @"Illegal adaptorValueType: %d", 
		       adaptorValueType];
        }

      // Do value need conversion ?
      if (convert)
        {
          SEL sel;
          sel = [self adaptorValueConversionMethod];
          
          if (sel == 0)
            {
              if (adaptorValueType == EOAdaptorBytesType)
                {
                  value = [value archiveData];
                }
              else
                {
                  /* This exception might not be conformant, but seems helpful.  */
                  [NSException raise: NSInvalidArgumentException
                               format: @"Value of class: %@ needs conversion "
                               @"yet no conversion method specified. "
                               @"Attribute is %@. adaptorValueType=%d", 
                               NSStringFromClass([value class]),
                               self,adaptorValueType];
                }
            }
          else
            {
              value = [value performSelector: sel];
            }
        }
    };
  return value;
}

/** Returns method name to use to convert value of a class 
different than attribute adaptor value type. 

See also: -adaptorValueByConvertingAttributeValue, -adaptorValueConversionMethod
**/
- (NSString *)adaptorValueConversionMethodName
{
  return _adaptorValueConversionMethodName;
}

/** Returns selector of the method to use to convert value of a class 
different than attribute adaptor value type. 
Default implementation returns selector of method returned by 
adaptorValueConversionMethodName or NULL if there's not selector for the method

See also: -adaptorValueByConvertingAttributeValue, -adaptorValueConversionMethodName
**/
- (SEL)adaptorValueConversionMethod
{
  return _adaptorValueConversionMethod;
}

/** Returns an EOAdaptorValueType describing the adaptor 
(i.e. database) type of data for this attribute.

Returned value can be:
EOAdaptorBytesType 	Raw bytes (default type)
EOAdaptorNumberType 	Number value (attribute valueClass is kind of NSNumber)
EOAdaptorCharactersType String value (attribute valueClass is kind of NSString)
EOAdaptorDateType 	Date value (attribute valueClass is kind of NSDate)

**/
- (EOAdaptorValueType)adaptorValueType
{
  if (!_flags.isAttributeValueInitialized)
    {
      Class adaptorClasses[] = { GDL2_NSNumberClass, 
                                 GDL2_NSStringClass,
                                 GDL2_NSDateClass };
      EOAdaptorValueType values[] = { EOAdaptorNumberType,
                                      EOAdaptorCharactersType,
                                      EOAdaptorDateType };
      Class valueClass = Nil;
      int i = 0;
      
      _adaptorValueType = EOAdaptorBytesType;

      for ( i = 0; i < 3 && !_flags.isAttributeValueInitialized; i++)
        {
          for ( valueClass = [self _valueClass];
                valueClass != Nil;
                valueClass = GSObjCSuper(valueClass))
            {
              if (valueClass == adaptorClasses[i])
		{
		  _adaptorValueType=values[i];
		  _flags.isAttributeValueInitialized = YES;
		  break;
		}    
            }
        }
      
      _flags.isAttributeValueInitialized = YES;
    };
  return _adaptorValueType;
}


/** Returns the type of argument needed by the factoryMethod.

Type can be:

EOFactoryMethodArgumentIsNSData 	
	method need one parameter: a NSData

EOFactoryMethodArgumentIsNSString 	
	method need one parameter: a NSString

EOFactoryMethodArgumentIsBytes 	        
	method need 2 parameters (for data type valueClass): a raw bytes buffer and its length
	or 3 parameters (for string type valueClass): a raw bytes buffer, its length and the encoding

See also: -valueFactoryMethod, -setFactoryMethodArgumentType:
**/
- (EOFactoryMethodArgumentType)factoryMethodArgumentType
{
  return _argumentType;
}

@end


@implementation EOAttribute (EOAttributeValueCreationEditing)

/** Set the "factory method" name (the method to invoke to create custom class attribute value). 
This method must be a class method returning an autoreleased value of attribute valueClass.

See also: -setFactoryMethodArgumentType:
**/
- (void)setValueFactoryMethodName: (NSString *)factoryMethodName
{
  [self willChange];
  ASSIGN(_valueFactoryMethodName, factoryMethodName);
  _valueFactoryMethod = NSSelectorFromString(_valueFactoryMethodName);
}

/** Set method name to use to convert value of a class 
different than attribute adaptor value type. 

See also: -adaptorValueByConvertingAttributeValue, -adaptorValueConversionMethod, 
	-adaptorValueConversionMethodName
**/

- (void)setAdaptorValueConversionMethodName: (NSString *)conversionMethodName
{
  [self willChange];
  ASSIGN(_adaptorValueConversionMethodName, conversionMethodName);

  _adaptorValueConversionMethod = NSSelectorFromString(_adaptorValueConversionMethodName);
}

/** Set the type of argument needed by the factoryMethod.

Type can be:

EOFactoryMethodArgumentIsNSData 	
	method need one parameter: a NSData

EOFactoryMethodArgumentIsNSString 	
	method need one parameter: a NSString

EOFactoryMethodArgumentIsBytes 	        
	method need 2 parameters (for data type valueClass): a raw bytes buffer and its length
	or 3 parameters (for string type valueClass): a raw bytes buffer, its length and the encoding

See also:   -setValueFactoryMethodName:, -factoryMethodArgumentType
**/
- (void)setFactoryMethodArgumentType: (EOFactoryMethodArgumentType)argumentType
{
  [self willChange];
  _argumentType = argumentType;
}

@end


@implementation EOAttribute (EOAttributeValueMapping)

/** Validates value pointed by valueP, may set changed validated value in 
valueP and return an validation exception if constraints validation fails.
valueP must not be NULL.

More details:
1. raise an exception if [self allowsNull] == NO but *valueP is nil or EONull
	except if attribute is a primaryKey attribute (reason of this process 
        exception is currently unknown).

2. if valueClassName isn't set, return nil and leave *valueP unchanged

3. if it can't find the class by name, log message, return nil and 
	leave *valueP unchanged

4. do the fancy type conversions as necessary (Pretty much the current 
	handling we have)

5. THEN if width is not 0 call adaptorValueByConvertingAttributeValue: 
	 on the new value and the if returned value is NSString or NSData 
	 validate length with width and return a corresponding exception 
         if it's longer than allowed.
**/

- (NSException *)validateValue: (id*)valueP
{
  NSException *exception=nil;

  NSAssert(valueP, @"No value pointer");

  NSDebugMLog(@"In EOAttribute validateValue: value (class=%@) = %@ attribute = %@",
              [*valueP class],*valueP,self);

  // First check if value is nil or EONull
  if (_isNilOrEONull(*valueP))
    {
      // Check if this is not allowed
      if ([self allowsNull] == NO)
        {
          NSArray *pkAttributes = [[self entity] primaryKeyAttributes];

          // "Primary key attributes are ignored when enforcing allowsNull 
          // property for attributes.  The values could be handled later 
          // by automatic PK-generation later
          if ([pkAttributes indexOfObjectIdenticalTo: self] == NSNotFound)
            {
              exception = 
                [NSException 
                  validationExceptionWithFormat: 
                    @"attribute '%@' of entity '%@' cannot be nil or EONull ", 
                  [self name],[[self entity] name]];
            };
        }
    }
  else // There's a value.
    {
      NSString* valueClassName=[self valueClassName];

      // if there's no valueClassName, leave the value unchanged 
      // and don't return an exception 

      if (valueClassName)
        {
          Class valueClass=[self _valueClass];

          // There's a className but no class !
          if (!valueClass)
            {
              //Log this problem, leave the value unchanged 
              // and don't return an exception 
              NSLog(@"No valueClass for valueClassName '%@' in attribute %@",
                    valueClassName,self);
            }
          else
            {
              unsigned int width = 0;
              IMP isKindOfClassIMP=[*valueP  methodForSelector:@selector(isKindOfClass:)];

              // If the value has not the good class we'll try to convert it
              if ((*isKindOfClassIMP)(*valueP,@selector(isKindOfClass:),
                                      valueClass) == NO)
                {
                  // Is it a string ?
                  if ((*isKindOfClassIMP)(*valueP,@selector(isKindOfClass:),
                                          GDL2_NSStringClass))
                    {
                      if (valueClass == GDL2_NSNumberClass)
                        {
                          char valueTypeChar=[self _valueTypeChar];
                          switch(valueTypeChar)
                            {
                            case 'i':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithInt:
                                                     [*valueP intValue]];
                              AUTORELEASE(*valueP);
                              break;

                            case 'I':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithUnsignedInt:
                                                    [*valueP unsignedIntValue]];
                              AUTORELEASE(*valueP);
                              break;

                            case 'c':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithChar:
                                                    [*valueP intValue]];
                              AUTORELEASE(*valueP);
                              break;

                            case 'C':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithUnsignedChar:
                                                    [*valueP unsignedIntValue]];
                              AUTORELEASE(*valueP);
                              break;

                            case 's':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithShort:
                                                    [*valueP shortValue]];
                              AUTORELEASE(*valueP);
                              break;

                            case 'S':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithUnsignedShort:
                                                    [*valueP unsignedShortValue]];
                              AUTORELEASE(*valueP);
                              break;

                            case 'l':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithLong:
                                                    [*valueP longValue]];
                              AUTORELEASE(*valueP);
                              break;

                            case 'L':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithUnsignedLong:
                                                    [*valueP unsignedLongValue]];
                              AUTORELEASE(*valueP);
                              break;

                            case 'u':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithLongLong:
                                                    [*valueP longLongValue]];
                              AUTORELEASE(*valueP);
                              break;

                            case 'U':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithUnsignedLongLong:
                                                    [*valueP unsignedLongLongValue]];
                              AUTORELEASE(*valueP);
                              break;

                            case 'f':
                              *valueP = [GDL2_alloc(NSNumber) 
                                                   initWithFloat:
                                                    [*valueP floatValue]];
                              AUTORELEASE(*valueP);
                              break;

                            default:
                              *valueP = [GDL2_alloc(NSNumber)
                                                   initWithDouble:
                                                    [*valueP doubleValue]];
                              AUTORELEASE(*valueP);
                              break;
                            };
                        }
                      else if (valueClass == GDL2_NSDecimalNumberClass)
                        {
                          *valueP = [GDL2_alloc(NSDecimalNumber)
                                               initWithString: *valueP];
                          AUTORELEASE(*valueP);
                        }
                      else if (valueClass == GDL2_NSDataClass)
                        {
                          //TODO Verify here. 
                          *valueP = [*valueP
                                      dataUsingEncoding: 
                                        [NSString defaultCStringEncoding]];
                        }
                      else if (valueClass == GDL2_NSCalendarDateClass)
                        {
                          *valueP = AUTORELEASE([(GDL2_alloc(NSCalendarDate))
                                                  initWithString: *valueP]);
                        }
                    }
                };

              // Now, test width if any
              width = [self width];

              if (width>0)
                {
                  // First convert value to adaptor value
                  id testValue = [self adaptorValueByConvertingAttributeValue: *valueP];

                  if (testValue)
                    {
                      IMP testIsKindOfClassIMP=[testValue  methodForSelector:@selector(isKindOfClass:)];

                      // We can test NSString and NSData type only
                      if ((*testIsKindOfClassIMP)(testValue,@selector(isKindOfClass:),
                                              GDL2_NSStringClass)
                          || (*testIsKindOfClassIMP)(testValue,@selector(isKindOfClass:),
                                                     GDL2_NSDataClass))
                        {
                          unsigned int testValueLength = [testValue length];
                          if (testValueLength > width)
                            {
                              exception = [NSException validationExceptionWithFormat: 
                                                         @"Value %@ for attribute '%@' is too large",
                                                       testValue,[self name]];
                            };
                        };
                    };
                };
            }
        }
    }

  return exception;
}

@end


@implementation NSObject (EOCustomClassArchiving)

+ objectWithArchiveData: (NSData *)data
{
  return [NSUnarchiver unarchiveObjectWithData:data];
}

- (NSData *)archiveData
{
  return [NSArchiver archivedDataWithRootObject:self];
}

@end


@implementation EOAttribute (EOAttributePrivate)

- (void)setParent: (id)parent
{
  //OK
  [self willChange];
  _parent = parent;

  _flags.isParentAnEOEntity = [_parent isKindOfClass: [EOEntity class]];//??
}

- (EOAttribute *)realAttribute
{
  return _realAttribute;
}

- (GCMutableArray *)_definitionArray
{
  return _definitionArray;
}

- (Class)_valueClass
{
  if (_valueClass)
    return _valueClass;
  else if ([self isFlattened])
    return [[_definitionArray realAttribute] _valueClass];
  else
    return [_prototype _valueClass];
}

- (char)_valueTypeChar
{
  char valueTypeChar=_valueTypeChar;
  if (valueTypeChar=='\0')
    {
      // Compute it
      NSString* valueType=[self valueType];
      if ([valueType length]==1)
        valueTypeChar=(char)[valueType characterAtIndex:0];
    }
  return valueTypeChar;
};

@end

@implementation EOAttribute (EOAttributePrivate2)

- (BOOL) _hasAnyOverrides
{
  [self notImplemented: _cmd]; //TODO
  return NO;
}

- (void) _resetPrototype
{
  [self notImplemented: _cmd]; //TODO
}

- (void) _updateFromPrototype
{
  [self notImplemented: _cmd]; //TODO
}

- (void) _setOverrideForKeyEnum: (int)keyEnum
{
  //[self notImplemented:_cmd]; //TODO
}

- (BOOL) _isKeyEnumOverriden: (int)param0
{
  [self notImplemented: _cmd]; //TODO
  return NO;
}

- (BOOL) _isKeyEnumDefinedByPrototype: (int)param0
{
  [self notImplemented: _cmd]; //TODO
  return NO;
}

@end

