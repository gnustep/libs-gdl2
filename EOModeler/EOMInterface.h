/* Native interface construction shared by the model editors.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */
#ifndef EOM_INTERFACE_H
#define EOM_INTERFACE_H

#import <AppKit/AppKit.h>

@interface NSObject (EOMInterfaceConstruction)

+ (void) buildForOwner: (id)owner;

@end

/* Interface classes are linked into the application or its inspector bundle.
 * Older external inspectors can continue to supply a native nib. */
static inline BOOL
EOMLoadInterface (NSString *name, id owner)
{
  NSString *className;
  Class builder;

  className = [@"EOMInterface_" stringByAppendingString:
    [[name componentsSeparatedByString: @"-"] componentsJoinedByString: @"_"]];
  builder = NSClassFromString (className);
  if (builder != Nil)
    {
      [builder buildForOwner: owner];
      return YES;
    }
  return [NSBundle loadNibNamed: name owner: owner];
}

#endif
