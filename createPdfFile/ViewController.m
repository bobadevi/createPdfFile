//
//  ViewController.m
//  createPdfFile
//
//  Created by sachita sharma on 26/06/16.
//  Copyright © 2016 sachita sharma. All rights reserved.
//

#define kDefaultPageHeight 792
#define kDefaultPageWidth  612

#import "ViewController.h"
#import <CoreText/CoreText.h>

@interface ViewController ()

@end

@implementation ViewController
@synthesize textView;
@synthesize pdfFilePath;
@synthesize savePdf;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Use Core Text to draw the text in a frame on the page.
- (CFRange)renderPage:(NSInteger)pageNum withTextRange:(CFRange)currentRange
       andFramesetter:(CTFramesetterRef)framesetter
{
    // Get the graphics context.
    CGContextRef    currentContext = UIGraphicsGetCurrentContext();
    
    // Put the text matrix into a known state. This ensures
    // that no old scaling factors are left in place.
    CGContextSetTextMatrix(currentContext, CGAffineTransformIdentity);
    
    // Create a path object to enclose the text. Use 72 point
    // margins all around the text.
    CGRect    frameRect = CGRectMake(100, 100, 368, 648);
    CGMutablePathRef framePath = CGPathCreateMutable();
    CGPathAddRect(framePath, NULL, frameRect);
    
    // Get the frame that will do the rendering.
    // The currentRange variable specifies only the starting point. The framesetter
    // lays out as much text as will fit into the frame.
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, currentRange, framePath, NULL);
    CGPathRelease(framePath);
    
    // Core Text draws from the bottom-left corner up, so flip
    // the current transform prior to drawing.
    CGContextTranslateCTM(currentContext, 0, kDefaultPageHeight);
    CGContextScaleCTM(currentContext, 1.0, -1.0);
    
    // Draw the frame.
    CTFrameDraw(frameRef, currentContext);
    
    // Update the current range based on what was drawn.
    currentRange = CTFrameGetVisibleStringRange(frameRef);
    currentRange.location += currentRange.length;
    currentRange.length = 0;
    CFRelease(frameRef);
    
    return currentRange;
}

- (void)drawPageNumber:(NSInteger)pageNum
{
    NSString* pageString = [NSString stringWithFormat:@"Page %ld", (long)pageNum];
    UIFont* theFont = [UIFont systemFontOfSize:25];
    // CGSize maxSize = CGSizeMake(kDefaultPageWidth, 72);
    
    
    CGSize pageStringSize = [pageString sizeWithAttributes:
                             @{NSFontAttributeName:
                                   theFont}];
    
    //  CGSize pageStringSize = [pageString sizeWithFont:theFont
    //   constrainedToSize:maxSize
    //       lineBreakMode:NSLineBreakByClipping];
    CGRect stringRect = CGRectMake(((kDefaultPageWidth - pageStringSize.width) / 2.0),
                                   720.0 + ((72.0 - pageStringSize.height) / 2.0) ,
                                   pageStringSize.width,
                                   pageStringSize.height);
    
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:15], NSParagraphStyleAttributeName: paragraphStyle};
    
    [pageString drawInRect:stringRect withAttributes:attributes];
    
    
    
    // [pageString drawInRect:stringRect withFont:theFont];
}

- (IBAction)savePDFFile:(id)sender
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"sampleData" ofType:@"plist"];
    
    // get a temprorary filename for this PDF
    //  path = NSTemporaryDirectory();
    // NSString* fileName = @"Invoice.pdf";
    
    
    NSArray *arrayPaths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
    path = [arrayPaths objectAtIndex:0];
    //  NSString* pdfFileName = [path stringByAppendingPathComponent:fileName];
    
    self.pdfFilePath = [path stringByAppendingPathComponent:
                        [NSString stringWithFormat:@"%f.pdf",
                         [[NSDate date]
                          timeIntervalSince1970] ]];
    // NSString *fileName = [self getPDFFileName];
    
  
    
    // Prepare the text using a Core Text Framesetter
    CFAttributedStringRef currentText = CFAttributedStringCreate(NULL,
                                                                 (CFStringRef)textView.text, NULL);
    CTFontRef font = CTFontCreateWithName((CFStringRef)@"Arial", 16.0f, nil);
    // CFAttributedStringSetAttribute(currentText,CFRangeMake(0, strLength-1), kCTFontAttributeName, font);
    
    if (currentText) {
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(currentText);
        if (framesetter) {
            
            NSString* pdfFileName = self.pdfFilePath; //[NSString stringWithString:@"test.pdf"];
            
            // Create the PDF context using the default page: currently constants at the size
            // of 612 x 792.
            UIGraphicsBeginPDFContextToFile(pdfFileName, CGRectZero, nil);
            
            CFRange currentRange = CFRangeMake(0, 0);
            NSInteger currentPage = 0;
            BOOL done = NO;
            
            do {
                // Mark the beginning of a new page.
                UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, kDefaultPageWidth,
                                                          kDefaultPageHeight), nil);
                
                // Draw a page number at the bottom of each page
                currentPage++;
                [self drawPageNumber:currentPage];
                
                // Render the current page and update the current range to
                // point to the beginning of the next page.
                currentRange = [self renderPage:currentPage withTextRange:
                                currentRange andFramesetter:framesetter];
                
                // If we're at the end of the text, exit the loop.
                if (currentRange.location == CFAttributedStringGetLength
                    ((CFAttributedStringRef)currentText))
                    done = YES;
            } while (!done);
            
            // Close the PDF context and write the contents out.
            UIGraphicsEndPDFContext();
            
            // Release the framewetter.
            CFRelease(framesetter);
            
        } else {
            NSLog(@"Could not create the framesetter needed to lay out the atrributed string.");
        }
        // Release the attributed string.
        CFRelease(currentText);
    } else {
        NSLog(@"Could not create the attributed string for the framesetter");
    }
    // Ask the user if they'd like to see the file or email it.
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Would you like to preview or email this PDF?"
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:@"Preview", @"Email", nil];
    [actionSheet showInView:self.view];
    

}
#pragma mark - MFMailComposerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"Action Sheet button %ld", (long)buttonIndex);
    
    if (buttonIndex == 0) {
        
        // present a preview of this PDF File.
        QLPreviewController* preview = [[QLPreviewController alloc] init];
        preview.dataSource = self;
        [self presentModalViewController:preview animated:YES];
        
    }
    else if(buttonIndex == 1)
    {
        // email the PDF File.
        MFMailComposeViewController* mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        [mailComposer addAttachmentData:[NSData dataWithContentsOfFile:self.pdfFilePath]
                               mimeType:@"application/pdf" fileName:@"report.pdf"];
        
        [self presentModalViewController:mailComposer animated:YES];
    }
    
}

#pragma mark - QLPreviewControllerDataSource
- (NSInteger) numberOfPreviewItemsInPreviewController: (QLPreviewController *) controller
{
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    return [NSURL fileURLWithPath:self.pdfFilePath];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


