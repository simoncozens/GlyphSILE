//
//  GlyphSILE.m
//  GlyphSILE
//
//  Created by Simon Cozens on 25/09/2015.
//  Copyright © 2015 Simon Cozens. All rights reserved.
//

#import "GlyphSILE.h"
#import "EasyLua.h"

@implementation GlyphSILE
@synthesize consoleWindow;
@synthesize incomingCode;
@synthesize luaResult;

NSMutableString *buffer;

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
    return 0;
}

static const struct luaL_Reg printlib [] = {
    {"print", lua_my_print},
    {NULL, NULL} /* end of array */
};

- (void) loadPlugin {
    [NSBundle loadNibNamed:@"LuaConsole" owner:self];
    
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *consoleMenuItem = [[NSMenuItem alloc] initWithTitle:@"Lua Console" action:@selector(showConsole) keyEquivalent:@""];
    [consoleMenuItem setTarget:self];
    int index = 0;
    int numberOfSeperators = 0;
    for (NSMenuItem *i in [[[mainMenu itemAtIndex:8] submenu] itemArray]) {
        if ([i isSeparatorItem]) {
            numberOfSeperators++;
            if (numberOfSeperators == 2) break;
        }
        index++;
    }
    [[[mainMenu itemAtIndex:8] submenu] insertItem:consoleMenuItem atIndex:index];
    
    lua_State *L = [[EasyLua sharedEasyLua] getLuaState];
    lua_getglobal(L, "_G");
    luaL_setfuncs(L, printlib, 0);
    lua_pop(L, 1);
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"GlyphsApp" ofType:@"lua"];
    if (luaL_dofile(L, [path UTF8String]))
    {
        const char *err = lua_tostring(L, -1);
        NSLog(@"error while loading Glyphs API: %s", err);
    }
}

- (NSUInteger) interfaceVersion {
	// Distinguishes the API verison the plugin was built for. Return 1.
	return 1;
}

- (void) showConsole {
    [consoleWindow makeKeyAndOrderFront:self];
}

- (IBAction)clearWindow:(id)sender {
    [luaResult setStringValue:@""];
    [buffer setString:@""];
}

- (IBAction)compileConsoleCode:(id)sender {
    NSLog(@"Lua: %@", [incomingCode stringValue]);
    @try {
        [[EasyLua sharedEasyLua] runLuaString:[incomingCode stringValue]];
        NSString *errorBuffer = [[EasyLua sharedEasyLua] getErrorBuffer];
        if (errorBuffer && errorBuffer.length > 0) {
            [buffer appendString:errorBuffer];
        }
        [luaResult setStringValue:buffer];
    }
    @catch (NSException* e) {
        NSLog(@"Lua failed: %@", e.reason);
    }
}

// Delegate to make the text entry field wrap. Blegh.
- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector
{
    BOOL result = NO;
    
    if (commandSelector == @selector(insertNewline:))
    {
        // new line action:
        // always insert a line-break character and don’t cause the receiver to end editing
        [textView insertNewlineIgnoringFieldEditor:self];
        result = YES;
    }
    else if (commandSelector == @selector(insertTab:))
    {
        // tab action:
        // always insert a tab character and don’t cause the receiver to end editing
        [textView insertTabIgnoringFieldEditor:self];
        result = YES;
    }
    
    return result;
}
@end
