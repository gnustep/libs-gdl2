/** -*-ObjC-*-
   SubclassFlags.h

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Matt Rice <ratmice@yahoo.com>

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 2, 
   or (at your option) any later version.

   The GNUstep Database Library is distributed in the hope that it will be 
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License 
   along with the GNUstep Database Library; see the file COPYING. If not, 
   write to the Free Software Foundation, Inc., 
   51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

/* 
   please be careful when adding stuff; as this is hideous.
   there is one section for every class directly desending from EOAssociation
   which includes flags from its subclasses.
 */
#define EnabledAspectMask	0x1

/* EOTableViewAssociation:5 (enabled, italic, source, textColor, bold) */
//	EnabledAspectMask	0x1
#define SourceAspectMask	0x2
#define ItalicAspectMask	0x4
#define TextColorAspectMask	0x8
#define BoldAspectMask		0x10

/* EOActionInsertionAssociation:3 (source, enabled, destination) */
// 	EnabledAspectMask	0x1
//	SourceAspectMask	0x2
#define DestinationAspectMask	0x4

/* EOActionAssociation:3 (action, enabled, argument) */
// 	EnabledAspectMask	0x1
#define ActionAspectMask	0x2
#define ArgumentAspectMask	0x4

/* EOColumnAssociation:2 (value, enabled) */
// 	EnabledAspectMask	0x1 
#define ValueAspectMask		0x2

/* EOGenericControlAssociation:3 (enabled, URL, value) */
//	EnabledAspectMask	0x1
//	ValueAspectMask		0x2 
#define URLAspectMask		0x4

/* EOTextAssociation:3 (editable, URL, value) */
//	EnabledAspectMask	0x1
//	ValueAspectMask		0x2 
#define EditableAspectMask	0x4


/* EORecursiveBrowserAssociation:4 (isLeaf, rootChildren, children, title) */
#define IsLeafAspectMask	0x1
#define RootChildrenAspectMask	0x2
#define	TitleAspectMask		0x4
#define ChildrenAspectMask	0x8

/* EODetailSelectionAssociation:1 (selectedObjects) */
#define SelectedObjectsAspectMask 0x1

/* EOMatrixAssociation:3 (enabled, title, image) */
//	EnabledAspectMask	0x1
#define ImageAspectMask 	0x2
//	TitleAspectMask		0x4

/* EOMasterCopyAssociation:1 (parent) */
/* EOMasterDetailAssociation:1 (parent) */
#define ParentAspectMask	0x1

/* EOPickTextAssociation:3 (matchKey2, matchKey3, matchKey1) */
#define MatchKey2AspectMask 0x1
#define MatchKey3AspectMask 0x2
#define MatchKey1AspectMask 0x4

/* EORadioMatrixAssociation:3 (enabled, selectedTitle, selectedTag) */
//	EnabledAspectMask	0x1
#define SelectedTitleAspectMask 0x2
#define SelectedTagAspectMask	0x4

/* EOComboBoxAssociation:4 (enabled, selectedObject, titles, selectedTitle) */
//	EnabledAspectMask	 0x1
// 	SelectedTitleAspectMask  0x2
#define SelectedObjectAspectMask 0x8
#define TitlesAspectMask	 0x10

/* EOPopUpAssociation:5 (enabled, selectedTag, selectedObject, titles, selectedTitle) */
//	EnabledAspectMask	 0x1
// 	SelectedTitleAspectMask  0x2
//	SelectedTagAspectMask	 0x4
//	SelectedObjectAspectMask 0x8
//	TitlesAspectMask	 0x10


#ifdef HELPFUL_COMMENT_MAKER
#include <GNUstepBase/GSObjCRuntime.h>
#include <Foundation/Foundation.h>
#include <EOInterface/EOAssociation.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
  NSArray *a1;
  int i;

  a1 = GSObjCDirectSubclassesOfClass([EOAssociation class]);
  for (i = 0; i < [a1 count]; i++)
    {
      int n;
      NSArray *a2;
      NSMutableSet *aSet = [[NSMutableSet alloc] init];

      a2 = GSObjCAllSubclassesOfClass([a1 objectAtIndex:i]);
      [aSet addObjectsFromArray:[[a1 objectAtIndex:i] aspects]];
      for (n = 0; n < [a2 count]; n++)
        {
          [aSet addObjectsFromArray:[[a2 objectAtIndex:n] aspects]];
        }
      [dict setObject:aSet forKey:[a1 objectAtIndex:i]];
    }
  for (i = 0; i < [dict count]; i++)
    {
      id key = [[dict allKeys] objectAtIndex:i];
      NSArray *arr;
      int n;

      arr = [[dict objectForKey:key] allObjects];
      GSPrintf(stdout, @"/* %@:%i %@ */\n", key, [arr count], arr);
    }
}

#endif
