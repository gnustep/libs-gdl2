/** 
   EOAdaptor.m <title>EOAdaptor Class</title>

   Copyright (C) 1996-2001,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>
   Date: October 1996

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   Author: David Wetzel <dave@turbocat.de>
   Date: 2010
 
   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
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
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#if HAVE_LIBC_H
# include <libc.h>
#else
#ifndef __WIN32__
# include <unistd.h>
#endif /* !__WIN32__ */
#endif

#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSData.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#include <GNUstepBase/NSObject+GNUstepBase.h>
#include <GNUstepBase/NSString+GNUstepBase.h>
#endif

#include <GNUstepBase/GSMime.h>
#include <GNUstepBase/Unicode.h>

#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include "EOAccess/EOAdaptor.h"
#include "EOAccess/EOAdaptorContext.h"
#include "EOAccess/EOAdaptorChannel.h"
#include "EOAccess/EOAttribute.h"
#include "EOAccess/EOEntity.h"
#include "EOAccess/EOModel.h"
#include "EOAccess/EOSQLExpression.h"

#include "EOAdaptorPriv.h"


NSString *EOGeneralAdaptorException = @"EOGeneralAdaptorException";

NSString *EOAdministrativeConnectionDictionaryNeededNotification 
  = @"EOAdministrativeConnectionDictionaryNeededNotification";
NSString *EOAdaptorKey = @"EOAdaptorKey";
NSString *EOModelKey = @"EOModelKey";
NSString *EOConnectionDictionaryKey = @"EOConnectionDictionaryKey";
NSString *EOAdministrativeConnectionDictionaryKey 
  = @"EOAdministrativeConnectionDictionaryKey";

@implementation EOAdaptor

+ (id)adaptorWithModel: (EOModel *)model
{
  //OK
  /* Check first to see if the adaptor class exists in the running program
     by testing the existence of [_model adaptorClassName]. */
  EOAdaptor *adaptor = nil;

  if(!model)
    [NSException raise: NSInvalidArgumentException
		 format: @"%@ -- %@ 0x%x: no model specified",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];
  else
    {
      NSString *adaptorName = [model adaptorName];

      if (!adaptorName)
        [NSException raise: NSInvalidArgumentException
		     format: @"%@ -- %@ 0x%x: no adaptor name in model named %@",
                     NSStringFromSelector(_cmd),
                     NSStringFromClass([self class]),
                     self,
                     [model name]];
      else
        {
	  NSString *className;
	  Class adaptorClass;

	  className = [adaptorName stringByAppendingString: @"Adaptor"]; 
	  adaptorClass  = NSClassFromString(className); 

          if(adaptorClass)
            adaptor = AUTORELEASE([[adaptorClass alloc] initWithName: adaptorName]);
          else
            adaptor = [self adaptorWithName: adaptorName];

          [adaptor setModel: model];
          [adaptor setConnectionDictionary: [model connectionDictionary]];
        }
    }

  return adaptor;
}

