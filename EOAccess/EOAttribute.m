/**
   EOAttribute.m <title>EOAttribute Class</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#include <ctype.h>
#include <string.h>

#ifndef NeXT_Foundation_LIBRARY
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
#endif

#include <EOControl/EONull.h>
#include <EOControl/EOObserver.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOEntityPriv.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOAttributePriv.h>
#include <EOAccess/EOStoredProcedure.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOExpressionArray.h>

#include <string.h>


@implementation EOAttribute

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
      //OK
      NSString *tmpString;
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
	  if ([tmpString isKindOfClass: [NSNumber class]])
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
    [propertyList setObject: [NSNumber numberWithUnsignedInt: _width]
		  forKey: @"width"];
  if (_precision > 0)
    [propertyList setObject: [NSNumber numberWithUnsignedShort: _precision]
		  forKey: @"precision"];
  if (_scale != 0)
    [propertyList setObject: [NSNumber numberWithShort: _scale]
		  forKey: @"scale"];

  if (_parameterDirection != 0)
    [propertyList setObject: [NSNumber numberWithInt: _parameterDirection]
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

  dscr = [dscr stringByAppendingFormat: @"valueClassName=%@ valueType=%@ externalType=%@ isReadOnly=%s isDerived=%s isFlattened=%s>",
	       [self valueClassName],
	       [self valueType],
               [self externalType],
	       ([self isReadOnly] ? "YES" : "NO"),
	       ([self isDerived] ? "YES" : "NO"),
	       ([self isFlattened] ? "YES" : "NO")];

  return dscr;
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

  if([self isFlattened])
    return [[_definitionArray realAttribute] valueType];

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
      
      if ([[self entity] attributeNamed:name])
	exc++;
      else if ([[self entity] relationshipNamed:name])
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
    return [NSException exceptionWithName: NSInvalidArgumentException
			reason: [NSString stringWithFormat:@"%@ -- %@ 0x%x: argument \"%@\" contains invalid chars",
					  NSStringFromSelector(_cmd),
					  NSStringFromClass([self class]),
					  self,
					  name]
			userInfo: nil];

  return nil;
}

- (void)setName: (NSString *)name
{
  [[self validateName: name] raise];

  ASSIGN(_name, name);
}

- (void)setPrototype: (EOAttribute *)prototype 
{
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

  [self _setOverrideForKeyEnum: 4];//TODO
}

- (void)setValueClassName: (NSString *)name
{
  //OK
  [self willChange];

  ASSIGN(_valueClassName, name);

  _valueClass = NSClassFromString(_valueClassName);//TODO Do it later !
  [self _setOverrideForKeyEnum: 3];//TODO
}

- (void)setWidth: (unsigned)length
{
  _width = length;
}

- (void)setPrecision: (unsigned)precision
{
  _precision = precision;
}

- (void)setScale: (int)scale
{
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
  ASSIGN(_writeFormat, string);
}

- (void)setReadFormat: (NSString *)string
{
  ASSIGN(_readFormat, string);
}

- (void)setParameterDirection: (EOParameterDirection)parameterDirection
{
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
  ASSIGN(_serverTimeZone, tz);
}

@end


@implementation EOAttribute (EOAttributeValueCreation)


/** 
 * Returns an NSString or a custom-class value object
 * from the supplied set of bytes. 
 * The Adaptor calls this method during value creation
 * when fetching objects from the database. 
 * For efficiency, the returned value is NOT autoreleased.
 **/
