//
//  PictureScreenSaverView.m
//  PictureScreenSaver
//
//  Created by Erik Larsen on 2/25/15.
//  Copyright (c) 2015 Erik Larsen. All rights reserved.
//


#import "PictureScreenSaver.h"

static NSString * const pictureDirectoryKey = @"pictureDirectory";
static NSString * const pictureChangeIntervalKey = @"pictureIntervalChange";
static double const shuffleTimeInterval = 60.0 * 60.0 * 24.0; // shuffle the photos every 24 hours

@interface PictureScreenSaver()

@property (nonatomic) NSTimeInterval changeTimeInterval;
@property (nonatomic) NSTimeInterval currentTimeInterval;
@property (nonatomic) NSTimeInterval currentShuffleTimeInterval;
@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSMutableArray *files;
@property (nonatomic) int currentIndex;
@property (strong, nonatomic) NSImage *currentImage;
@property (strong, nonatomic) NSString *bundleIdentifier;
@property (strong, nonatomic) ScreenSaverDefaults *defaults;
@end

@implementation PictureScreenSaver

#pragma mark - Properties

- (NSMutableArray *)files
{
    if(!_files)
    {
        _files = [[NSMutableArray alloc] init];
    }
    return _files;
}
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

        [self.defaults registerDefaults:[PictureScreenSaver defaultsDictionary]];
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

    self.files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error]  mutableCopy];

    [self shuffleFiles];
    NSLog(@"Total # of files: %lu", (unsigned long)self.files.count);
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    CGFloat height, width;

    [super drawRect:rect];
    if(self.currentImage)
    {

        CGFloat centerX, centerY;

        CGFloat horizontalScaleFactor = rect.size.width / self.currentImage.size.width;
        CGFloat verticalScaleFactor = rect.size.height / self.currentImage.size.height;
        CGFloat scaleFactor;

        if(verticalScaleFactor < horizontalScaleFactor)
        {
            scaleFactor = verticalScaleFactor;
        }
        else
        {
            scaleFactor = horizontalScaleFactor;
        }

        width = self.currentImage.size.width * scaleFactor;
        height = self.currentImage.size.height * scaleFactor;

        centerX = (rect.size.width / 2.0) - (width / 2.0);
        centerY = (rect.size.height / 2.0) - (height / 2.0);


        NSRect newRect = CGRectMake(centerX, centerY, width,
                                 height);
        [self.currentImage drawInRect:newRect];
        NSLog(@"Drawing %@ (%@) in rect: %@", self.files[self.currentIndex],
              NSStringFromSize(self.currentImage.size), NSStringFromRect(newRect));

    }
}

- (void)animateOneFrame
{
    if(!self.files.count)
    {
        // Maybe put something up to say there are no displayable files in the directory
        return;
    }

    self.currentShuffleTimeInterval += self.animationTimeInterval;
    if(self.currentShuffleTimeInterval >= shuffleTimeInterval)
    {
        self.currentShuffleTimeInterval = 0.0;
        [self shuffleFiles];
    }


    self.currentTimeInterval += self.animationTimeInterval;
    if(self.currentTimeInterval > self.changeTimeInterval)
    {
        BOOL invalidImage;
        do
        {
            if(!invalidImage)
            {
                self.currentIndex++;
            }
            if(self.currentIndex >= self.files.count)
            {
                self.currentIndex = 0;
            }

            invalidImage = NO;

            self.currentImage = [[NSImage alloc]
                                 initByReferencingFile:[self.path stringByAppendingPathComponent:self.files[self.currentIndex]]];
            if(!self.currentImage.isValid)
            {
                NSLog(@"Removing bad image: %@", self.files[self.currentIndex]);
                NSLog(@"Images remaining: %lu", (unsigned long)self.files.count);
                [self.files removeObjectAtIndex:self.currentIndex];
                invalidImage = YES;
            }
            else
            {
                [self regenerateImage];
                if(!self.currentImage)
                {
                    NSLog(@"Removing bad image: %@", self.files[self.currentIndex]);
                    [self.files removeObjectAtIndex:self.currentIndex];
                    NSLog(@"Images remaining: %lu", (unsigned long)self.files.count);
                    invalidImage = YES;
                }
            }

        } while(invalidImage);


        [self setNeedsDisplay:YES];


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

    for(int i = 0; i < [PictureScreenSaver intervalNames].count; i++)
    {
        NSString *key = [PictureScreenSaver intervalNames][i];
        if(loadedBundle == YES) // Only add the items if we just loaded the window
        {
            [self.pictureChangeIntervalComboBox addItemWithObjectValue:key];
        }
        if(fabs(self.changeTimeInterval -
                [[PictureScreenSaver intervalLengths][i] doubleValue]) < 0.01)
        {
            [self.pictureChangeIntervalComboBox selectItemWithObjectValue:key];
        }
    }

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

    NSNumber *selectedInterval = [PictureScreenSaver intervalLengths][self.pictureChangeIntervalComboBox.indexOfSelectedItem];
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

- (void)regenerateImage
{
    NSInteger repWidth = 0;
    NSInteger repHeight = 0;
    for(NSImageRep *rep in self.currentImage.representations)
    {
        NSLog(@"Image rep width: %ld height: %ld", (long)rep.pixelsWide, (long)rep.pixelsHigh);
        if([rep pixelsWide] > repWidth)
        {
            repWidth = [rep pixelsWide];
            repHeight = [rep pixelsHigh];
        }
    }
    if(repWidth == 0 || repHeight == 0)
    {
        NSLog(@"Bad image with width and height = 0");
        self.currentImage = nil;
        return;
    }
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(repWidth, repHeight)];
    [image addRepresentations:self.currentImage.representations];
    self.currentImage = image;

}

- (void)shuffleFiles
{
    NSMutableArray *files = [self.files mutableCopy];

    [self.files removeAllObjects];

    while(files.count)
    {
        int index = arc4random_uniform((int)files.count);
        [self.files addObject:files[index]];
        [files removeObjectAtIndex:index];
    }
}

//+ (NSDictionary *)comboBoxToInterval
//{
//    return @{@"5 seconds": @5.0,
//             @"Minute": @60,
//             @"10 minutes": @(60 * 10),
//             @"15 minutes": @(60 * 15),
//             @"30 minutes": @(60 * 30),
//             @"Hour": @(60 * 60),
//             @"4 hours": @(60 * 60 * 4),
//             @"8 hours": @(60 * 60 * 8),
//             @"Day": @(60 *60 * 24)};
//}
//
// Want to use a dictionary, but keys are in hash order

+ (NSArray *)intervalNames
{
    return @[@"5 seconds",
             @"Minute",
             @"10 minutes",
             @"15 minutes",
             @"30 minutes",
             @"Hour",
             @"4 hours",
             @"8 hours",
             @"Day"];
}

+ (NSArray *)intervalLengths
{
    return @[@5.0,
             @60,
             @(60 * 10),
             @(60 * 15),
             @(60 * 30),
             @(60 * 60),
             @(60 * 60 * 4),
             @(60 * 60 * 8),
             @(60 *60 * 24)];

}

+ (NSDictionary *)defaultsDictionary
{
    // TODO: must be able to expand tildes in paths for this to work
    return @{pictureDirectoryKey: @"~/Desktop",
             pictureChangeIntervalKey: @5.0};
}

@end