+ (id) adaptorWithName: (NSString *)name
{
  //OK
  NSBundle *bundle = [NSBundle mainBundle];
  NSString *adaptorBundlePath;
  NSArray *paths;
  Class adaptorClass;
  NSString *adaptorClassName;
  unsigned i, count;

  /* Check error */
  if ([name length] == 0)
    [NSException raise: NSInvalidArgumentException
		 format: @"%@ -- %@ 0x%x: adaptor name can't be nil",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];
  
  // append EOAdaptor
  if ([name hasSuffix: @"EOAdaptor"] == NO)
    name = [name stringByAppendingString: @"EOAdaptor"];

  /* Look in application bundle */
  adaptorBundlePath = [bundle pathForResource: name
                              ofType: @"framework"];
  // should be NSString *path=[NSBundle pathForLibraryResource:libraryResource  type:@"framework"  directory:@"Frameworks"]; ?

  /* Look in standard paths */
  if (!adaptorBundlePath)
    {
      SEL      sel = @selector(stringByAppendingPathComponent:);
      /*
	The path of where to search for the adaptor files.
      */

      paths 
	= NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory,
					      NSAllDomainsMask, NO);

      paths = [paths resultsOfPerformingSelector: sel
		     withObject: @"Frameworks"];

      /* Loop through the paths and check each one */
      for(i = 0, count = [paths count]; i < count; i++)
        {
	  bundle = [NSBundle bundleWithPath: [paths objectAtIndex: i]];
	  adaptorBundlePath = [bundle pathForResource: name
				      ofType: @"framework"];
	  
	  if(adaptorBundlePath && [adaptorBundlePath length])
	    break;
        }
    }

  /* Make adaptor bundle */
  if(adaptorBundlePath)
    bundle = [NSBundle bundleWithPath: adaptorBundlePath];
  else
    bundle = nil;

  /* Check bundle */
  if (!bundle)
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: the adaptor bundle '%@' does not exist",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self,
                 name];
  
  /* Get the adaptor bundle "infoDictionary", and pricipal class, ie. the
     adaptor class. Other info about the adaptor should be put in the
     bundle's "Info.plist" file (property list format - see NSBundle class
     documentation for details about reserved keys in this dictionary
     property list containing one entry whose key is adaptorClassName. It
     identifies the actual adaptor class from the bundle. */

  if(![bundle isLoaded])
    EOFLOGClassLevelArgs(@"gsdb", @"Loaded %@? %@", bundle, ([bundle load]? @"YES":@"NO"));

  adaptorClassName = [[bundle infoDictionary] objectForKey: @"EOAdaptorClassName"];

  EOFLOGClassLevelArgs(@"gsdb", @"adaptorClassName is %@", adaptorClassName);

  adaptorClass = NSClassFromString(adaptorClassName);

  if (adaptorClass == Nil)
    {
      adaptorClass = [bundle principalClass];
    }

  if(adaptorClass == Nil)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"%@ -- %@ 0x%x: value of EOAdaptorClassName '%@' is not a valid class and bundle does not contain a principal class",
		   NSStringFromSelector(_cmd),
		   NSStringFromClass([self class]),
		   self,
		   name];
    }
      
  if ([adaptorClass isSubclassOfClass: [self class]] == NO)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"%@ -- %@ 0x%x: principal class is not a subclass of EOAdaptor:%@",
		   NSStringFromSelector(_cmd),
		   NSStringFromClass([self class]),
		   self,
		   NSStringFromClass([adaptorClass class])];
    }

  return AUTORELEASE([[adaptorClass alloc] initWithName: name]);
}

+ (void)setExpressionClassName: (NSString *)sqlExpressionClassName
              adaptorClassName: (NSString *)adaptorClassName
{
  // TODO
  [self notImplemented: _cmd];
}

+ (EOLoginPanel *)sharedLoginPanelInstance
{
  static NSMutableDictionary *panelDict = nil;
  NSString     *name;
  EOLoginPanel *panel = nil;

  if ([self isMemberOfClass: [EOAdaptor class]] == NO)
    {
      if (panelDict == nil)
	{
	  panelDict = [NSMutableDictionary new];
	}

      name = NSStringFromClass(self);
      panel = [panelDict objectForKey: name];

      if (panel == nil
	  && NSClassFromString(@"NSApplication") != nil)
	{
	  NSBundle *adaptorFramework;
	  NSBundle *loginBundle;
	  NSString *path;
	  Class     loginClass;
	  
	  adaptorFramework = [NSBundle bundleForClass: self];
	  path = [adaptorFramework pathForResource: @"LoginPanel"
				   ofType: @"bundle"];
	  loginBundle = [NSBundle bundleWithPath: path];
	  loginClass = [loginBundle principalClass];
	  panel = [loginClass new];
	  if (panel != nil)
	    {
	      [panelDict setObject: panel forKey: name];
	    }
	}
    }
  
  return panel;
}

