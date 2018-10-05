//
//  GlyphSILEWindow.m
//  GlyphSILE
//
//  Created by Georg Seifert on 28/10/2015.
//  Copyright (c) 2015 Simon Cozens. All rights reserved.
//

#import "GlyphSILEWindow.h"
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSInstance.h>
#import <GlyphsCore/GSFontMaster.h>
#import "NSLua.h"
#import "LuaBridgedFunctions.h"

@interface GSApplication : NSApplication
@property (weak, nonatomic, nullable) GSDocument* currentFontDocument;
@end

@interface GSDocument : NSDocument
@property (nonatomic, retain) GSFont* font;
@end

@interface GlyphSILEWindow ()

@end

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

@implementation GlyphSILEWindow

- (void)windowDidLoad {
	[super windowDidLoad];
	[_SILEInput setTextContainerInset:NSMakeSize(10,5)];
}

- (void)windowDidBecomeKey:(NSNotification *)notification{
	[self setupBehaviorMenu];
	[self drawSILEPreview:self];
}

- (void)setupBehaviorMenu {
	NSInteger sel = [_SILEMode indexOfSelectedItem];
	[_SILEMode setAutoenablesItems:NO];
	
	[_SILEMode removeAllItems];
	[_SILEMode addItemWithTitle:@"Instances"];
	[[_SILEMode itemAtIndex:0] setEnabled:FALSE];
	
	GSDocument* doc = [(GSApplication *)[NSApplication sharedApplication] currentFontDocument];
	if ([doc isKindOfClass:NSClassFromString(@"GSDocument")]) {
		GSFont* f = [(GSDocument*)doc font];
		for (GSInstance* ins in [f instances]) {
			NSMutableDictionary* robj = [[NSMutableDictionary alloc] init];
			NSMenuItem *i = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [f valueForKey:@"familyName"], [ins valueForKey:@"name"]] action:NULL keyEquivalent:@""];
			[robj setObject:f forKey:@"font"];
			[robj setObject:ins forKey:@"instance"];
			[i setRepresentedObject:robj];
			[[_SILEMode menu] addItem:i];
		}
	}
	[[_SILEMode menu] addItem:[NSMenuItem separatorItem]];
	[_SILEMode addItemWithTitle:@"Masters"];
	[[_SILEMode itemAtIndex:([[_SILEMode itemArray]count]-1)] setEnabled:FALSE];
	for (NSDocument* doc in [[NSApplication sharedApplication] orderedDocuments]) {
		if ([doc isKindOfClass:NSClassFromString(@"GSDocument")]) {
			GSFont* f = (GSFont *)[(GSDocument*)doc font];
			for (GSFontMaster* master in [f fontMasters]) {
				NSMutableDictionary* robj = [[NSMutableDictionary alloc] init];
				NSMenuItem *i = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [f valueForKey:@"familyName"], [master name]] action:NULL keyEquivalent:@""];
				[robj setObject:f forKey:@"font"];
				[robj setObject:master forKey:@"master"];
				[i setRepresentedObject:robj];
				[[_SILEMode menu] addItem:i];
			}
			
		}
	}
	[_SILEMode selectItemAtIndex:sel];
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

- (void) callSILE:(bool)toScreen {
	NSString *code = [_SILEInput string];
	SILEPreviewView *view = _SILEOutput;
	NSMenuItem* mode =  [_SILEMode selectedItem];
	if (!mode) return;
	
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"sile.pdf"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    
	NSMutableDictionary* d = [mode representedObject];
	NSError *Error = nil;
	GSFont *f = [d objectForKey:@"font"];
	UKLog(@"f: %@", f);
    if (!f) return;
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
    if (toScreen) {
        d[@"toscreen"] = @"YES";
    } else {
        d[@"toscreen"] = @"NO";
        d[@"output"] = filePath;
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
    if (!toScreen && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSWorkspace sharedWorkspace] openFile:filePath];
    }
}

- (IBAction)drawSILEPreview:(id)sender {
    [self callSILE:true];
}
- (IBAction)createPDF:(id)sender {
    [self callSILE:false];
}

- (IBAction)onSILEModeSelect:(id)sender {
    NSMenuItem* mode =  [_SILEMode selectedItem];
    if (!mode) return;
    NSMutableDictionary* d = [mode representedObject];
    if ([d objectForKey:@"instance"]) {
        [_PDFButton setEnabled:true];
    } else if ([d objectForKey:@"master"]) {
        [_PDFButton setEnabled:false];
    }
}
@end
