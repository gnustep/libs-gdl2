#include <Foundation/NSArray.h>
/* since we don't really have blocks and i don't feel like including them.. */
@interface NSArray (SelectorStuff)
- (NSArray *) arrayWithObjectsRespondingYesToSelector:(SEL)selector;
- (NSArray *) arrayWithObjectsRespondingYesToSelector:(SEL)selector
withObject:(id)argument;
@end

@interface NSObject(GDL2PaletteAdditions)
- (BOOL) isKindOfClasses:(NSArray *)classes;
@end
