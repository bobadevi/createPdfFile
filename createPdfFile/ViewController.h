//
//  ViewController.h
//  createPdfFile
//
//  Created by sachita sharma on 26/06/16.
//  Copyright © 2016 sachita sharma. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <MessageUI/MessageUI.h>
#import <QuickLook/QuickLook.h>

@interface ViewController : UIViewController <MFMailComposeViewControllerDelegate, UIActionSheetDelegate, QLPreviewControllerDataSource>{
    UITextView *textView;
    NSString* pdfFilePath;
}

@property (nonatomic, retain) NSString* pdfFilePath;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIButton *savePdf;

- (IBAction)savePDFFile:(id)sender;

@end
