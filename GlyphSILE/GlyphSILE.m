//
//  GlyphSILEWindow.m
//  GlyphSILEWindow
//
//  Created by Simon Cozens on 25/09/2015.
//  Copyright © 2015 Simon Cozens. All rights reserved.
//

#import "GlyphSILE.h"
#import "NSLua.h"
#import "LuaBridgedFunctions.h"

// stub definitions, implemented in Glyphs

@interface JSTDocument
- (void) setKeywords:(NSDictionary *)keyWords;
@end

@protocol WindowsAdditions <NSObject>
- (BOOL)reallyVisible;
@end

@implementation GlyphSILE

NSMutableString *buffer;
NSTextView *luaResult;


+ (void)initialize {
	NSTask *task;
	task = [[NSTask alloc] init];
	NSString *Command = @"/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister";
	[task setLaunchPath:Command];
	NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
	NSString * AppPath = [thisBundle pathForResource:@"SILEapp" ofType:@"app"];
	[task setArguments:@[AppPath]];
	[task launch];
	
	CFStringRef Handler = LSCopyDefaultRoleHandlerForContentType(CFSTR("org.simon-cozens.siledocument"), kLSRolesViewer);
	if (!Handler || CFStringCompare(Handler, CFSTR("com.GeorgSeifert.Glyphs2"), 0)) {
		LSSetDefaultRoleHandlerForContentType(CFSTR("org.simon-cozens.sileDocument"), kLSRolesViewer, CFSTR("com.GeorgSeifert.Glyphs2"));
	}
	if (Handler) {
		CFRelease(Handler);
	}
}

- (id) init {
    self = [super init];
    if (self) {
        buffer = [NSMutableString stringWithString:@""];
        // do stuff
    }
    return self;
}

int lua_my_print(lua_State* L) {
    int nargs = lua_gettop(L);
    
    for (int i=1; i <= nargs; i++) {
        [buffer appendString:[NSString stringWithUTF8String:luaL_tolstring(L,i,NULL)]];
        if (i <nargs) [buffer appendString:@"\t"];
    }
    [buffer appendString:@"\n"];
    [luaResult setString:buffer];
    return 0;
}

static const struct luaL_Reg printlib [] = {
    {"print", lua_my_print},
    {NULL, NULL} /* end of array */
};

- (void) insertWindowMenuItemwithTitle: (NSString*)title andSelector:(SEL)s {
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem* i = [[NSMenuItem alloc] initWithTitle:title action:s keyEquivalent:@""];
    [i setTarget:self];
    int index = 0;
    int numberOfSeperators = 0;
    for (NSMenuItem *i in [[[mainMenu itemAtIndex:8] submenu] itemArray]) {
        if ([i isSeparatorItem]) {
            numberOfSeperators++;
            if (numberOfSeperators == 2) break;
        }
        index++;
    }
    [[[mainMenu itemAtIndex:8] submenu] insertItem:i atIndex:index];
}

