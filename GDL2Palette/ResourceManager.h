#include <InterfaceBuilder/IBResourceManager.h>

@class EOEditingContext;
@class EOModelGroup;


@interface GDL2ResourceManager : IBResourceManager
{
  EOEditingContext *_defaultEditingContext;
  EOModelGroup *modelGroup;
}

@end

