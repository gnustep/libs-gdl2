#include <Foundation/NSString.h>
@interface NSFramework_PostgreSQLEOAdaptor : NSObject
+ (NSString *)frameworkVersion;
+ (NSString *const*)frameworkClasses;
@end
@implementation NSFramework_PostgreSQLEOAdaptor
+ (NSString *)frameworkVersion { return @"0"; }
static NSString *allClasses[] = {@"PostgreSQLAdaptor", @"PostgreSQLContext", @"PostgreSQLChannel", @"PostgreSQLExpression", NULL};
+ (NSString *const*)frameworkClasses { return allClasses; }
@end