/**
 * Returns an array of EOAdaptor frameworks found in the standard
 * framework locations.  If an adaptor is found in multiple locations
 * the name is listed only once.  An adaptor framework is recognized
 * the the "EOAdaptor.framework" suffix.  The framework name without
 * this suffix is the name returned in the array.
 */
+ (NSArray *)availableAdaptorNames
{
  NSArray	 *pathArray =  NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory,
                                                             NSAllDomainsMask, YES);
  NSEnumerator	 *pathEnum = [pathArray objectEnumerator];
  NSString	 *searchPath;
  NSFileManager  *defaultManager = [NSFileManager defaultManager];
  NSArray	 *fileNames;
  NSEnumerator	 *filesEnum;
  NSString	 *fileName;
  NSMutableSet   *adaptorNames = [NSMutableSet set];
  NSString       *adaptorSuffix = @"EOAdaptor.framework";
  
  EOFLOGObjectFnStartOrCond2(@"AdaptorLevel", @"EOAdaptor");

  while ((searchPath = [pathEnum nextObject]))
    {
      searchPath = [searchPath stringByAppendingPathComponent: @"Frameworks"];
      fileNames = [defaultManager directoryContentsAtPath: searchPath];
      filesEnum = [fileNames objectEnumerator];
    

    
      while ((fileName = [filesEnum nextObject]))
	{
	
	  if ([fileName hasSuffix: adaptorSuffix])
	    {
	      fileName = [fileName stringByDeletingSuffix: adaptorSuffix];
	      [adaptorNames addObject: fileName];
	    }
	}
    }

  EOFLOGObjectFnStopOrCond2(@"AdaptorLevel", @"EOAdaptor");
  
  return [adaptorNames allObjects];
}

- (void)_performAdministativeStatementsForSelector: (SEL)sel
			      connectionDictionary: (NSDictionary *)connDict
		administrativeConnectionDictionary: (NSDictionary *)admConnDict
{

  if (admConnDict == nil)
    {
      admConnDict 
	= [[[self class] sharedLoginPanelInstance]
	    administrativeConnectionDictionaryForAdaptor: self];
    }

  if (connDict == nil)
    {
      connDict = [self connectionDictionary];
    }

  if (admConnDict != nil)
    {
      EOAdaptor        *admAdaptor;
      EOAdaptorContext *admContext;
      EOAdaptorChannel *admChannel;
      NSArray          *stmts;
      unsigned i;

      stmts = [(id)[self expressionClass] performSelector: sel
					  withObject: connDict
					  withObject: admConnDict];

      /*TODO: check if we need a model. */
      admAdaptor = [EOAdaptor adaptorWithName: [self name]];
      [admAdaptor setConnectionDictionary: admConnDict];

      admContext = [admAdaptor createAdaptorContext];
      admChannel = [admContext createAdaptorChannel];
      NS_DURING
	{
          unsigned stmtsCount=0;
	  [admChannel openChannel];
          stmtsCount=[stmts count];
	  for (i = 0; i < stmtsCount; i++)
	    {
	      [admChannel evaluateExpression: [stmts objectAtIndex: i]];
	    }
	  [admChannel closeChannel];
	}
      NS_HANDLER
	{
	  if ([admChannel isOpen])
	    {
	      [admChannel closeChannel];
	    }
	  [localException raise];
	}
      NS_ENDHANDLER;
    }
}