- (void) loadPlugin {
    [NSBundle loadNibNamed:@"LuaConsole" owner:self];
    //[NSBundle loadNibNamed:@"SILEPreview" owner:self];
    luaResult = _luaResult;

    [self insertWindowMenuItemwithTitle:@"Lua Console" andSelector:@selector(showConsole)];
    [self insertWindowMenuItemwithTitle:@"SILE Preview" andSelector:@selector(showSILEPreview)];

    lua_State *L = [[NSLua sharedLua] getLuaState];
    lua_getglobal(L, "_G");
    luaL_setfuncs(L, printlib, 0);
    lua_pop(L, 1);
    [[NSLua sharedLua] runLuaBundleFile:@"GlyphsApp.lua"];
    [[NSLua sharedLua] runLuaBundleFile:@"GlyphSILE.lua"];
    
    NSArray *blueWords = @[@"and", @"break", @"do", @"else", @"elseif", @"end", @"false", @"for", @"function", @"goto", @"if", @"in", @"local", @"nil", @"not", @"or", @"repeat", @"return", @"then", @"true", @"until", @"while"];
    NSArray *greenWords = @[@"glyphs", @"components", @"anchors", @"kerning", @"Layer", @"Glyph", @"Node", @"Anchor", @"Component"];
    NSArray *orangeWords = @[];

    
    NSMutableDictionary *keywords = [[NSMutableDictionary alloc] init];
    //[keywords setObject:[NSColor whiteColor] forKey:GSForegroundColor];
    NSFont *Font = [NSFont fontWithName:@"Menlo-Italic" size:11];
    if (Font) {
        keywords[@"GSCommmentAttributes"] = @{@"NSColor": [NSColor darkGrayColor], @"NSFont": Font};
    }
    else {
        keywords[@"GSCommmentAttributes"] = @{@"NSColor": [NSColor darkGrayColor]};
    }
    
    Font = [NSFont fontWithName:@"Menlo-Bold" size:11];
    NSMutableDictionary *Attributes = [NSMutableDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:0.0f green:0.55f blue:0.8f alpha:1.0f] forKey:NSForegroundColorAttributeName];
    if (Font) {
        Attributes[NSFontAttributeName] = Font;
    }
    for (NSString *word in blueWords) {
        keywords[word] = Attributes;
    }
    Attributes = [NSMutableDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:0.2f green:0.4f blue:0.16f alpha:1.0f] forKey:NSForegroundColorAttributeName];
    for (NSString *word in greenWords) {
        keywords[word] = Attributes;
    }
    Attributes = [NSMutableDictionary dictionaryWithObject:[NSColor colorWithCalibratedRed:0.5f green:0.28f blue:0.0f alpha:1.0f] forKey:NSForegroundColorAttributeName];
    for (NSString *word in orangeWords) {
        keywords[word] = Attributes;
    }
    
//    [(JSTDocument *)[_incomingCode delegate] setKeywords:keywords];
    NSString *Code = [[NSUserDefaults standardUserDefaults] objectForKey:@"LuaConsoleCode"];
    if ([Code length] > 0) {
        [_incomingCode setString:Code];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showLuaConsole"]) {
        [_consoleWindow orderBack:self];
    }
}

- (NSUInteger) interfaceVersion {
    // Distinguishes the API verison the plugin was built for. Return 1.
    return 1;
}

- (void) dealloc {
	self.incomingCode = nil;
	self.luaResult = nil;
}

- (BOOL)windowShouldClose:(id)window {
    if (_consoleWindow == window) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showLuaConsole"];
    }
    return YES;
}

- (void) showConsole {
    if ([(NSWindow <WindowsAdditions>*)_consoleWindow reallyVisible] && [_consoleWindow isKeyWindow]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showLuaConsole"];
        [_consoleWindow orderOut:self];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showLuaConsole"];
        [_consoleWindow makeKeyAndOrderFront:self];
    }
}

- (void) showSILEPreview {
	NSDocument *newDoc = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"org.simon-cozens.siledocument" error:nil];
	[NSDocumentController.sharedDocumentController addDocument:newDoc];
	[newDoc makeWindowControllers];
	[newDoc showWindows];
}

- (IBAction)clearWindow:(id)sender {
    [_luaResult setString:@""];
    [buffer setString:@""];
}

- (IBAction)compileConsoleCode:(id)sender {
    NSString *Code = [_incomingCode string];
    NSLog(@"Lua: %@", Code);
    @try {
        [[NSLua sharedLua] runLuaString:Code];
        NSString *errorBuffer = [[NSLua sharedLua] getErrorBuffer];
        if (errorBuffer && errorBuffer.length > 0) {
            [buffer appendString:errorBuffer];
        }
        [_luaResult setString:buffer];
        [[NSUserDefaults standardUserDefaults] setObject:Code forKey:@"LuaConsoleCode"];
    }
    @catch (NSException* e) {
        NSLog(@"Lua failed: %@", e.reason);
    }
}
@end
