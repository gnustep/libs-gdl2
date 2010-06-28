/**
 CodeGenerator.m
 Created by David Wetzel on 16.11.2008.
 
 This file is part of EOModelEditor.
 
 <license>
 EOModelEditor is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.
 
 EOModelEditor is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with EOModelEditor; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 </license>
 **/

#import "CodeGenerator.h"
#import <Foundation/NSUserDefaults.h>
#import <EOAccess/EOEntity.h>
#import <EOAccess/EORelationship.h>
#import <EOAccess/EOAttribute.h>

#import <EOModeler/EOModelerApp.h>
#import <EOModeler/EOModelExtensions.h>


#import <AppKit/AppKit.h>



@implementation NSString (GeneratorAddtions)

// those 2 methods are from EOGenerator

/*-
 * Copyright (c) 2002-2006 Carl Lindberg and Mike Gentry
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION, HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

- (NSString *)initialCapitalString
{
  NSRange  firstLetterRange;
  NSString *firstLetterString;
  NSString *restOfString;
  
  if ([self length] == 0) return self;
  
  firstLetterRange  = [self rangeOfComposedCharacterSequenceAtIndex:0];
  firstLetterString = [[self substringWithRange:firstLetterRange] uppercaseString];
  restOfString      = [self substringFromIndex:NSMaxRange(firstLetterRange)];
  
  return [firstLetterString stringByAppendingString:restOfString];
}


- (NSString *)initialLowercaseString
{
  NSRange  firstLetterRange;
  NSString *firstLetterString;
  NSString *restOfString;
  
  if ([self length] == 0) return self;
  
  firstLetterRange  = [self rangeOfComposedCharacterSequenceAtIndex:0];
  firstLetterString = [[self substringWithRange:firstLetterRange] lowercaseString];
  restOfString      = [self substringFromIndex:NSMaxRange(firstLetterRange)];
  
  return [firstLetterString stringByAppendingString:restOfString];
}


@end


@implementation CodeGenerator


- (id) init
{
  self = [super init];
//  if (self != nil) {
//    NSUserDefaults *defs;
//    
//    defs = [NSUserDefaults standardUserDefaults];
//    _generatedClassPath = [defs stringForKey:GENERATED_CLASS_PATH];
//    _subclassPath = [defs stringForKey:SUBCLASS_PATH];
//    _superclassName = [defs stringForKey:SUPERCLASS_NAME];
//    
//  }
  return self;
}

- (NSString*) copyright
{
  return @"";
}

/*
 those are NOT added as '@class XXX;' lines to the _MyClass.h EO file.
 */

- (NSSet*) knownBaseClassNames
{
  return [NSSet setWithObjects:@"NSArray", @"NSNumber", @"NSDecimalNumber", @"NSCalendarDate", 
          @"NSData", @"NSString", nil];
}

- (NSMutableString*) interfacePrologueForEntity:(EOEntity*) entity
{
  NSMutableString * cs = [NSMutableString string];
  NSString        * copy = [self copyright];
  NSString        * className = [entity className];

  [cs appendFormat:@"// _%@.h\n", className];
  
  if ((copy != nil) && ([copy length])) {
    [cs appendString:copy];
  }

  [cs appendString:@"//\n"];
  [cs appendString:@"// Created by EOModelEditor.\n"];
  [cs appendFormat:@"// DO NOT EDIT. Make changes to %@.h instead.\n\n", className];
  [cs appendFormat:@"#ifndef ___%@_h_\n#define ___%@_h_\n\n", className, className];
  [cs appendString:@"#import <EOControl/EOControl.h>\n\n"];
  
  return cs;
}

- (NSMutableString*) superclassPrologueForEntity:(EOEntity*) entity
{
  NSMutableString * cs = [NSMutableString string];
  NSString        * copy = [self copyright];
  NSString        * className = [entity className];
  
  [cs appendFormat:@"// _%@.m\n", className];
  
  if ((copy != nil) && ([copy length])) {
    [cs appendString:copy];
  }
  
  [cs appendString:@"//\n"];
  [cs appendString:@"// Created by EOModelEditor.\n"];
  [cs appendFormat:@"// DO NOT EDIT. Make changes to %@.m instead.\n\n", className];
  [cs appendFormat:@"#import \"_%@.h\"\n", className];
  
  return cs;
}

