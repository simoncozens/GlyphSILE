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

#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSInstance.h>
#import <GlyphsCore/GSFontMaster.h>

// Horrible private things
@interface GSApplication : NSApplication
@property (weak, nonatomic, nullable) GSDocument* currentFontDocument;
@end

// stub definitions, implemented in Glyphs

@interface GSExportInstanceOperation : NSOperation {
}
@property (nonatomic, readonly) NSString* finalFontFile;
@property (nonatomic, strong) NSURL* installFontURL;
@property (weak, nonatomic) id delegate;
@property (nonatomic, retain) NSString* tempPath;
@property (nonatomic) BOOL autohint;
@property (nonatomic) BOOL removeOverlap;
@property (nonatomic) BOOL useSubroutines;
@property (nonatomic) BOOL useProductionNames;

- (instancetype)initWithFont:(GSFont*)Font instance:(GSInstance*)Instance format:(int)Format;
@end

@interface JSTDocument
- (void) setKeywords:(NSDictionary *)keyWords;
@end
@interface GSDocument : NSObject
@property (nonatomic, retain) GSFont* font;
@end

@protocol WindowsAdditions <NSObject>
- (BOOL)reallyVisible;
@end

@implementation GlyphSILE

NSMutableString *buffer;
NSTextView *luaResult;

+ (void) initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{@"SILE_FontSize": @24}];
}

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
    [self drawSILEPreview:self];
}

- (void) setupBehaviorMenu {
    NSInteger sel = [_SILEMode indexOfSelectedItem];
    [_SILEMode setAutoenablesItems:NO];
	
    [_SILEMode removeAllItems];
	GSDocument *doc = [(GSApplication *)[NSApplication sharedApplication] currentFontDocument];
	if ([doc isKindOfClass:NSClassFromString(@"GSDocument")]) {
		GSFont* f = (GSFont *)[(GSDocument*)doc font];
	
		[_SILEMode addItemWithTitle:@"Instances"];
		[[_SILEMode itemAtIndex:0] setEnabled:FALSE];
		
		for (GSInstance* ins in [f instances]) {
			NSMutableDictionary* robj = [[NSMutableDictionary alloc] init];
			NSString *FullName;
			if ([ins respondsToSelector:@selector(fullName)]) {
				FullName = [ins fullName];
			}
			else {
				FullName = [NSString stringWithFormat:@"%@ %@", [f familyName], [ins name]];
			}
			NSMenuItem *i = [[NSMenuItem alloc] initWithTitle:FullName action:NULL keyEquivalent:@""];
			[robj setObject:f forKey:@"font"];
			[robj setObject:ins forKey:@"instance"];
			[i setRepresentedObject:robj];
			[[_SILEMode menu] addItem:i];
		}
		[[_SILEMode menu] addItem:[NSMenuItem separatorItem]];
		[_SILEMode addItemWithTitle:@"Masters"];
		[[_SILEMode lastItem] setEnabled:FALSE];
		for (GSFontMaster* master in [f fontMasters]) {
			NSMutableDictionary* robj = [[NSMutableDictionary alloc] init];
			NSMenuItem *i = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [f familyName], [master name]] action:NULL keyEquivalent:@""];
			[robj setObject:f forKey:@"font"];
			[robj setObject:master forKey:@"master"];
			[i setRepresentedObject:robj];
			[[_SILEMode menu] addItem:i];
		}
		NSNumber *SelectedItem = f.userData[@"SILE_SelectedBehavior"];
		if (SelectedItem) {
			NSMenuItem *Item = [_SILEMode itemAtIndex:[SelectedItem integerValue]];
			if (Item && [Item isEnabled]) {
				sel = [SelectedItem integerValue];
			}
		}
		while (sel <= 0) sel++;
		[_SILEMode selectItemAtIndex:sel];
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
	NSString *code = [[NSUserDefaults standardUserDefaults] objectForKey:@"SILE_Code"];
	if ([code length] > 0) {
		[_SILEInput setString:code];
	}
	[_SILEInput setTextContainerInset:NSMakeSize(10, 4)];
	[_fontSizeSelection setIntegerValue:[[NSUserDefaults standardUserDefaults] integerForKey:@"SILE_FontSize"]];
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

- (NSString *)_exportInstance:(GSInstance *)instance {
    int Format = 0;
    GSFont *Font = instance.font;
    GSExportInstanceOperation *Exporter = [[NSClassFromString(@"GSExportInstanceOperation") alloc] initWithFont:Font instance:instance format:Format];
    
    Exporter.installFontURL = [NSURL fileURLWithPath:[@"~/Library/Application Support/Glyphs/Temp/" stringByExpandingTildeInPath]];
    // the following parameters can be set here or directly read from the instance.
    Exporter.autohint = NO;
    Exporter.removeOverlap = NO;
    Exporter.useSubroutines = NO;
    Exporter.useProductionNames = NO;

    Exporter.tempPath = [@"~/Library/Application Support/Glyphs/Temp/" stringByExpandingTildeInPath]; // this has to be set correctly.

    //Delegate = [[ExporterDelegate.alloc] init]; // the collectResults method of this object will be called on case the exporter has to report a problem.
    //Exporter.delegate = Delegate;
    [Exporter main];
    return [Exporter finalFontFile];
}

- (IBAction)drawSILEPreview:(id)sender {
    NSString *code = [_SILEInput string];
	[[NSUserDefaults standardUserDefaults] setObject:code forKey:@"SILE_Code"];
	[[NSUserDefaults standardUserDefaults] setInteger:[_fontSizeSelection integerValue] forKey:@"SILE_FontSize"];
    SILEPreviewView *view = _SILEOutput;
    NSMenuItem* mode =  [_SILEMode selectedItem];
    if (!mode || ![mode isEnabled]) return;
	
    NSMutableDictionary* d = [mode representedObject];
	if (!d) {
		return;
	}
    NSError *Error = nil;
    GSFont *f = [d objectForKey:@"font"];
    UKLog(@"f: %@", f);
	NSInteger itemIndex = [_SILEMode indexOfItem:mode];
	if ([f respondsToSelector:@selector(setUserObject:forKey:)]) {
		[f setUserObject:@(itemIndex) forKey:@"SILE_SelectedBehavior"];
	}
	else {
		[f userData][@"SILE_SelectedBehavior"] = @(itemIndex);
	}
    if ([d objectForKey:@"instance"]) {
        GSInstance *i = [d objectForKey:@"instance"];

        NSString *filename = [self _exportInstance:i];
        if (filename) {
            d[@"filename"] = filename;
        } else {
            NSLog(@"Error exporting instance");
            return;
        }
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
    UKLog(@"d: %@", d);
    to_lua(L, d, true);
    if (lua_pcall(L, 4, 1, 0) != 0)
        NSLog(@"GlyphsSILE error running function `f': %s", lua_tostring(L, -1));
}

@end
