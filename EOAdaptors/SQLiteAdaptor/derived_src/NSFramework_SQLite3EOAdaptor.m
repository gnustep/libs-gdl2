#include <Foundation/NSString.h>
@interface NSFramework_SQLite3EOAdaptor : NSObject
+ (NSString *)frameworkVersion;
+ (NSString *const*)frameworkClasses;
@end
@implementation NSFramework_SQLite3EOAdaptor
+ (NSString *)frameworkVersion { return @"0"; }
static NSString *allClasses[] = {@"SQLite3Adaptor", @"SQLite3Context", @"SQLite3Expression", @"SQLite3Channel", NULL};
+ (NSString *const*)frameworkClasses { return allClasses; }
@end
