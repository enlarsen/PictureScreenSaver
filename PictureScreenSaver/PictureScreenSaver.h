//
//  PictureScreenSaver.h
//  PictureScreenSaver
//
//  Created by Erik Larsen on 2/25/15.
//  Copyright (c) 2015 Erik Larsen. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>

@interface PictureScreenSaver : ScreenSaverView

@property (strong, nonatomic) IBOutlet NSWindow *configureWindow;
@property (strong, nonatomic) IBOutlet NSTextField *picturesFolderTextField;
@property (weak) IBOutlet NSComboBox *pictureChangeIntervalComboBox;

@end
