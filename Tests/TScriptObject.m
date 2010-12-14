//
//  TScriptObject.m
//  GAJavaScript
//
//  Created by Andrew on 12/11/10.
//  Copyright 2010 Goodale Software. All rights reserved.
//

#import "TScriptObject.h"
#import "GAScriptObject.h"
#import "UIWebView+GAJavaScript.h"

@implementation TScriptObject

- (BOOL)shouldRunOnMainThread 
{
	// By default NO, but if you have a UI test or test dependent on running on the main thread return YES
	return YES;
}

- (void)setUp
{
	UIApplication* app = [UIApplication sharedApplication];
	UIWindow* mainWindow = app.keyWindow;
	CGRect webFrame = [[UIScreen mainScreen] applicationFrame];
	
	m_webView = [[UIWebView alloc] initWithFrame:webFrame];
	m_webView.delegate = self;
	m_webView.hidden = YES;
	[mainWindow addSubview:m_webView];	

	[m_webView loadHTMLString:@"<html><body><p>Hello World</p></body></html>" baseURL:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// Load the GAJavaScript runtime here
	[webView loadScriptRuntime];
	
	[self performSelector:m_curTest];
}

- (void)testKeyValueCoding
{
	[self prepare];
	m_curTest = @selector(finishKeyValueCoding);
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:3.0];
}

- (void)finishKeyValueCoding
{
	NSArray* kTestValues = [NSArray arrayWithObjects:
							@"abcd", 
							@"string 'with' quotes",
							[NSNumber numberWithInt:400000],
							[NSNumber numberWithFloat:0.55555],
							[NSNull null],
							[NSNumber numberWithBool:YES],
							[NSDate date],
							nil];
	
	NSInteger status = kGHUnitWaitStatusSuccess;
	GAScriptObject* jsObject = [[GAScriptObject alloc] initForReference:@"location" view:m_webView];

	for (id testValue in kTestValues)
	{
		[jsObject setValue:testValue forKey:@"js_test"];
		id gotValue = [jsObject valueForKey:@"js_test"];
		
		// I don't know why regular isEqual: and compare: don't work for floating point numbers,
		// so I need to compare the decimal values specifically. Weird.
		if ([testValue isKindOfClass:[NSNumber class]])
		{
			NSDecimal dec1 = [testValue decimalValue];
			NSDecimal dec2 = [gotValue decimalValue];
			
			if (NSDecimalCompare(&dec1, &dec2) != NSOrderedSame)
				status = kGHUnitWaitStatusFailure;
		}
		else if (![gotValue isEqual:testValue])
		{
			status = kGHUnitWaitStatusFailure;		
			GHTestLog(@"get/setValue failed for %@", testValue);
		}
	}
	
	[self notify:status forSelector:@selector(testKeyValueCoding)];	
	[jsObject release];
}

- (void)testAllKeys
{
	[self prepare];
	m_curTest = @selector(finishAllKeys);

	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:3.0];
}

- (void)finishAllKeys
{
	NSInteger status = kGHUnitWaitStatusSuccess;

	GAScriptObject* jsObject = [[GAScriptObject alloc] initForReference:@"location" view:m_webView];
	NSArray* allKeys = [jsObject allKeys];
		
	if (allKeys == nil)
		status = kGHUnitWaitStatusFailure;
	if ([allKeys count] == 0)
		status = kGHUnitWaitStatusFailure;
	if ([allKeys containsObject:@"hostname"] == NO)
		status = kGHUnitWaitStatusFailure;
	
	[self notify:status forSelector:@selector(testAllKeys)];	
	[jsObject release];
}

- (void)testFastEnumeration
{
	[self prepare];
	m_curTest = @selector(finishFastEnumeration);
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:3.0];	
}

- (void)finishFastEnumeration
{
	NSInteger status = kGHUnitWaitStatusFailure;
	
	GAScriptObject* jsObject = [[GAScriptObject alloc] initForReference:@"location" view:m_webView];

	for (id key in jsObject)
	{
		if ([key isEqual:@"hostname"])
			status = kGHUnitWaitStatusSuccess;
	}

	[self notify:status forSelector:@selector(testFastEnumeration)];	
	[jsObject release];
}

- (void)testInvokeMethod
{
	[self prepare];
	m_curTest = @selector(finishInvokeMethod);
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:3.0];		
}

- (void)finishInvokeMethod
{
	NSInteger status = kGHUnitWaitStatusSuccess;

	GAScriptObject* jsObject = [[GAScriptObject alloc] initForReference:@"document" view:m_webView];
	id retVal = [jsObject invokeMethod:@"createElement" withObject:@"strong"];

	if (![retVal isKindOfClass:[GAScriptObject class]])
		status = kGHUnitWaitStatusFailure;
	
	[self notify:status forSelector:@selector(testInvokeMethod)];	
	[jsObject release];
}

@end