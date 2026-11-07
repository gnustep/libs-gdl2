/* Simple row and column layout for native model editor interfaces.
 * Copyright (C) 2026 Gregory Casamento <greg.casamento@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */
#import "EOMLayoutView.h"
#import <GNUstepBase/GNUstep.h>

static BOOL
EOMExpandsVertically (NSView *view)
{
  if ([view isKindOfClass: [EOMLayoutView class]])
    return [(EOMLayoutView *)view expandsVertically];
  return [view isKindOfClass: [NSScrollView class]]
    || [view isKindOfClass: [NSSplitView class]]
    || [view isKindOfClass: [NSTabView class]];
}

@implementation EOMLayoutView

- (id) initWithFrame: (NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self)
    preferredSizes = [[NSMutableArray alloc] init];
  return self;
}

- (void) setHorizontal: (BOOL)flag
{
  horizontal = flag;
}

- (void) addSubview: (NSView *)view
{
  [preferredSizes addObject: [NSValue valueWithSize: [view frame].size]];
  [super addSubview: view];
}

- (BOOL) expandsVertically
{
  NSEnumerator *enumerator = [[self subviews] objectEnumerator];
  NSView *view;

  while ((view = [enumerator nextObject]) != nil)
    if (EOMExpandsVertically (view))
      return YES;
  return NO;
}

- (void) resizeSubviewsWithOldSize: (NSSize)oldSize
{
  NSArray *views = [self subviews];
  NSUInteger count = [views count];
  NSUInteger i, flexible = 0;
  CGFloat total = 12 + (count > 0 ? (count - 1) * 6 : 0);
  CGFloat position = 6;
  CGFloat extra;
  NSSize available = [self bounds].size;

  /* During initialization AppKit can resize an empty content view. */
  if (count != [preferredSizes count])
    return;
  for (i = 0; i < count; i++)
    {
      NSSize size = [[preferredSizes objectAtIndex: i] sizeValue];
      total += horizontal ? size.width : size.height;
      if (horizontal || EOMExpandsVertically ([views objectAtIndex: i]))
        flexible++;
    }
  extra = MAX (0, (horizontal ? available.width : available.height) - total);
  for (i = 0; i < count; i++)
    {
      NSView *view = [views objectAtIndex: i];
      NSSize size = [[preferredSizes objectAtIndex: i] sizeValue];
      NSRect frame;

      if (horizontal)
        {
          size.width += flexible ? extra / flexible : 0;
          frame = NSMakeRect (position, 6, size.width, MAX (0, available.height - 12));
          position += size.width + 6;
        }
      else
        {
          if (EOMExpandsVertically (view) && flexible)
            size.height += extra / flexible;
          frame = NSMakeRect (6, available.height - position - size.height,
                              MAX (0, available.width - 12), size.height);
          position += size.height + 6;
        }
      [view setFrame: frame];
    }
}

- (void) dealloc
{
  DESTROY (preferredSizes);
  DEALLOC;
}

@end