- (id)newValueForBytes: (const void *)bytes
                length: (int)length
{
  NSMethodSignature *aSignature;
  NSInvocation *anInvocation;
  NSData *value = nil;
  Class valueClass = [self _valueClass];

  if (valueClass != Nil && valueClass != [NSData class])
    {
      switch (_argumentType)
        {
	case EOFactoryMethodArgumentIsNSData:
	  value = [[NSData alloc] initWithBytes:bytes length: length]; //For efficiency reasons, the returned value is NOT autoreleased !

	  if(_valueFactoryMethod != NULL)
	    value = [valueClass performSelector: _valueFactoryMethod
				 withObject: [value autorelease]];
	  break;

	case EOFactoryMethodArgumentIsBytes:
	  value = [valueClass alloc];//For efficiency reasons, the returned value is NOT autoreleased !

	  aSignature =
	    [valueClass
	      instanceMethodSignatureForSelector: _valueFactoryMethod];

	  anInvocation = [NSInvocation
			   invocationWithMethodSignature: aSignature];

	  [anInvocation setSelector: _valueFactoryMethod];
	  [anInvocation setTarget: value];
	  [anInvocation setArgument: &bytes atIndex: 2];
	  [anInvocation setArgument: &length atIndex: 3];
	  [anInvocation invoke];
	  break;

	case EOFactoryMethodArgumentIsNSString:
	  break;
        }
    }
    
  if(!value)
    value = [[NSData alloc] initWithBytes: bytes length: length];//For efficiency reasons, the returned value is NOT autoreleased !

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
  NSMethodSignature *aSignature;
  NSInvocation *anInvocation;
  id value = nil;
  Class valueClass = [self _valueClass];

  if (valueClass != Nil && valueClass != [NSString class])
    {
      switch (_argumentType)
        {
	case EOFactoryMethodArgumentIsNSString:
	  value = [[NSString alloc] initWithData: [NSData dataWithBytes: bytes
							  length: length]
				    encoding: encoding];//For efficiency reasons, the returned value is NOT autoreleased !
	  
	  value = [valueClass performSelector: _valueFactoryMethod
			       withObject: [value autorelease]];
	  break;

	case EOFactoryMethodArgumentIsBytes:
	  value = [valueClass alloc];//For efficiency reasons, the returned value is NOT autoreleased !

	  aSignature =
	    [valueClass
	      instanceMethodSignatureForSelector: _valueFactoryMethod];

	  anInvocation = [NSInvocation
			   invocationWithMethodSignature: aSignature];

	  [anInvocation setSelector: _valueFactoryMethod];
	  [anInvocation setTarget: value];
	  [anInvocation setArgument: &bytes atIndex: 2];
	  [anInvocation setArgument: &length atIndex: 3];
	  [anInvocation setArgument: &encoding atIndex: 4];
	  [anInvocation invoke];
	  break;

	case EOFactoryMethodArgumentIsNSData:
	  break;
        }
    }
    
  if(!value)
    value = [[NSString alloc]
	      initWithData: [NSData dataWithBytes: bytes length: length]
	      encoding: encoding];//For efficiency reasons, the returned value is NOT autoreleased !
  
  return value;
}

