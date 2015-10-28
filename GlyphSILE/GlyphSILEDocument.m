//
//  GlyphSILEDocument.m
//  GlyphSILE
//
//  Created by Georg Seifert on 28/10/2015.
//  Copyright (c) 2015 Simon Cozens. All rights reserved.
//

#import "GlyphSILEDocument.h"
#import "GlyphSILEWindow.h"

@interface GSExportInstanceOperation : NSOperation { }
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

@implementation GlyphSILEDocument


- (void) makeWindowControllers {
	NSWindowController *WindowController = [[GlyphSILEWindow alloc] initWithWindowNibName:@"SILEPreview"];
	[self addWindowController:WindowController];
}

- (NSWindowController *)windowController {
	return self.windowControllers[0];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataRepresentationOfType:(NSString *)aType {
	if ([self.text length] > 0) {
		return [self.text dataUsingEncoding:NSUTF8StringEncoding];
	}
	else {
		return [NSData data];
	}
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType {
	self.text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return YES;
}

+ (NSArray *)writableTypes {
	return @[@"org.simon-cozens.sileDocument"];
}

+ (BOOL) isNativeType:(NSString *)aType {
	return [@"org.simon-cozens.sileDocument" isEqualTo:aType];
}

+ (BOOL) autosavesInPlace {
	return NO;
}

+ (BOOL) autosavesDrafts {
	return YES;
}

- (void) setText:(NSString *)text {
	[[[self undoManager] prepareWithInvocationTarget:self] setText:_text];
	_text = text;
}

@end
