//
//  GlyphSILE.m
//  GlyphSILE
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

- (id) init {
    self = [super init];
	if (self) {
        buffer = [NSMutableString stringWithString:@""];
		// do stuff
	}
	return self;
}

- (void) dealloc {
	self.incomingCode = nil;
	self.luaResult = nil;
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
    [NSBundle loadNibNamed:@"SILEPreview" owner:self];
    
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
    
    lua_State *L = [[NSLua sharedLua] getLuaState];
    lua_getglobal(L, "_G");
    luaL_setfuncs(L, printlib, 0);
    lua_pop(L, 1);
    [[NSLua sharedLua] runLuaBundleFile:@"GlyphsApp.lua"];
    [[NSLua sharedLua] runLuaBundleFile:@"GlyphSILE.lua"];

//    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
//    NSString *path = [bundle pathForResource:@"GlyphsApp" ofType:@"lua"];
//    if (luaL_dofile(L, [path UTF8String]))
//    {
//        const char *err = lua_tostring(L, -1);
//        NSLog(@"error while loading Glyphs API: %s", err);
//    }
	
	
	NSArray *blueWords = @[@"False", @"True", @"None", @"print", @"and", @"del", @"from", @"not", @"while", @"as", @"elif", @"global", @"or", @"with", @"assert", @"else", @"if", @"pass", @"yield", @"break", @"except", @"import", @"print", @"class", @"exec", @"in", @"raise", @"continue", @"finally", @"is", @"return", @"function", @"for", @"lambda", @"try"];
	
	NSArray *greenWords = @[@"glyphs", @"components", @"anchors", @"kerning", @"Layer", @"Glyph", @"Node", @"Anchor", @"Component"];
	NSArray *orangeWords = @[@"all", @"abs", @"any", @"apply", @"callable", @"chr", @"cmp", @"coerce", @"compile", @"delattr", @"dir", @"divmod", @"eval", @"execfile", @"filter", @"getattr", @"globals", @"hasattr", @"hash", @"hex", @"id", @"input", @"intern", @"isinstance", @"issubclass", @"iter", @"len", @"locals", @"map", @"max", @"min", @"oct", @"ord", @"pow", @"range", @"raw_input", @"reduce", @"reload", @"repr", @"round", @"setattr", @"sorted", @"sum", @"unichr", @"vars", @"zip", @"basestring", @"bool", @"buffer", @"classmethod", @"complex", @"dict", @"enumerate", @"file", @"float", @"frozenset", @"int", @"list", @"long", @"object", @"open", @"property", @"reversed", @"set", @"slice", @"staticmethod", @"str", @"super", @"tuple", @"type", @"unicode", @"xrange"];

	
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
	
	[(JSTDocument *)[_incomingCode delegate] setKeywords:keywords];
	NSString *Code = [[NSUserDefaults standardUserDefaults] objectForKey:@"LuaConsoleCode"];
	[_incomingCode setString:Code];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showLuaConsole"]) {
		[_consoleWindow orderBack:self];
	}
}

- (NSUInteger) interfaceVersion {
	// Distinguishes the API verison the plugin was built for. Return 1.
	return 1;
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
- (IBAction)drawSILEPreview:(id)sender {
    NSLog(@"dsp called");
    NSString *code = [_SILEInput string];
    NSView *view = _SILEOutput;
    lua_State *L = [[NSLua sharedLua] getLuaState];
    lua_getglobal(L, "doGlyphSILE");
    lua_pushstring(L, [code UTF8String]);
    to_lua(L, view, true);
    if (lua_pcall(L, 2, 1, 0) != 0)
        NSLog(@"error running function `f': %s", lua_tostring(L, -1));
}
@end
