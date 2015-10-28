//
//  GlyphSILEWindow.h
//  GlyphSILE
//
//  Created by Georg Seifert on 28/10/2015.
//  Copyright (c) 2015 Simon Cozens. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SILEPreviewView.h"

@interface GlyphSILEWindow : NSWindowController

//@property (nonatomic, weak) IBOutlet NSWindow *silePreviewWindow;
@property (unsafe_unretained) IBOutlet NSTextView *SILEInput;
@property (weak) IBOutlet SILEPreviewView *SILEOutput;
@property (weak) IBOutlet NSComboBoxCell *fontSizeSelection;
@property (weak) IBOutlet NSPopUpButton *SILEMode;

@end
