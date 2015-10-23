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

// Horrible private things
@interface GSApplication : NSApplication
@property (weak, nonatomic, nullable) GSDocument* currentFontDocument;
@end

@interface GSDocument : NSDocument
@property (weak, nonatomic, nullable) GSFont* font;
@end

@interface GSInstance : GSFont
@end
@interface GSFontMaster : GSFont
@end

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

- (void)windowDidBecomeKey:(NSNotification *)notification{
    [self setupBehaviorMenu];
}

- (void) setupBehaviorMenu {
    [_SILEMode setAutoenablesItems:NO];

    [_SILEMode removeAllItems];
    [_SILEMode addItemWithTitle:@"Instances"];
    [[_SILEMode itemAtIndex:0] setEnabled:FALSE];
    
    for (NSDocument* doc in [[NSApplication sharedApplication] orderedDocuments]) {
        if ([doc isKindOfClass:NSClassFromString(@"GSDocument")]) {
            GSFont* f = [(GSDocument*)doc font];
            for (GSInstance* ins in [f instances]) {
                NSMutableDictionary* robj = [[NSMutableDictionary alloc] init];
                NSMenuItem *i = [[NSMenuItem alloc] initWithTitle:[ins valueForKey:@"name"] action:NULL keyEquivalent:@""];
                [robj setObject:f forKey:@"font"];
                [robj setObject:ins forKey:@"instance"];
                [i setRepresentedObject:robj];
                [[_SILEMode menu] addItem:i];
            }
        }
    }
    [[_SILEMode menu] addItem:[NSMenuItem separatorItem]];
    [_SILEMode addItemWithTitle:@"Masters"];
    [[_SILEMode itemAtIndex:([[_SILEMode itemArray]count]-1)] setEnabled:FALSE];
    for (NSDocument* doc in [[NSApplication sharedApplication] orderedDocuments]) {
        if ([doc isKindOfClass:NSClassFromString(@"GSDocument")]) {
            GSFont* f = [(GSDocument*)doc font];
            for (GSFontMaster* master in [f fontMasters]) {
                NSMutableDictionary* robj = [[NSMutableDictionary alloc] init];
                NSMenuItem *i = [[NSMenuItem alloc] initWithTitle:[master valueForKey:@"name"] action:NULL keyEquivalent:@""];
                [robj setObject:f forKey:@"font"];
                [robj setObject:master forKey:@"master"];
                [i setRepresentedObject:robj];
                [[_SILEMode menu] addItem:i];
            }

        }
    }
}

- (void) loadPlugin {
    [NSBundle loadNibNamed:@"LuaConsole" owner:self];
    [NSBundle loadNibNamed:@"SILEPreview" owner:self];
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
    
    [(JSTDocument *)[_incomingCode delegate] setKeywords:keywords];
    NSString *Code = [[NSUserDefaults standardUserDefaults] objectForKey:@"LuaConsoleCode"];
    [_incomingCode setString:Code];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showLuaConsole"]) {
        [_consoleWindow orderBack:self];
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showSILEPreview"]) {
        [_silePreviewWindow orderBack:self];
    }
    [self setupBehaviorMenu];
}

- (NSUInteger) interfaceVersion {
    // Distinguishes the API verison the plugin was built for. Return 1.
    return 1;
}

- (BOOL)windowShouldClose:(id)window {
    if (_consoleWindow == window) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showLuaConsole"];
    }
    if (_silePreviewWindow == window) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showSILEPreview"];
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
    if ([(NSWindow <WindowsAdditions>*)_silePreviewWindow reallyVisible] && [_silePreviewWindow isKeyWindow]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showSILEPreview"];
        [_silePreviewWindow orderOut:self];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showSILEPreview"];
        [_silePreviewWindow makeKeyAndOrderFront:self];
    }
    [self setupBehaviorMenu];
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
    NSString *code = [_SILEInput string];
    SILEPreviewView *view = _SILEOutput;
    NSMenuItem* mode =  [_SILEMode selectedItem];
    if (!mode) return;

    NSMutableDictionary* d = [mode representedObject];
    NSError *Error = nil;

    GSFont *f = [d objectForKey:@"font"];
    if ([d objectForKey:@"instance"]) {
        GSInstance *i = [d objectForKey:@"instance"];
        GSFont *f2 = [f generateInstance:i error:&Error];
        [f2 compileTempFontError:&Error];
        NSString *filename = [f2 tempOTFFont];
        [d setValue:filename forKey:@"filename"];
        /* XXX Need to export full font here */
    } else if ([d objectForKey:@"master"]) {
        [f compileTempFontError:&Error];
        NSString *family = [NSString stringWithFormat: @"Glyphs:Master:%@", [[d objectForKey:@"master"] valueForKey:@"id"]];
        [d setValue:family forKey:@"family"];
    }
    lua_State *L = [[NSLua sharedLua] getLuaState];
    lua_getglobal(L, "doGlyphSILE");
    lua_pushstring(L, [code UTF8String]);
    to_lua(L, view, true);
    lua_pushinteger(L, [_fontSizeSelection integerValue]);
    to_lua(L, d, true);
    if (lua_pcall(L, 4, 1, 0) != 0)
        NSLog(@"error running function `f': %s", lua_tostring(L, -1));
}

@end
