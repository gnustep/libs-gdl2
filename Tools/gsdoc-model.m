/* <title>This tool produce .gsdoc files from eomodel files</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Written by:	Manuel Guesdon <mguesdon@orange-concept.com>
   Created: August 2000

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

#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSCalendarDate.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOAccess/EOAccess.h>
#include "EOModel+GSDoc.h"


NSString *PathExtension_GSDoc = @"gsdoc";
NSString *PathExtension_EOModel = @"eomodeld";
NSString *PathExtension_Model = @"model";
int verbose = 0;

//--------------------------------------------------------------------
// In text, replace keys from variables with their values
// variables is like something like this
// {
//		"[[key1]]" = "value1";
//		"[[key2]]" = "value2";
// };

NSString *TextByReplacingVariablesInText(NSString *text,
					 NSDictionary *variables)
{
  NSEnumerator *variablesEnum = [variables keyEnumerator];
  id key;

  while ((key = [variablesEnum nextObject]))
    {
      id value = [variables objectForKey: key];

      text = [text stringByReplacingString: key
		   withString: [value description]];
    }

  return text;
}

//--------------------------------------------------------------------
// Return list of files found in dir (deep search) which have extension extension
NSArray *FilesInPathWithExtension(NSString *dir, NSString *extension)
{
  NSMutableArray *files = [NSMutableArray array];
  NSString *file = nil;
  NSFileManager *fm = [NSFileManager defaultManager];
  NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath: dir];  

  while ((file = [enumerator nextObject]))
    {
      BOOL isDirectory = NO;

      file = [dir stringByAppendingPathComponent: file];

      if ([[file pathExtension] isEqual: extension])
	{
	  if ([fm fileExistsAtPath: file isDirectory: &isDirectory])
	    {
	      if (!isDirectory)
		{
		  [files addObject: file];
		}
	    }
	}
    }

  return files;
}

//--------------------------------------------------------------------
int
main(int argc, char **argv, char **env)
{
  NSProcessInfo		*proc;
  NSArray		*args;
  unsigned		i;
  NSUserDefaults	*defs;
  NSMutableArray *files = nil;		// Files to parse
  NSString *templateFileName = nil;		// makeIndex template file name
  NSMutableDictionary *infoDictionary = nil;		// user info
  NSDictionary *variablesDictionary = nil;		// variables dictionary
  BOOL goOn = YES;
  BOOL splitByEntities = NO;
  NSFileManager *fileManager = nil;
  NSString              *documentationDirectory = nil;
  NSString              *declared = nil;
  NSString              *project = nil;
  BOOL                  generateHtml = YES;
  BOOL                  ignoreDependencies = NO;
  BOOL                  showDependencies = NO;
  id                    obj = nil;

  CREATE_AUTORELEASE_POOL(pool);

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments: argv count: argc environment: env];
#endif

  defs = [NSUserDefaults standardUserDefaults];
  [defs registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
					  @"Untitled", @"Project",
					nil]];

  verbose = [defs boolForKey: @"Verbose"];
  ignoreDependencies = [defs boolForKey: @"IgnoreDependencies"];
  showDependencies = [defs boolForKey: @"ShowDependencies"];

  if (ignoreDependencies == YES)
    {
      if (showDependencies == YES)
        {
          showDependencies = NO;
          NSLog(@"ShowDependencies(YES) used with IgnoreDependencies(YES)");
        }
    }

  obj = [defs objectForKey: @"GenerateHtml"];
  if (obj != nil)
    {
      generateHtml = [defs boolForKey: @"GenerateHtml"];
    }

  declared = [defs stringForKey: @"Declared"];
  project = [defs stringForKey: @"Project"];

  documentationDirectory = [defs stringForKey: @"DocumentationDirectory"];
  if (documentationDirectory == nil)
    {
      documentationDirectory = @"";
    }

  proc = [NSProcessInfo processInfo];
  if (proc == nil)
    {
      NSLog(@"unable to get process information!");
      goOn = NO;
    }

  fileManager = [NSFileManager defaultManager];
  if (goOn)
    {
      args = [proc arguments];

      // First, process arguments
      for (i = 1; goOn && i < [args count]; i++)
        {
          NSString *arg = [args objectAtIndex: i];

          // is this an option ?
          if ([arg hasPrefix: @"--"])
            {
              NSString *argWithoutPrefix = [arg stringByDeletingPrefix: @"--"];
              NSString *key = nil;
              NSString *value = nil;
              NSArray *parts = [argWithoutPrefix componentsSeparatedByString:
						   @"="];

              key = [parts objectAtIndex: 0];

              if ([parts count] > 1)
                value = [[parts subarrayWithRange:
				  NSMakeRange(1, [parts count] - 1)]
			  componentsJoinedByString: @"="];

              // projectName option
              if ([key isEqualToString: @"projectName"]
		  || [key isEqualToString: @"project"])
                {
                  project = value;
                  NSCAssert([project length], @"No project name");
                }
              // template option
              else if ([key isEqualToString: @"template"])
                {
                  templateFileName = value;
                  NSCAssert([templateFileName length], @"No template filename");
                }
              else if ([key isEqualToString: @"splitByEntities"])
                {
                  splitByEntities = [value boolValue];
                }
              // Verbose
              else if ([key hasPrefix: @"verbose"])
                {
                  NSCAssert1(value, @"No value for %@", key);

                  verbose = [value intValue];

                  if (verbose > 0)
                    {
                      NSMutableSet *debugSet = [proc debugSet];
                      [debugSet addObject: @"dflt"];
                    }
                }
              // define option
              else if ([key hasPrefix: @"define-"])
                {
                  if (!infoDictionary)
                    infoDictionary = (id)[NSMutableDictionary dictionary];

                  NSCAssert1(value, @"No value for %@", key);

                  [infoDictionary setObject: value
                                  forKey:
				    [key stringByDeletingPrefix: @"define-"]];
                }
              // DocumentationDirectory
              else if ([key hasPrefix: @"documentationDirectory"])
                {
                  if (!value)
                    value = @"";

                  documentationDirectory = value;
                }
/*              // unknown option
              else
                {
                  NSLog(@"Unknown option %@", arg);
                  goOn = NO;
                };*/
            }
          // file to parse
          else
            {
              if (!files)
                files = [NSMutableArray array];

              [files addObject: arg];
            }
        }
    }

  //Default Values
  if (goOn)
    {
      if (!project)
        project = @"unknown";
    }

  // Verify option compatibilities
  if (goOn)
    {
    }

  //Variables
  if (goOn)
    {		  
      NSMutableDictionary *variablesMutableDictionary =
	[NSMutableDictionary dictionary];
      NSEnumerator *enumer = [infoDictionary keyEnumerator];
      id key;

      while ((key = [enumer nextObject]))
        {
          id value = [infoDictionary objectForKey: key];

          [variablesMutableDictionary
	    setObject: value
	    forKey: [NSString stringWithFormat: @"[[infoDictionary.%@]]", key]];
        }

      [variablesMutableDictionary setObject: [NSCalendarDate calendarDate]
                                  forKey: @"[[timestampString]]"];

      if (project)
        [variablesMutableDictionary setObject: project
                                    forKey: @"[[projectName]]"];

      variablesDictionary = [[variablesMutableDictionary copy] autorelease];

      if (verbose >= 3)
        {
          NSEnumerator *enumer = [variablesDictionary keyEnumerator];
          id key;

          while ((key = [enumer nextObject]))
            {
              NSLog(@"Variables: %@=%@",
                    key,
                    [variablesDictionary objectForKey: key]);
            }
        }
    }

  // Find Files to parse
  if (goOn)
    {
      if ([files count] < 1)
        {
          NSLog(@"No file names given to parse.");
          goOn = NO;
        }
      else
        {
/*          NSMutableArray* tmpNewFiles=[NSMutableArray array];
          for (i=0;goOn && i<[files count];i++)
            {
              NSString* file = [files objectAtIndex: i];
              BOOL isDirectory=NO;
              if (![fileManager fileExistsAtPath:file isDirectory:&isDirectory])
                {
                  NSLog(@"File %@ doesn't exist",file);				  
                  goOn=NO;
                }
              else
                {
                  if (isDirectory)
                    {
                      NSArray* tmpFiles=FilesInPathWithExtension(file,PathExtension_EOModel);
                      [tmpNewFiles addObjectsFromArray:tmpFiles];
                      tmpFiles=FilesInPathWithExtension(file,PathExtension_Model);
                      [tmpNewFiles addObjectsFromArray:tmpFiles];
                    }
                  else
                    {
                      [tmpNewFiles addObject:file];
                    }
                }
            }
          files=tmpNewFiles;
          files=(NSMutableArray*)[files sortedArrayUsingSelector:@selector(compare:)];
          NSDebugLog(@"files=%@",files);
*/
        }
    }

  if (goOn)
    {
      NSString *textTemplate = [NSString stringWithContentsOfFile:
					   templateFileName];

      for (i = 0; goOn && i < [files count]; i++)
        {
          int xmlId = 0;
          NSString *file = [files objectAtIndex: i];
          NSAutoreleasePool *arp = [NSAutoreleasePool new];

          if (verbose >= 1)
            {
              NSLog(@"File %d/%d - Processing %@",
                    (i+1),
                    [files count],
                    file);
            }
          NS_DURING
            {
              EOModel *model;

//              model=[[[EOModel alloc]autorelease]initWithContentsOfFile:file];
              model = [[[EOModel alloc] initWithContentsOfFile: file]
			autorelease];

              if (model)
                {	  
                  NSString *gsdocModelContent = nil;
                  NSString *gsdocEntitiesContent = nil;
                  NSDictionary *entities = nil;

                  NSLog(@"Model %@ loaded", file);

                  gsdocModelContent = [model gsdocContentSplittedByEntities:
					       (splitByEntities
						? &entities : NULL)
					     idPtr: NULL/*&xmlId*/];//Debugging

                  if (gsdocModelContent == nil)
                    {
                      NSLog(@"File %d/%d - Error generating doc for %@",
                            (i+1),
                            [files count],
                            file);
                      goOn = NO;
                    }
                  else
                    {
                      int iGenerateDoc = 0;
                      int iGenerateCount = 0;
                      NSString *fileContent = nil;
                      NSString *baseFileName = nil;
                      NSString *fileName = nil;
                      NSMutableDictionary *variablesMutableDictionary = nil;
                      NSArray *entitiesNames = [[entities allKeys]
						 sortedArrayUsingSelector:
						   @selector(compare:)];
                      NSMutableString *entitiesIndex = [NSMutableString
							 stringWithString:
							   @"<list>\n"];

                      iGenerateCount = [entitiesNames count] + 1;
                      variablesMutableDictionary = [variablesDictionary
						     mutableCopy];

                      for (iGenerateDoc = 0;
			   iGenerateDoc < iGenerateCount;
			   iGenerateDoc++)
                        {
                          NSString *theFile = nil;
                          NSString *content = nil;

                          if (iGenerateDoc == (iGenerateCount - 1))
                            {
                              NSMutableDictionary *tmpVariablesMutableDictionary = nil;

                              theFile = file;
                              [entitiesIndex appendString: @"</list>\n"];
                              tmpVariablesMutableDictionary =
				[NSMutableDictionary dictionaryWithObjectsAndKeys:
						       entitiesIndex,
						     @"[[entities]]",
						     nil];
                              content = TextByReplacingVariablesInText(gsdocModelContent, tmpVariablesMutableDictionary);
                            }
                          else
                            {
                              NSString *entityName = [entitiesNames
						       objectAtIndex:
							 iGenerateDoc];

                              theFile = [NSString stringWithFormat: @"%@+%@",
						  [file stringByDeletingPathExtension],
						  entityName];
                              content = [entities objectForKey: entityName];
                              [entitiesIndex appendFormat:
					       @"<item><prjref file=\"%@\">%@</prjref></item>\n",
                                             theFile,
                                             entityName];
                            }

                          baseFileName = [theFile
					   stringByDeletingPathExtension];
                          fileName = [baseFileName
				       stringByAppendingPathExtension: PathExtension_GSDoc];
                          fileName = [documentationDirectory stringByAppendingPathComponent: fileName];

                          [variablesMutableDictionary setObject: fileName
                                                      forKey: @"[[fileName]]"];
                          [variablesMutableDictionary setObject: baseFileName
                                                      forKey:
							@"[[baseFileName]]"];
                          [variablesMutableDictionary setObject: content
                                                      forKey: @"[[content]]"];

                          fileContent = TextByReplacingVariablesInText(textTemplate, variablesMutableDictionary);
                          [fileContent writeToFile: fileName
                                       atomically: NO];
                        }

                      if (verbose >= 1)
                        {
                          NSLog(@"File %d/%d - Generating %@ - OK",
                                (i+1),
                                [files count],
                                file);
                        }
                    }
                }
              else
                {
                  NSLog(@"File %d/%d - Error parsing '%@'",
                        (i+1),
                        [files count],
                        file);
                  goOn = NO;
                }
            }
          NS_HANDLER
            {
              NSLog(@"File %d/%d - Parsing '%@' - %@",
                    (i+1),
                    [files count],
                    file,
                    [localException reason]);
              goOn = NO;
            }
          NS_ENDHANDLER;

	  DESTROY(arp);
        }
    }

  [pool release];

  return (goOn ? 0 : 1);
}