/**
 * Returns an NSCalanderDate object
 * from the supplied time information. 
 * The Adaptor calls this method during value creation
 * when fetching objects from the database. 
 * For efficiency, the returned value is NOT autoreleased.
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
  NSCalendarDate *date;

  //For efficiency reasons, the returned value is NOT autoreleased !
  date = [[NSCalendarDate allocWithZone: zone]
	   initWithYear: year
	   month: month
	   day: day
	   hour: hour
	   minute: minute
	   second: second
	   timeZone: timezone];

// TODO milliseconds ??

  return date;
}

- (NSString *)valueFactoryMethodName
{
  return _valueFactoryMethodName;
}

- (SEL)valueFactoryMethod
{
  return _valueFactoryMethod;
}

- (id)adaptorValueByConvertingAttributeValue: (id)value
{
  id adaptorValue = nil;
  SEL convMethod = NULL;

  convMethod = [self adaptorValueConversionMethod];

  if (convMethod)
    {
      //TODO-VERIFY
      adaptorValue = [value performSelector: convMethod];
    }
  else
    {
      //TODO-VERIFY
      EOAdaptorValueType adaptorValueType = [self adaptorValueType];

      switch (adaptorValueType)
        {
        case EOAdaptorBytesType:
          adaptorValue = [value archiveData];
          break;

        default:
          if ([value isKindOfClass: [NSNumber class]] == YES ||
	      [value isKindOfClass: [NSString class]] == YES ||
	      [value isKindOfClass: [NSDate class]] == YES ||
	      [value isKindOfClass: [NSData class]] == YES ||
	      [value isKindOfClass: [[EONull null] class]] == YES)
            adaptorValue = value;
          else
            adaptorValue = value;
          break;
        }
    }

  return adaptorValue;
}

- (NSString *)adaptorValueConversionMethodName
{
  return _adaptorValueConversionMethodName;
}

- (SEL)adaptorValueConversionMethod
{
  return _adaptorValueConversionMethod;
}

- (EOAdaptorValueType)adaptorValueType
{
  Class adaptorClasses[] = { [NSNumber class], 
                             [NSString class],
			     [NSDate class] };
  EOAdaptorValueType values[] = { EOAdaptorNumberType,
                                  EOAdaptorCharactersType,
				  EOAdaptorDateType };
  Class valueClass;
  int i;

  for ( i = 0; i < 3; i++)
    {
      for ( valueClass = [self _valueClass];
	    valueClass != Nil;
	    valueClass = GSObjCSuper(valueClass))
	{
	  if (valueClass == adaptorClasses[i])
	    return values[i];
	}
    }

  return EOAdaptorBytesType;
}

- (EOFactoryMethodArgumentType)factoryMethodArgumentType
{
  return _argumentType;
}

@end


@implementation EOAttribute (EOAttributeValueCreationEditing)

- (void)setValueFactoryMethodName: (NSString *)factoryMethodName
{
  ASSIGN(_valueFactoryMethodName, factoryMethodName);
  _valueFactoryMethod = NSSelectorFromString(_valueFactoryMethodName);
}

- (void)setAdaptorValueConversionMethodName: (NSString *)conversionMethodName
{
  ASSIGN(_adaptorValueConversionMethodName, conversionMethodName);

  _adaptorValueConversionMethod = NSSelectorFromString(_adaptorValueConversionMethodName);
}

- (void)setFactoryMethodArgumentType: (EOFactoryMethodArgumentType)argumentType
{
  _argumentType = argumentType;
}

@end


@implementation EOAttribute (EOAttributeValueMapping)

- (NSException *)validateValue: (id*)valueP
{
  NSException *exception=nil;

  NSAssert(valueP, @"No value pointer");

  if (*valueP == nil && [self allowsNull] == NO)
    exception = [NSException validationExceptionWithFormat: @"attribute '%@' cannot be nil", [self name]];
  else if (*valueP)
    {
      //call self valueClassName
      *valueP = [self adaptorValueByConvertingAttributeValue: *valueP];
      //call attribute width
      //end !

      //TODO: revoir
      {
        //EOEntity *entity = [self entity];
        //NSArray *pkAttributes = [entity primaryKeyAttributes];
        //TODO wowhat

        if (*valueP)
          {
	    Class valueClass = [self _valueClass];

            if ([*valueP isKindOfClass: valueClass] == NO)
              {
                if ([*valueP isKindOfClass: [NSString class]])
                  {
                    if (valueClass == [NSNumber class])
                      {
                        if ([[self valueType] isEqualToString: @"i"] == YES)
                          *valueP = [NSNumber numberWithInt:
						[*valueP intValue]];
                        else
                          *valueP = [NSNumber numberWithDouble:
                                                 [*valueP doubleValue]];
                      }
                    else if (valueClass == [NSDecimalNumber class])
                      *valueP = [NSDecimalNumber
				  decimalNumberWithString: *valueP];
                  
                    else if (valueClass == [NSData class])
                      *valueP = [*valueP
				  dataUsingEncoding: NSASCIIStringEncoding
				  allowLossyConversion: YES];
                  
                    else if (valueClass == [NSCalendarDate class])
                      *valueP = [[[NSCalendarDate alloc]
				   initWithString: *valueP]
				  autorelease];
                  }
              }
            else
              {
                if ([*valueP isKindOfClass: [NSString class]])
                  {
		    unsigned width = [self width];

                    if (width && [*valueP length] > width)
                      {
                        const char *buf;
                      
                        buf = [*valueP cString];
                        *valueP = [NSString stringWithCString: buf
					    length: width];
                      }
                  }
                else if ([*valueP isKindOfClass: [NSNumber class]])
                  {
                    // TODO ??
                  }
              }
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
  ASSIGN(_parent, parent);//TODO assign ??

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

  if ([self isFlattened])
    return [[_definitionArray realAttribute] _valueClass];

  return [_prototype _valueClass];
}

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