- (NSArray *)prototypeAttributes
{
  NSBundle *bundle;
  NSString *path;
  NSString *modelName;
  EOModel *model;
  NSMutableArray *attributes = nil;



  bundle = [NSBundle bundleForClass: [self class]];

  modelName = [NSString stringWithFormat: @"EO%@Prototypes.eomodeld", _name];
  path = [[bundle resourcePath] stringByAppendingPathComponent: modelName];

  model = [[EOModel alloc] initWithContentsOfFile: path];

  if (model)
    {
      NSArray *entities;
      unsigned i, count;

      attributes = [NSMutableArray arrayWithCapacity: 20];

      entities = [model entities];
      count = [entities count];

      for (i = 0; i < count; i++)
	{
	  EOEntity *entity = [entities objectAtIndex: i];

	  [attributes addObjectsFromArray: [entity attributes]];
	}

      RELEASE(model);
    }



  return attributes;
}

- initWithName:(NSString *)name
{
  if ((self = [super init]))
    {
      ASSIGN(_name, name);
      _contexts = [NSMutableArray new];
    }

  return self;
}

- (void)dealloc
{
  DESTROY(_model);
  DESTROY(_name);
  DESTROY(_connectionDictionary);
  DESTROY(_contexts);

  [super dealloc];
}

- (void)setConnectionDictionary: (NSDictionary *)dictionary
{
  //OK
  if ([self hasOpenChannels])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: cannot set the connection dictionary while the adaptor is connected!",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  ASSIGN(_connectionDictionary, dictionary);
//    [model setConnectionDictionary:dictionary]; // TODO ??
}

- (void)assertConnectionDictionaryIsValid
{
  return;
}

- (EOAdaptorContext *)createAdaptorContext
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (NSArray *)contexts
{
  SEL sel = @selector(nonretainedObjectValue);
  return [_contexts resultsOfPerformingSelector: sel];
}

- (BOOL)hasOpenChannels
{
  unsigned i;

  i = [_contexts count];
  while (i--)
    {
      EOAdaptorContext *ctx 
	= [[_contexts objectAtIndex: i] nonretainedObjectValue];

      if([ctx hasOpenChannels] == YES)
	return YES;
    }

  return NO;
}

- (void)setDelegate:delegate
{
  _delegate = delegate;

  _delegateRespondsTo.processValue
    = [delegate respondsToSelector:
		  @selector(adaptor:fetchedValueForValue:attribute:)];
}

- (void)setModel: (EOModel *)model
{
  ASSIGN(_model, model);
}

- (NSString *)name
{
  return _name;
}

- (NSDictionary *)connectionDictionary
{
  return _connectionDictionary;
}

- (EOModel *)model
{
  return _model;
}

- delegate
{
  return _delegate;
}

- (Class)expressionClass
{
  Class expressionClass = Nil;


/* retrieve EOAdaptorQuotesExternalNames from ? or from user default */

  expressionClass = _expressionClass;

  if(!expressionClass)
    expressionClass = [self defaultExpressionClass];



  return expressionClass;
}

- (Class)defaultExpressionClass 
{
  [self subclassResponsibility: _cmd];
  return Nil; //TODO vedere setExpressionClass
}

- (BOOL)canServiceModel: (EOModel *)model
{
  return [_connectionDictionary isEqual: [model connectionDictionary]];
}

- (NSStringEncoding)databaseEncoding
{
  NSString         *encodingValue;
  NSStringEncoding  stringEncoding;
  
  encodingValue = [[self connectionDictionary] objectForKey: @"databaseEncoding"];
  
  if (encodingValue == nil)
  {
    stringEncoding = [NSString defaultCStringEncoding];
  } else {
    // + GSMimeDocument encodingFromCharset should be in NSString Additions,
    // but better there than in GSWeb and GDL -- dw
    stringEncoding = [GSMimeDocument encodingFromCharset:encodingValue];
    
    if (stringEncoding == 0) {
      return [NSString defaultCStringEncoding];
    }
  }
  
  return stringEncoding;
}

