/** 
   EOAdaptor.m <title>EOAdaptor Class</title>

   Copyright (C) 1996-2001 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>
   Date: October 1996

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

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

#if HAVE_LIBC_H
# include <libc.h>
#else
#ifndef __WIN32__
# include <unistd.h>
#endif /* !__WIN32__ */
#endif

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <GNUstepBase/Unicode.h>


#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOAdaptorPriv.h>
#include <EOAccess/EOAdaptorContext.h>
#include <EOAccess/EOAdaptorChannel.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOSQLExpression.h>


NSString *EOGeneralAdaptorException = @"EOGeneralAdaptorException";


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
          Class adaptorClass = NSClassFromString([NSString stringWithFormat: @"%@%@", adaptorName, @"Adaptor"]);

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

+ (id) adaptorWithName: (NSString *)adaptorName
{
  //OK
  NSBundle *bundle = [NSBundle mainBundle];
  NSString *adaptorBundlePath;
  NSMutableArray *paths;
  Class adaptorClass;
  NSString *adaptorClassName;
  NSProcessInfo *pInfo;
  NSDictionary *env;
  NSMutableString *user, *local, *system;
  int i, count;

  /* Check error */
  if ([adaptorName length] == 0)
    [NSException raise: NSInvalidArgumentException
		 format: @"%@ -- %@ 0x%x: adaptor name can't be nil",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];
  
  // append EOAdaptor
  adaptorName = [adaptorName stringByAppendingString: @"EOAdaptor"];

  /* Look in application bundle */
  adaptorBundlePath = [bundle pathForResource: adaptorName
                              ofType: @"framework"];
  // should be NSString *path=[NSBundle pathForLibraryResource:libraryResource  type:@"framework"  directory:@"Frameworks"]; ?

  /* Look in standard paths */
  if (!adaptorBundlePath)
    {
      /*
	The path of where to search for the adaptor files
	is based upon environment variables.
	GDL_ADAPTORS_PATH
	GNUSTEP_USER_ROOT
	GNUSTEP_LOCAL_ROOT
	GNUSTEP_SYSTEM_ROOT
      */
      pInfo = [NSProcessInfo processInfo];
      env = [pInfo environment];
      paths = [NSMutableArray array];

      user = AUTORELEASE([[env objectForKey: @"GNUSTEP_USER_ROOT"] 
			   mutableCopy]);
      [user appendString: @"/Libraries/Frameworks"];

      if (user)
	[paths addObject: user];

      local = AUTORELEASE([[env objectForKey: @"GNUSTEP_LOCAL_ROOT"]
			    mutableCopy]);
      [local appendString: @"/Libraries/Frameworks"];

      if (local)
	[paths addObject: local];

      local = AUTORELEASE([[env objectForKey: @"GNUSTEP_LOCAL_ROOT"]
         mutableCopy]);
      [local appendString: @"/Library/Frameworks"];

      if (local)
	[paths addObject: local];

      system = AUTORELEASE([[env objectForKey: @"GNUSTEP_SYSTEM_ROOT"]
		  mutableCopy]);
      [system appendString: @"/Libraries/Frameworks"];

      if (system)
	[paths addObject: system];

      /* Loop through the paths and check each one */
      for(i = 0, count = [paths count]; i < count; i++)
        {
	  bundle = [NSBundle bundleWithPath: [paths objectAtIndex: i]];
	  adaptorBundlePath = [bundle pathForResource: adaptorName
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
                 adaptorName];
  
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
		   adaptorName];
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

  return AUTORELEASE([[adaptorClass alloc] initWithName: adaptorName]);
}

+ (void)setExpressionClassName: (NSString *)sqlExpressionClassName
              adaptorClassName: (NSString *)adaptorClassName
{
  // TODO
  [self notImplemented: _cmd];
}

+ (EOLoginPanel *)sharedLoginPanelInstance
{
  // TODO
  [self notImplemented: _cmd];
  return nil;
}

+ (NSArray *)availableAdaptorNames
{
  NSArray	 *pathArray = NSStandardLibraryPaths();
  NSEnumerator	 *pathEnum = [pathArray objectEnumerator];
  NSString	 *searchPath;
  NSFileManager  *defaultManager = [NSFileManager defaultManager];
  NSArray	 *fileNames;
  NSEnumerator	 *filesEnum;
  NSString	 *fileName;
  NSMutableArray *adaptorNames = AUTORELEASE([NSMutableArray new]);
  
  EOFLOGObjectFnStartOrCond2(@"AdaptorLevel", @"EOAdaptor");

  while ((searchPath = [pathEnum nextObject]))
    {
      fileNames = [defaultManager
		    directoryContentsAtPath:
		      [searchPath stringByAppendingPathComponent:@"Frameworks"]];
      filesEnum = [fileNames objectEnumerator];
    
      //NSLog(@"EOAdaptor : availableAdaptorNames, path = %@", searchPath);
    
      while ((fileName = [filesEnum nextObject]))
	{
	  //NSLog(@"EOAdaptor : availableAdaptorNames, fileName = %@", fileName);
	  if ([fileName hasSuffix:@"EOAdaptor.framework"]) {
	    [adaptorNames addObject:
			    [fileName substringToIndex: 
					([fileName length]
					 - [@"EOAdaptor.framework" length])]];
	  }
	}
    }

  EOFLOGObjectFnStopOrCond2(@"AdaptorLevel", @"EOAdaptor");
  
  return adaptorNames;
}

- (NSArray *)prototypeAttributes
{
  NSBundle *bundle;
  NSString *path;
  NSString *modelName;
  EOModel *model;
  NSMutableArray *attributes = nil;

  EOFLOGObjectFnStart();

  bundle = [NSBundle bundleForClass: [self class]];

  modelName = [NSString stringWithFormat: @"EO%@Prototypes.eomodeld", _name];
  path = [[bundle resourcePath] stringByAppendingPathComponent: modelName];

  model = [[EOModel alloc] initWithContentsOfFile: path];

  if (model)
    {
      NSArray *entities;
      int i, count;

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

  EOFLOGObjectFnStop();

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
  int i;

  for (i = [_contexts count] - 1; i >= 0; i--)
    {
      EOAdaptorContext *ctx = [[_contexts objectAtIndex: i]
				nonretainedObjectValue];

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

  EOFLOGObjectFnStart();
/* retrieve EOAdaptorQuotesExternalNames from ? or from user default */

  expressionClass = _expressionClass;

  if(!expressionClass)
    expressionClass = [self defaultExpressionClass];

  EOFLOGObjectFnStop();

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
  NSString	   *encodingString=nil;
  NSDictionary	   *encodingsDict = [self connectionDictionary];
  const NSStringEncoding *availableEncodingsArray;
  int		    count = 0;
  NSStringEncoding  availableEncodingValue;
  NSString	   *availableEncodingString;
  
  EOFLOGObjectFnStartOrCond2(@"AdaptorLevel",@"EOAdaptor");
  
  if (encodingsDict
      && (encodingString = [encodingsDict objectForKey: @"databaseEncoding"]))
    {
      availableEncodingsArray = [NSString availableStringEncodings];
    
      while (availableEncodingsArray[count] != 0)
	{
	  availableEncodingValue = availableEncodingsArray[count++];

	  availableEncodingString = GSEncodingName(availableEncodingValue);

	  if (availableEncodingString)
	    {
	      if ([availableEncodingString isEqual: encodingString])
		{
		  EOFLOGObjectFnStopOrCond2(@"AdaptorLevel", @"EOAdaptor");

		  return availableEncodingValue;
		}
	    }
	}
    }

  EOFLOGObjectFnStopOrCond2(@"AdaptorLevel", @"EOAdaptor");

  return [NSString defaultCStringEncoding];
}

- (id)fetchedValueForValue: (id)value
                 attribute: (EOAttribute *)attribute
{
  //Should be OK
  SEL valueFactoryMethod;

  EOFLOGObjectFnStart();
  EOFLOGObjectLevelArgs(@"gsdb", @"value=%@", value);
  EOFLOGObjectLevelArgs(@"gsdb", @"attribute=%@", attribute);

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

      EOFLOGObjectLevelArgs(@"gsdb",@"value=%@",value);
    }

  if(_delegateRespondsTo.processValue)
    value = [_delegate adaptor: self
                       fetchedValueForValue: value
                       attribute: attribute];

  EOFLOGObjectLevelArgs(@"gsdb", @"value=%@", value);
  EOFLOGObjectFnStop();

  return value;
}

- (NSString *)fetchedValueForStringValue: (NSString *)value
                               attribute: (EOAttribute *)attribute
{
  NSString *resultValue = nil;

  EOFLOGObjectFnStart();
  EOFLOGObjectLevelArgs(@"gsdb", @"value=%@", value);
  EOFLOGObjectLevelArgs(@"gsdb", @"attribute=%@", attribute);
    
  if([value length]>0)
    {
      //TODO-NOW: correct this code which loop!
      /*
      const char *cstr=NULL;
      int i=0, spc=0;
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

  EOFLOGObjectFnStop();

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
  int i;
  
  for (i = [_contexts count] - 1; i >= 0; i--)
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

- (BOOL)isDroppedConnectionException: (NSException *)exception
{
  EOFLOGObjectFnStartOrCond2(@"AdaptorLevel", @"EOAdaptor");
  EOFLOGObjectFnStopOrCond2(@"AdaptorLevel", @"EOAdaptor");

  return NO;
}
 
//NOT in EOF
- (void)createDatabaseWithAdministrativeConnectionDictionary: (NSDictionary *)connectionDictionary
{
  [self notImplemented: _cmd];
}

//NOT in EOF
- (void)dropDatabaseWithAdministrativeConnectionDictionary: (NSDictionary *)connectionDictionary
{
  [self notImplemented: _cmd];
}

- (BOOL) isValidQualifierType: (NSString *)attribute
			model: (EOModel *)model
{
  [self subclassResponsibility: _cmd];
  return NO;
}

@end /* EOAdaptor */


@implementation EOAdaptor (EOAdaptorLoginPanel)

- (BOOL)runLoginPanelAndValidateConnectionDictionary
{
  // TODO
  NSEmitTODO();  
  return NO;
}

- (NSDictionary *)runLoginPanel
{
  // TODO
  [self notImplemented: _cmd];
  return nil;
}

@end


@implementation EOAdaptor (EOExternalTypeMapping)

+ (NSString *)internalTypeForExternalType: (NSString *)extType
				    model: (EOModel *)model
{
  [self subclassResponsibility: _cmd];
  return nil;
}

+ (NSArray *)externalTypesWithModel: (EOModel *)model
{
  [self subclassResponsibility: _cmd];
  return nil;
}

+ (void)assignExternalTypeForAttribute: (EOAttribute *)attribute
{
  return;
}

+ (void)assignExternalInfoForAttribute: (EOAttribute *)attribute
{
  // TODO
  NSEmitTODO();  
  [self assignExternalTypeForAttribute: attribute];
}

+ (void)assignExternalInfoForEntity: (EOEntity *)entity
{
  // TODO
  [self notImplemented: _cmd];
}

+ (void)assignExternalInfoForEntireModel: (EOModel *)model
{
  // TODO
  [self notImplemented: _cmd];
}

@end


@implementation EOAdaptor (EOAdaptorPrivate)

- (void) _requestConcreteImplementationForSelector: (SEL)param0
{
  [self notImplemented: _cmd]; //TODO
}

- (void) _unregisterAdaptorContext: (EOAdaptorContext*)adaptorContext
{
  int i = 0;    

  for (i = [_contexts count] - 1; i >= 0; i--)
    {
      if ([[_contexts objectAtIndex: i] nonretainedObjectValue]
	  == adaptorContext)
        {
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

- (NSDictionary *) runPanelForAdaptor: (EOAdaptor *)adaptor validate: (BOOL)yn
{
  [self subclassResponsibility: _cmd];
  return nil;
}

- (NSDictionary *) administraticeConnectionDictionaryForAdaptor: (EOAdaptor *)adaptor
{
  [self subclassResponsibility: _cmd];
  return nil;
}

@end