- (NSString*) superInterfaceEpilogueForEntity:(EOEntity*) entity
{
  NSMutableString * cs = [NSMutableString string];
  NSString        * className = [entity className];
  
//  [cs appendString:@"// \n"];
  [cs appendFormat:@"#endif //___%@_h_\n", className];
  
  return cs;
}

- (NSString*) superclassEpilogueForEntity:(EOEntity*) entity
{
  return @"@end\n";
}


- (BOOL) updateNeededForFileAtPath:(NSString*) aPath content:(NSString*)aString canOverwrite:(BOOL) overwrite
{
  NSFileManager * fileManager = [NSFileManager defaultManager]; 
  
  if ([fileManager fileExistsAtPath:aPath]) {
    if (!overwrite) {
      return NO;
    }
    
    NSString * myStr = [NSString stringWithContentsOfFile:aPath
                                                 encoding:NSUTF8StringEncoding
                                                    error:NULL];
    
    if ([myStr isEqual:aString]) {
      return NO;
    }
    
    if (overwrite) {
      return YES;
    }
  }
    
  return YES;
}

void addToUsedClasses(NSMutableArray * mutArray,NSSet * knownNames, NSArray * otherArray)
{
  NSEnumerator   * enumer = [otherArray objectEnumerator];
  NSString       * className = nil;
  id               currentObj = nil;

  while ((currentObj = [enumer nextObject])) {
    
    if ([currentObj isKindOfClass:[NSString class]]) {
      className = currentObj;
    } else if ([currentObj isKindOfClass:[EORelationship class]]) {
      className = [[(EORelationship*) currentObj destinationEntity] className];
    } else if ([currentObj isKindOfClass:[EOAttribute class]]) {
      className = [(EOAttribute*) currentObj valueClassName];
    }
    
    if ((className) && ((([mutArray containsObject:className] == NO)) && ((!knownNames) || (([knownNames containsObject:className] == NO))))) {
      [mutArray addObject:className];
    } 
  }
  
}