- (id)fetchedValueForValue: (id)value
                 attribute: (EOAttribute *)attribute
{
  //Should be OK
  SEL valueFactoryMethod;

  valueFactoryMethod = [attribute valueFactoryMethod];

  if (valueFactoryMethod)
    {
      NSEmitTODO();  
      [self notImplemented: _cmd]; //TODO
    }
  else
    {
      if ([value isKindOfClass: [NSString class]])
        [self fetchedValueForStringValue: value
              attribute: attribute];
      else if ([value isKindOfClass: [NSNumber class]])
        value = [self fetchedValueForNumberValue: value
                      attribute: attribute];
      else if ([value isKindOfClass: [NSDate class]])
        value = [self fetchedValueForDateValue: value
                      attribute: attribute];
      else if ([value isKindOfClass: [NSData class]])
        value = [self fetchedValueForDataValue: value
                      attribute: attribute];
    }

  if(_delegateRespondsTo.processValue)
    value = [_delegate adaptor: self
                       fetchedValueForValue: value
                       attribute: attribute];


  return value;
}

- (NSString *)fetchedValueForStringValue: (NSString *)value
                               attribute: (EOAttribute *)attribute
{
  NSString *resultValue = nil;
    
  if([value length]>0)
    {
      //TODO-NOW: correct this code which loop!
      /*
      const char *cstr=NULL;
      unsigned i=0, spc=0;
      cstr = [value cString];
      while(*cstr)
        {
          if(*cstr == ' ')
            spc++;
          else
            spc = 0;
          i++;
        }
      cstr = &cstr[-i];
      
      if(!spc)
        resultValue=value;
      else if(!(&cstr[i-spc]-cstr))
        resultValue=nil;
      else
      resultValue=[NSString stringWithCString:cstr
                            length:&cstr[i-spc]-cstr];
      */
      resultValue = value;
    }



  return resultValue;
}

- (NSNumber *)fetchedValueForNumberValue: (NSNumber *)value
                               attribute: (EOAttribute *)attribute
{
  return value;
}

- (NSCalendarDate *)fetchedValueForDateValue: (NSCalendarDate *)value
                                   attribute: (EOAttribute *)attribute
{
  return value;
}

- (NSData *)fetchedValueForDataValue: (NSData *)value
                           attribute: (EOAttribute *)attribute
{
  return value;
}

/* Reconnection to database */
- (void)handleDroppedConnection
{
  NSDictionary *newConnectionDictionary = nil;
  NSUInteger i;
  
  for (i = 0; i < [_contexts count]; i++)
    {
      EOAdaptorContext *ctx = [[_contexts objectAtIndex:i]
				nonretainedObjectValue];

      [ctx handleDroppedConnection];
    }
  
  [_contexts removeAllObjects];
  
  if (_delegate
      && [_delegate
	   respondsToSelector: @selector(reconnectionDictionaryForAdaptor:)])
    {
      if ((newConnectionDictionary = [_delegate
				       reconnectionDictionaryForAdaptor: self]))
	{
	  [self setConnectionDictionary: newConnectionDictionary];
	}
    }
}

/**
 * Returns YES if the exception is one that the adaptor can attempt to recover from by reconnecting.
 * NO otherwise.
 * The default implementation returns NO.
 *
 * Subclasses that support database reconnection should override this
 * to allow for automatic database reconnection.
 */

- (BOOL)isDroppedConnectionException: (NSException *)exception
{
  return NO;
}
 
/**
 * Attempts to create a database using 
 * the statments returned by the Adaptor's expression class
 * for @selector(createDatabaseStatementsForConnectionDictionary:administrativeConnectionDictionary:);
 * using the connectionDictionary as the administrative connection dictionary. 
 */
- (void)createDatabaseWithAdministrativeConnectionDictionary: (NSDictionary *)connectionDictionary
{
  SEL sel;
  sel = @selector(createDatabaseStatementsForConnectionDictionary:administrativeConnectionDictionary:);
  [self _performAdministativeStatementsForSelector: sel
	connectionDictionary: [self connectionDictionary]
	administrativeConnectionDictionary: connectionDictionary];
}

