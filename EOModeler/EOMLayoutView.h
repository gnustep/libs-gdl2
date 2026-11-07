/* Simple row and column layout for native model editor interfaces.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */
#ifndef EOM_LAYOUT_VIEW_H
#define EOM_LAYOUT_VIEW_H

#import <AppKit/AppKit.h>

@interface EOMLayoutView : NSView
{
  NSMutableArray *preferredSizes;
  BOOL horizontal;
}

- (void) setHorizontal: (BOOL)flag;
- (BOOL) expandsVertically;

@end

#endif
