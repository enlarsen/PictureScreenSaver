//
//  DonnaArtShowView.m
//  DonnaArtShow
//
//  Created by Erik Larsen on 2/25/15.
//  Copyright (c) 2015 Erik Larsen. All rights reserved.
//


#import "DonnaArtShowView.h"

static NSString * const pictureDirectoryKey = @"pictureDirectory";
static NSString * const pictureChangeIntervalKey = @"pictureIntervalChange";

@interface DonnaArtShowView()

@property (nonatomic) NSTimeInterval changeTimeInterval;
@property (nonatomic) NSTimeInterval currentTimeInterval;
@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSArray *files;
@property (nonatomic) int currentIndex;
@property (strong, nonatomic) NSImage *currentImage;
@property (strong, nonatomic) NSString *bundleIdentifier;
@property (strong, nonatomic) ScreenSaverDefaults *defaults;
@end

@implementation DonnaArtShowView

#pragma mark - Properties

- (NSString *)bundleIdentifier
{
    if(!_bundleIdentifier)
    {
        _bundleIdentifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    }
    return _bundleIdentifier;

}

- (ScreenSaverDefaults *)defaults
{
    if(!_defaults)
    {
        _defaults = [ScreenSaverDefaults defaultsForModuleWithName:self.bundleIdentifier];
    }
    return _defaults;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self)
    {

        [self.defaults registerDefaults:[DonnaArtShowView defaultsDictionary]];
        self.animationTimeInterval = 5.0;

        self.changeTimeInterval = [self.defaults doubleForKey:pictureChangeIntervalKey];

        self.path = [[self.defaults
                     stringForKey:pictureDirectoryKey] stringByExpandingTildeInPath];
        //        self.changeTimeInterval = 5.0; //20.0 * 60.0;
        self.currentTimeInterval = self.changeTimeInterval;
        self.currentIndex = 0;

    }
    return self;
}

- (void)startAnimation
{
    NSError *error;

    [super startAnimation];

    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];

    self.files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error] sortedArrayUsingDescriptors:@[sort]];
}

- (void)stopAnimation
{
    [super stopAnimation];
        // TODO save index so we can start with the same file next time
}

- (void)drawRect:(NSRect)rect
{

    [super drawRect:rect];
    if(self.currentImage)
    {
        NSInteger repWidth = 0;
        NSInteger repHeight = 0;
        CGFloat height, width;
        for(NSImageRep *rep in self.currentImage.representations)
        {
            NSLog(@"Image rep width: %ld height: %ld", (long)rep.pixelsWide, (long)rep.pixelsHigh);
            if([rep pixelsWide] > repWidth)
            {
                repWidth = [rep pixelsWide];
                repHeight = [rep pixelsHigh];
            }
        }
        NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(repWidth, repHeight)];
        [image addRepresentations:self.currentImage.representations];

        CGFloat centerX, centerY;

//        if(image.size.height > rect.size.height ||
//           image.size.width > rect.size.width)
//        {
            CGFloat horizontalScaleFactor = rect.size.width / image.size.width;
            CGFloat verticalScaleFactor = rect.size.height / image.size.height;
            CGFloat scaleFactor;

            if(verticalScaleFactor < horizontalScaleFactor)
            {
                scaleFactor = verticalScaleFactor;
            }
            else
            {
                scaleFactor = horizontalScaleFactor;
            }

            width = image.size.width * scaleFactor;
            height = image.size.height * scaleFactor;
//        }
//        else
//        {
//            width = image.size.width;
//            height = image.size.height;
//        }

        centerX = (rect.size.width / 2.0) - (width / 2.0);
        centerY = (rect.size.height / 2.0) - (height / 2.0);


        NSRect newRect = CGRectMake(centerX, centerY, width,
                                 height);
        [image drawInRect:newRect];
        NSLog(@"Drawing %@ (%@) in rect: %@", self.files[self.currentIndex],
              NSStringFromSize(self.currentImage.size), NSStringFromRect(newRect));

    }
}

- (void)animateOneFrame
{
    self.currentTimeInterval += self.animationTimeInterval;
    if(self.currentTimeInterval > self.changeTimeInterval)
    {
        do
        {
            self.currentIndex++;
            if(self.currentIndex >= self.files.count)
            {
                self.currentIndex = 0;
            }

            self.currentImage = [[NSImage alloc]
                                 initByReferencingFile:[self.path stringByAppendingPathComponent:self.files[self.currentIndex]]];
            [self setNeedsDisplay:YES];

        } while(!self.currentImage);


        self.currentTimeInterval = 0.0;
    }
    
    return;
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow*)configureSheet
{
    BOOL loadedBundle = NO;
    if(!self.configureWindow)
    {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        loadedBundle = [bundle loadNibNamed:@"ConfigurationSheet" owner:self topLevelObjects:nil];
    }

    for(NSString *key in [DonnaArtShowView comboBoxToInterval].allKeys)
    {
        if(loadedBundle == YES) // Only add the items if we just loaded the window
        {
            [self.pictureChangeIntervalComboBox addItemWithObjectValue:key];
        }
        if(fabs(self.changeTimeInterval -
                [[DonnaArtShowView comboBoxToInterval][key] doubleValue]) < 0.01)
        {
            [self.pictureChangeIntervalComboBox selectItemWithObjectValue:key];
        }
    }
//    [self.pictureChangeIntervalComboBox addItemsWithObjectValues:[DonnaArtShowView comboBoxToInterval].allKeys];

    self.picturesFolderTextField.stringValue = self.path;


    return self.configureWindow;

}
- (IBAction)configureOK:(NSButton *)sender
{
    if(![self.picturesFolderTextField.stringValue isEqualToString:self.path])
    {
        self.path = self.picturesFolderTextField.stringValue;
        [self.defaults setObject:self.path forKey:pictureDirectoryKey];
        [self.defaults synchronize];
    }

    NSNumber *selectedInterval = [DonnaArtShowView comboBoxToInterval].allValues[self.pictureChangeIntervalComboBox.indexOfSelectedItem];
    if(fabs([selectedInterval doubleValue] - self.changeTimeInterval) > 0.01)
    {
        self.changeTimeInterval = [selectedInterval doubleValue];
        [self.defaults setObject:@(self.changeTimeInterval) forKey:pictureChangeIntervalKey];
        [self.defaults synchronize];
    }

    [NSApp endSheet:self.configureWindow];
}

- (IBAction)configureCancel:(NSButton *)sender
{
    [NSApp endSheet:self.configureWindow];
}
- (IBAction)configureChooseFolder:(NSButton *)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = NO;
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = NO;
    openPanel.prompt = @"Choose";

    [openPanel beginSheetModalForWindow:self.configureWindow
                      completionHandler:^(NSInteger result)
    {
        if(result == NSFileHandlingPanelOKButton)
        {
            NSURL *selectedDirectoryURL = [openPanel URL];
            self.picturesFolderTextField.stringValue = selectedDirectoryURL.path;
        }
    }];

}

+ (NSDictionary *)comboBoxToInterval
{
    return @{@"5 seconds": @5.0,
             @"Minute": @60,
             @"15 minutes": @(60 * 15),
             @"20 minutes": @(60 * 20),
             @"Hour": @(60 * 60),
             @"4 hours": @(60 * 60 * 4),
             @"8 hours": @(60 * 60 * 8),
             @"Day": @(60 *60 * 24)};
}

+ (NSDictionary *)defaultsDictionary
{
    // TODO: must be able to expand tildes in paths for this to work
    return @{pictureDirectoryKey: @"~/Desktop",
             pictureChangeIntervalKey: @5.0};
}

@end