/**
 * Attempts to drop a database using 
 * the statments returned by the Adaptor's expression class
 * for @selector(dropDatabaseStatementsForConnectionDictionary:administrativeConnectionDictionary:);
 * using the connectionDictionary as the administrative connection dictionary. 
 */
- (void)dropDatabaseWithAdministrativeConnectionDictionary: (NSDictionary *)connectionDictionary
{
  SEL sel;
  sel = @selector(dropDatabaseStatementsForConnectionDictionary:administrativeConnectionDictionary:);
  [self _performAdministativeStatementsForSelector: sel
        connectionDictionary: [self connectionDictionary]
        administrativeConnectionDictionary: connectionDictionary];
}

- (BOOL) isValidQualifierType: (NSString *)attribute
			model: (EOModel *)model
{
  [self subclassResponsibility: _cmd];
  return NO;
}

@end /* EOAdaptor */


@implementation EOAdaptor (EOAdaptorLoginPanel)

/**
 * Invokes [EOLoginPanel-runPanelForAdaptor:validate:allowsCreation:]
 * for the adaptor's [+sharedLoginPanelInstance],
 * with YES as the validate flag.
 * If the user supplies valid connection information,
 * the reciever's connection dictionary is updated,
 * and the method return YES.  Otherwise it returns NO.
 * Subclass shouldn't need to override this method,
 * yet if the do, they should call this implementation.
 */
- (BOOL)runLoginPanelAndValidateConnectionDictionary
{
  EOLoginPanel *panel;
  NSDictionary *connDict;

  panel = [[self class] sharedLoginPanelInstance];
  connDict = [panel runPanelForAdaptor: self
		    validate: YES
		    allowsCreation: NO];
  if (connDict != nil)
    {
      [self setConnectionDictionary: connDict];
    }

  return (connDict != nil ? YES : NO);
}

/**
 * Invokes [EOLoginPanel-runPanelForAdaptor:validate:allowsCreation:]
 * for the adaptor's [+sharedLoginPanelInstance],
 * with YES as the validate flag.
 * Returns the dictionary without
 * changing the recievers connection dictionary.
 * Subclass shouldn't need to override this method,
 * yet if the do, they should call this implementation.
 */
- (NSDictionary *)runLoginPanel
{
  EOLoginPanel *panel;
  NSDictionary *connDict;

  panel = [[self class] sharedLoginPanelInstance];
  connDict = [panel runPanelForAdaptor: self
		    validate: NO
		    allowsCreation: NO];

  return connDict;
}

@end

@implementation EOAdaptor (EOExternalTypeMapping)

/**
 * Subclasses must override this method without invoking this implementation
 * to return the name of the class used internal to the database
 * for the extType provided.  
 * A subclass may use information provided by
 * an optional model to determine the exact type.
 */
+ (NSString *)internalTypeForExternalType: (NSString *)extType
				    model: (EOModel *)model
{
  [self subclassResponsibility: _cmd];
  return nil;
}

/**
 * Subclasses must override this method without invoking this implementation
 * to return an array of types available for the RDBMS.
 * A subclass may use information provided by
 * an optional model to determine the exact available types.
 */
+ (NSArray *)externalTypesWithModel: (EOModel *)model
{
  [self subclassResponsibility: _cmd];
  return nil;
}

/**
 * Subclasses must override this method without invoking this implementation
 * to set the the external type according to the internal type information.
 * It should take into account width, precesion and scale accordingly.
 */
+ (void)assignExternalTypeForAttribute: (EOAttribute *)attribute
{
  [self subclassResponsibility: _cmd];
}

/**
 * Invokes [+assignExternalTypeForAttribute:] 
 * and unless the attribute is derived
 * it sets the column name if it hasn't been set.  
 * An 'attributeName' result in a column named 'ATTRIBUTE_NAME'.  <br/>
 * NOTE: This differs from the EOF implementation as EOF unconditionally
 * sets the the external name attributes that are not derived.
 * This can cause trouble on certain RDMS which may not support
 * the extended names used internally in an application.
 * Subclass shouldn't need to override this method,
 * yet if the do, they should call this implementation.
 */