- (NSString*) classDummysForEntity:(EOEntity*) entity
{
  NSSet           * knownNames = [self knownBaseClassNames];
  NSMutableString * ms = [NSMutableString string];
  NSEnumerator    * enumer = nil;
  NSString        * className = nil;

  NSArray * classNonScalarAttributes = [[entity classNonScalarAttributes] 
                                                sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray * classToOneRelationships = [[entity classToOneRelationships] 
                                               sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray * classToManyRelationships = [[entity classToManyRelationships] 
                                                sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSMutableArray * mutArray = [NSMutableArray array];
  
  addToUsedClasses(mutArray, knownNames, classNonScalarAttributes);
  addToUsedClasses(mutArray, knownNames, classToOneRelationships);
  addToUsedClasses(mutArray, knownNames, classToManyRelationships);
  
  enumer = [mutArray objectEnumerator];

  while ((className = [enumer nextObject])) {
    [ms appendFormat:@"@class %@;\n", className];
  }

  [ms appendFormat:@"\n"];

  return ms;
}

- (NSString*) superIncludesForEntity:(EOEntity*) entity
{
  NSSet           * knownNames = [self knownBaseClassNames];
  NSMutableString * ms = [NSMutableString string];
  NSEnumerator    * enumer = nil;
  NSString        * className = nil;
  
  NSArray * classNonScalarAttributes = [[entity classNonScalarAttributes] 
                                        sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray * classToOneRelationships = [[entity classToOneRelationships] 
                                       sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray * classToManyRelationships = [[entity classToManyRelationships] 
                                        sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSMutableArray * mutArray = [NSMutableArray array];
  
  addToUsedClasses(mutArray, knownNames, classNonScalarAttributes);
  addToUsedClasses(mutArray, knownNames, classToOneRelationships);
  addToUsedClasses(mutArray, knownNames, classToManyRelationships);
  
  enumer = [mutArray objectEnumerator];
  
  while ((className = [enumer nextObject])) {
    [ms appendFormat:@"#import \"%@.h\"\n", className];
  }
  
  [ms appendFormat:@"\n"];
  
  return ms;
}


- (NSString*) superInterfaceForEntity:(EOEntity*) entity
{
  
  NSMutableString * cs = [NSMutableString string];
  NSArray         * classScalarAttributes = [[entity classScalarAttributes] 
                                             sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray         * classNonScalarAttributes = [[entity classNonScalarAttributes] 
                                                sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray         * classToOneRelationships = [[entity classToOneRelationships] 
                                               sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray         * classToManyRelationships = [[entity classToManyRelationships] 
                                                sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  EOAttribute     * eoAttr = nil;
  EORelationship  * eoRel = nil;
  NSEnumerator    * enumer = [classScalarAttributes objectEnumerator];
  NSString        * className = [entity className];

  
  [cs appendString:[self classDummysForEntity:entity]];
  
  [cs appendFormat:@"@interface _%@ : EOCustomObject\n{\n", className];
  
  while ((eoAttr = [enumer nextObject])) {
    [cs appendFormat:@"  %@ _%@;\n", [eoAttr cScalarTypeString], [eoAttr name]];
  }
  
  enumer = [classNonScalarAttributes objectEnumerator];
  
  while ((eoAttr = [enumer nextObject])) {
    [cs appendFormat:@"  %@ *_%@;\n", [eoAttr valueClassName], [eoAttr name]];
  }
  
  enumer = [classToOneRelationships objectEnumerator];
  
  while ((eoRel = [enumer nextObject])) {
    [cs appendFormat:@"  %@ *_%@;\n", [[eoRel destinationEntity] className], [eoRel name]];
  }
  
  enumer = [classToManyRelationships objectEnumerator];
  
  while ((eoRel = [enumer nextObject])) {
    [cs appendFormat:@"  %@ *_%@s;\n", [[eoRel destinationEntity] className], [eoRel name]];
  }
  
  [cs appendFormat:@"}\n\n"];
  
    
  enumer = [classScalarAttributes objectEnumerator];
  
  
  while ((eoAttr = [enumer nextObject])) {
    [cs appendFormat:@"- (void) set%@:(%@) aValue;\n", [[eoAttr name] initialCapitalString],
     [eoAttr cScalarTypeString]];
    [cs appendFormat:@"- (%@) %@;\n\n", [eoAttr cScalarTypeString], [eoAttr name]];
  }
  
  enumer = [classNonScalarAttributes objectEnumerator];
  
  while ((eoAttr = [enumer nextObject])) {
    [cs appendFormat:@"- (void) set%@:(%@ *) aValue;\n", [[eoAttr name] initialCapitalString],
     [eoAttr valueClassName]];
    [cs appendFormat:@"- (%@ *) %@;\n\n", [eoAttr valueClassName], [eoAttr name]];
  }
  
  enumer = [classToOneRelationships objectEnumerator];
  
  while ((eoRel = [enumer nextObject])) {
    [cs appendFormat:@"- (void) set%@:(%@ *) aValue;\n", [[eoRel name] initialCapitalString],
     [[eoRel destinationEntity] className]];
    [cs appendFormat:@"- (%@ *) %@;\n\n", [[eoRel destinationEntity] className], [eoRel name]];
  }
  
  enumer = [classToManyRelationships objectEnumerator];
  
  while ((eoRel = [enumer nextObject])) {
    [cs appendFormat:@"- (NSArray *) %@;\n\n", [eoRel name]];
    [cs appendFormat:@"- (void) addTo%@:(%@ *) aValue;\n", [[eoRel name] initialCapitalString],
     [[eoRel destinationEntity] className]];
    [cs appendFormat:@"- (void) removeFrom%@:(%@ *) aValue;\n", [[eoRel name] initialCapitalString],
     [[eoRel destinationEntity] className]];
  }
  
  [cs appendFormat:@"@end\n\n"];

  return cs;
}

- (NSArray*) retainableAttributesInEntity:(EOEntity*) entity
{
  NSArray         * classNonScalarAttributes = [[entity classNonScalarAttributes] 
                                                sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray         * classToOneRelationships = [[entity classToOneRelationships] 
                                               sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray         * classToManyRelationships = [[entity classToManyRelationships] 
                                                sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSMutableArray * mutArray = [NSMutableArray array];
  NSEnumerator    * enumer;
  EORelationship  * eoRel;
  EOAttribute     * eoAttr;
  
  enumer = [classNonScalarAttributes objectEnumerator];
  
  while ((eoAttr = [enumer nextObject])) {
    [mutArray addObject:[[eoAttr name] initialLowercaseString]];
  }
  
  enumer = [classToOneRelationships objectEnumerator];
  
  while ((eoRel = [enumer nextObject])) {
    [mutArray addObject:[[eoRel name] initialLowercaseString]];
  }
  
  enumer = [classToManyRelationships objectEnumerator];
  
  while ((eoRel = [enumer nextObject])) {
    [mutArray addObject:[[eoRel name] initialLowercaseString]];
  }
  
  
  return mutArray;
}

- (NSString*) deallocForAttributes:(NSArray*) attrs
{
  NSMutableString * cs = [NSMutableString string];
  NSEnumerator    * enumer = [attrs objectEnumerator];
  NSString        * anIvar = nil;

  [cs appendFormat:@"\n- (void) dealloc\n{\n"];

  while ((anIvar = [enumer nextObject])) {
    [cs appendFormat:@"  [_%@ release];\n", anIvar];
  }

  [cs appendFormat:@"\n  [super dealloc];\n}\n\n"];
  
  return cs;
}

- (NSString*) superclassGettersAndSettersForEntity:(EOEntity*) entity
{
  
  NSMutableString * cs = [NSMutableString string];
  NSArray         * classScalarAttributes = [[entity classScalarAttributes] 
                                             sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray         * classNonScalarAttributes = [[entity classNonScalarAttributes] 
                                                sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray         * classToOneRelationships = [[entity classToOneRelationships] 
                                               sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  NSArray         * classToManyRelationships = [[entity classToManyRelationships] 
                                                sortedArrayUsingSelector:@selector(eoCompareOnName:)];
  
  EOAttribute     * eoAttr = nil;
  EORelationship  * eoRel = nil;
  NSEnumerator    * enumer = [classScalarAttributes objectEnumerator];
  
  enumer = [classScalarAttributes objectEnumerator];
  
  
  while ((eoAttr = [enumer nextObject])) {
    NSString * lowStr = [[eoAttr name] initialLowercaseString];
    
    [cs appendFormat:@"- (void) set%@:(%@) aValue\n{\n  if ((_%@ == aValue)) {\n    return;\n  }\n\n", 
     [[eoAttr name] initialCapitalString],
     [eoAttr cScalarTypeString], lowStr];

    [cs appendFormat:@"  [self willChange];\n  _%@ = aValue;\n}\n\n",
     lowStr];
    
    [cs appendFormat:@"- (%@) %@\n{\n  return _%@;\n}\n\n", [eoAttr cScalarTypeString], [eoAttr name], lowStr];
  }
  
  enumer = [classNonScalarAttributes objectEnumerator];
  
  while ((eoAttr = [enumer nextObject])) {
    NSString * lowStr = [[eoAttr name] initialLowercaseString];

    [cs appendFormat:@"- (void) set%@:(%@ *) aValue\n{\n  if ((_%@ == aValue)) {\n    return;\n  }\n\n", 
     [[eoAttr name] initialCapitalString],
     [eoAttr valueClassName], lowStr];

    [cs appendFormat:@"  [self willChange];\n  ASSIGN(_%@, aValue);\n}\n\n", 
     lowStr, lowStr];
    [cs appendFormat:@"- (%@ *) %@\n{\n  return _%@;\n}\n\n", [eoAttr valueClassName], [eoAttr name], lowStr];
  }
  
  
  if ([classToOneRelationships count]) {
    [cs appendString:@"// to-one relationships\n\n"];
  }
  
  enumer = [classToOneRelationships objectEnumerator];
  
  while ((eoRel = [enumer nextObject])) {
    NSString * lowStr = [[eoRel name] initialLowercaseString];

    [cs appendFormat:@"- (void) set%@:(%@ *) aValue\n{\n  if ((_%@ == aValue)) {\n    return;\n  }\n\n", 
     [[eoRel name] initialCapitalString],
     [[eoRel destinationEntity] className], lowStr];
    
    [cs appendFormat:@"  [self willChange];\n  ASSIGN(_%@, aValue);\n}\n\n", 
     lowStr, lowStr];
    [cs appendFormat:@"- (%@ *)%@\n{\n  return _%@;\n}\n\n", [[eoRel destinationEntity] className], [eoRel name], lowStr];
  }
  
  enumer = [classToManyRelationships objectEnumerator];
  
  while ((eoRel = [enumer nextObject])) {
    NSString * lowStr = [[eoRel name] initialLowercaseString];
    
    [cs appendFormat:@"- (NSArray *) %@\n{\n",
     [eoRel name]];
    [cs appendFormat:@"  return  _%@;\n}\n\n", 
     lowStr];

    [cs appendFormat:@"- (void) addTo%@:(%@ *) aValue\n{\n", [[eoRel name] initialCapitalString],
     [[eoRel destinationEntity] className]];
    
    [cs appendFormat:@"  [self willChange];\n  [_%@ addObject:aValue];\n}\n\n", 
     lowStr];
    
    [cs appendFormat:@"- (void) removeFrom%@:(%@ *) aValue\n{\n", [[eoRel name] initialCapitalString],
     [[eoRel destinationEntity] className]];
    [cs appendFormat:@"  [self willChange];\n  [_%@ removeObject:aValue];\n}\n\n", 
     lowStr];
  }
  
  
  return cs;
}

- (NSString*) superclassForEntity:(EOEntity*) entity
{
  NSMutableString * cs = [NSMutableString string];
  NSString        * className = [entity className];
  
  NSArray         * retainableAttrs = [self retainableAttributesInEntity:entity];
    
  [cs appendFormat:@"@implementation _%@\n", className];
  
  [cs appendString:[self deallocForAttributes:retainableAttrs]];
  
  [cs appendString:[self superclassGettersAndSettersForEntity:entity]];

  
  return cs;
}


- (void) generateSuperInterfaceFileForEntity:(EOEntity*) entity
{
  NSMutableString * codeString = [self interfacePrologueForEntity:entity];
  NSString        * path = _generatedClassPath;

  NSString * className = [entity className];
  NSString * currentPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"_%@.h", 
                                                                 className]];

  [codeString appendString:[self superInterfaceForEntity:entity]];
  
  [codeString appendString:[self superInterfaceEpilogueForEntity:entity]];
    
  if ([self updateNeededForFileAtPath:currentPath 
                              content:codeString 
                         canOverwrite:YES]) {
    
    [codeString writeToFile:currentPath 
                 atomically:NO 
                   encoding:NSUTF8StringEncoding
                      error:NULL];
    
  }
}

- (void) generateSubInterfaceFileForEntity:(EOEntity*) entity
{
  NSMutableString * codeString = [NSMutableString string];
  NSString        * path = _subclassPath;  
  NSString        * className = [entity className];
  NSString        * currentPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h",
                                                                        className]];
  
  [codeString appendFormat:@"// %@.h\n\n", className];
  [codeString appendFormat:@"#ifndef __%@_h_\n#define __%@_h_\n\n", className, className];
  [codeString appendFormat:@"#import \"_%@.h\"\n\n", className];
  
  [codeString appendFormat:@"@interface %@: _%@\n", className, className];
  [codeString appendString:@"{\n  // Custom instance variables go here\n}\n\n"];
  [codeString appendString:@"// Business logic methods go here\n\n@end\n"];
  [codeString appendFormat:@"\n#endif //__%@_h_\n", className];

  if ([self updateNeededForFileAtPath:currentPath 
                              content:codeString 
                         canOverwrite:NO]) {
    
    [codeString writeToFile:currentPath 
                 atomically:NO 
                   encoding:NSUTF8StringEncoding
                      error:NULL];
    
  }
}

- (void) generateSuperclassFileForEntity:(EOEntity*) entity
{
  NSMutableString * codeString = [self superclassPrologueForEntity:entity];
  NSString        * path = _generatedClassPath;
  
  
  NSString * className = [entity className];
  NSString * currentPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"_%@.m",
                                                                 className]];
  
  [codeString appendString:[self superIncludesForEntity:entity]];
  [codeString appendString:[self superclassForEntity:entity]];
  
  [codeString appendString:[self superclassEpilogueForEntity:entity]];
    
  if ([self updateNeededForFileAtPath:currentPath 
                              content:codeString 
                         canOverwrite:YES]) {
    
    [codeString writeToFile:currentPath 
                 atomically:NO 
                   encoding:NSUTF8StringEncoding
                      error:NULL];
    
  }
}

- (void) generateSubclassFileForEntity:(EOEntity*) entity
{
  NSMutableString * codeString = [NSMutableString string];
  NSString        * path = _subclassPath;  
  NSString * className = [entity className];
  NSString * currentPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m",
                                                                 className]];
  
  [codeString appendFormat:@"// %@.m\n\n#import \"%@.h\"\n\n", className, className];
  [codeString appendFormat:@"@implementation %@\n\n", className];
  [codeString appendString:@"- (void)dealloc\n{\n  [super dealloc];\n}\n\n"];
  [codeString appendString:@"// Business logic methods go here\n\n@end\n"];
  
  if ([self updateNeededForFileAtPath:currentPath 
                              content:codeString 
                         canOverwrite:NO]) {
    
    [codeString writeToFile:currentPath 
                 atomically:NO 
                   encoding:NSUTF8StringEncoding
                      error:NULL];
    
  }
}

- (BOOL) getPaths
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  
  BOOL ok = NO;
  
  [panel setTitle:@"Select path for super classes"];
  [panel setCanCreateDirectories:YES];
  [panel setCanChooseFiles:NO];
  [panel setCanChooseDirectories:YES];
  
  if ([panel runModal] == NSOKButton)
  {
    NSURL * url = [panel directoryURL];
    
    [_generatedClassPath release];
    _generatedClassPath = [[url path] retain];
    
    [panel setTitle:@"Select path for sub classes"];
    if ([panel runModal] == NSOKButton)
    {
      NSURL * suburl = [panel directoryURL];
      
      [_subclassPath release];
      _subclassPath = [[suburl path] retain];
      
      ok = YES;
    }
  }
  
  return ok;
}

- (void) generate
{
  NSEnumerator  * entityEnumer = nil;
  EOEntity      * currentEntity = nil;
  
  _model        = [[[NSDocumentController sharedDocumentController] currentDocument] eomodel];
  
  if (!_model) {
    return;
  }
  
  if ([self getPaths]) {
    
    entityEnumer = [[_model entities] objectEnumerator];
    
    while ((currentEntity = [entityEnumer nextObject])) {
      [self generateSuperInterfaceFileForEntity:currentEntity];
      [self generateSuperclassFileForEntity:currentEntity];
      [self generateSubInterfaceFileForEntity:currentEntity];
      [self generateSubclassFileForEntity:currentEntity];
    }
  }
}

- (void) dealloc
{
  [_generatedClassPath release];
  [_subclassPath release];
  //[_superclassName release];
  //[_model release];
  
  [super dealloc];
}

@end