+ (void)assignExternalInfoForAttribute: (EOAttribute *)attribute
{
  if ([[attribute columnName] length] == 0
      && [attribute isFlattened] == NO)
    {
      NSString *name;
      name = [NSString externalNameForInternalName: [attribute name] 
		       separatorString: @"_"
		       useAllCaps: YES];
      [attribute setColumnName: name];
    }

  [self assignExternalTypeForAttribute: attribute];
}

/**
 * Invokes [+assignExternalInfoForAttribute:]
 * for each of the model's entities. 
 * If the externalName of the entity hasn't been set,
 * this method sets it to a standardized name
 * according to the entities name.  
 * An 'entityName' will be converted to 'ENTITY_NAME'. <br/>
 * Subclass shouldn't need to override this method,
 * yet if the do, they should call this implementation.
 */
+ (void)assignExternalInfoForEntity: (EOEntity *)entity
{
  NSArray  *attributes=nil;
  unsigned i=0;
  unsigned attributesCount=0;

  if ([[entity externalName] length] == 0)
    {
      NSString *name;
      name = [NSString externalNameForInternalName: [entity name] 
		       separatorString: @"_"
		       useAllCaps: YES];
      [entity setExternalName: name];
    }

  attributes = [entity attributes];
  attributesCount=[attributes count];

  for (i = 0; i < attributesCount; i++)
    {
      [self assignExternalInfoForAttribute: [attributes objectAtIndex: i]];
    }
}

/**
 * Invokes [+assignExternalInfoForEntity:]
 * for each of the model's entities. 
 * Subclass shouldn't need to override this method,
 * yet if the do, they should call this implementation.
 */
+ (void)assignExternalInfoForEntireModel: (EOModel *)model
{
  NSArray  *entities=nil;
  unsigned i=0;
  unsigned entitiesCount=0;

  entities = [model entities];
  entitiesCount=[entities count];

  for (i = 0; i < entitiesCount; i++)
    {
      [self assignExternalInfoForEntity: [entities objectAtIndex: i]];
    }
}

@end


@implementation EOAdaptor (EOAdaptorPrivate)

- (void) _requestConcreteImplementationForSelector: (SEL)param0
{
  [self notImplemented: _cmd]; //TODO
}

- (void) _unregisterAdaptorContext: (EOAdaptorContext*)adaptorContext
{
  NSUInteger i = 0;    

  for (i = 0; i < [_contexts count]; i++)
    {
      if ([[_contexts objectAtIndex: i] nonretainedObjectValue]
	  == adaptorContext)
        {
	  // this works, since it breaks out on first find
	  [_contexts removeObjectAtIndex: i];
	  break;
        }
    }
}

- (void) _registerAdaptorContext: (EOAdaptorContext*)adaptorContext
{
  [_contexts addObject: [NSValue valueWithNonretainedObject: adaptorContext]];
}

@end

@implementation EOLoginPanel

- (NSDictionary *) runPanelForAdaptor: (EOAdaptor *)adaptor 
			     validate: (BOOL)yn 
		       allowsCreation: (BOOL)allowsCreation
{
  [self subclassResponsibility: _cmd];
  return nil;
}
/** 
   Subclasses should implement this method to return a connection dictionary
   for an administrative user able to create databases etc. Or nil if the  
   the user cancels.
*/
- (NSDictionary *) administrativeConnectionDictionaryForAdaptor: (EOAdaptor *)adaptor
{
  [self subclassResponsibility: _cmd];
  return nil;
}

@end

@implementation EOLoginPanel (Deprecated)

- (NSDictionary *) runPanelForAdaptor: (EOAdaptor *)adaptor validate: (BOOL)yn
{
  return [self runPanelForAdaptor: adaptor validate: yn allowsCreation: NO];
}

@end

