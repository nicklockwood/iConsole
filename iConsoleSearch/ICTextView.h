/**
* ICTextView.h
* ------------
* https://github.com/Exile90/ICTextView.git
*
*
* Version:
* --------
* 1.1.0
*
*
* Authors:
* --------
* - Ivano Bilenchi (@SoftHardW)
*
*
* Description:
* ------------
* ICTextView is a UITextView subclass with optimized support for string/regex search and highlighting.
* It also features some iOS 7 specific improvements and bugfixes to the standard UITextView.
* 
*
* Features:
* ---------
* + Support for string and regex search and highlighting
* * Highly customizable
* * Doesn't use delegate methods (you can still implement your own)
* + Methods to account for contentInsets in iOS 7
* * Contains workarounds for many known iOS 7 UITextView bugs
*
*
* Compatibility:
* --------------
* ICTextView is compatible with iOS 4.x and above.
* It can be compiled with any iOS SDK starting from 5.x.
* Match highlighting is supported starting from iOS 5.x.
*
* !!!WARNING!!! - contains ARC enabled code. Beware, MRC purists.
*
*
* Configuration:
* --------------
* See comments in the `#pragma mark - Configuration` section.
*
*
* Usage:
* ------
*
*   Search:
*   -------
*   Searches can be performed via the `scrollToMatch:` and `scrollToString:` methods.
*   `scrollToMatch:` performs regex searches, while `scrollToString:` searches for string literals.
*
*   Both search methods are regex-powered, and therefore make use of `NSRegularExpressionOptions`.
*   They both support animation, range restriction and custom end scroll positioning.
*   See the `#pragma mark - Constants` section for further info about the `atScrollPosition:` parameter.
*
*   If a match is found, ICTextView highlights a primary match, and starts highlighting other matches while the user scrolls.
*   Searching for the same pattern multiple times will automatically match the next result, you don't need to update the range argument.
*   In fact, you should only specify it if you wish to restrict the search to a specific text range.
*   Search is optimized when the specified range and search pattern do not change (aka repeated searches).
*
*   The `rangeOfFoundString` property contains the range of the current search match.
*   You can get the actual string by calling the `foundString` method.
*
*   The `resetSearch` method lets you restore the search variables to their starting values, effectively resetting the search.
*   Calls to `resetSearch` cause the highlights to be deallocated, regardless of the `maxHighlightedMatches` variable.
*   After this method has been called, ICTextView stops highlighting results until a new search is performed.
*
*
*   Content insets methods:
*   -----------------------
*   The `scrollRangeToVisible:consideringInsets:[...]` and `scrollRectToVisible:animated:consideringInsets:[...]` methods
*   let you scroll until a certain range or rect is visible, eventually accounting for content insets.
*   This was the default behavior for `scrollRangeToVisible:` before iOS 7, but it has changed since (possibly because of a bug).
*   These methods support animation and scroll positioning, similarly to the search methods.
*
*   The other methods are pretty much self-explanatory. See the `#pragma mark - Misc` section for further info.
*
*
* iOS 7 UITextView Bugfixes
* -------------------------
* Long story short, iOS 7 completely broke `UITextView`. `ICTextView` contains fixes for some very common issues:
*
* - NSTextContainer bugfix: `UITextView` initialized via `initWithFrame:` had an erratic behavior due to an uninitialized or wrong `NSTextContainer`
* - Caret bugfix: the caret didn't consider `contentInset` and often went out of the visible area
* - characterRangeAtPoint bugfix: `characterRangeAtPoint:` always returned `nil`
*
* These fixes, combined with the custom methods to account for `contentInset`, should make working with `ICTextView` much more bearable
* than working with the standard `UITextView`.
*
* Bugfixes introduced by `ICTextView` will be removed (or isolated) as soon as they are fixed by Apple.
*
*
* License:
* --------
* Copyright (c) 2013-2014 Ivano Bilenchi
*
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without
* restriction, including without limitation the rights to use,
* copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following
* conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
**/

#import <UIKit/UIKit.h>

#pragma mark Constants

typedef enum
{
    ICTextViewScrollPositionNone,       // Scrolls until the rect/range/text is visible with minimal movement
    ICTextViewScrollPositionTop,        // Scrolls until the rect/range/text is on top of the text view
    ICTextViewScrollPositionMiddle,     // Scrolls until the rect/range/text is in the middle of the text view
    ICTextViewScrollPositionBottom      // Scrolls until the rect/range/text is at the bottom of the text view
} ICTextViewScrollPosition;

#pragma mark - Interface

@interface ICTextView : UITextView


#pragma mark - Configuration

#pragma mark -- General --

// Toggles highlights for search results (default = YES // NO = only scrolls)
@property (nonatomic) BOOL highlightSearchResults;

#pragma mark -- Appearance --

// Color of the primary search highlight (default = RGB 150/200/255)
@property (nonatomic, strong) UIColor *primaryHighlightColor;

// Color of the secondary search highlights (default = RGB 215/240/255)
@property (nonatomic, strong) UIColor *secondaryHighlightColor;

// Highlight corner radius (default = fontSize * 0.2)
@property (nonatomic) CGFloat highlightCornerRadius;

#pragma mark -- Performance --

// Maximum number of cached highlighted matches (default = 100)
// Note 1: setting this too high will impact memory usage
// Note 2: this value is indicative. More search results will be highlighted if they are on-screen
@property (nonatomic) NSUInteger maxHighlightedMatches;

// Delay for the auto-refresh while scrolling feature (default = 0.2 // min = 0.1 // off = 0.0)
// Note: decreasing/disabling this may improve performance when self.text is very big
@property (nonatomic) NSTimeInterval scrollAutoRefreshDelay;

#pragma mark -- Output --

// Range of string found during last search ({0, 0} on init and after resetSearch // {NSNotFound, 0} if not found)
@property (nonatomic, readonly) NSRange rangeOfFoundString;

// The total number of the matching text
@property (nonatomic, assign) NSUInteger matchingCount;

#pragma mark - Usage

#pragma mark -- Search --

// Returns string found during last search
- (NSString *)foundString;

// Resets search, starts from top
- (void)resetSearch;

// Scrolls to regex match (returns YES if found, NO otherwise)
- (BOOL)scrollToMatch:(NSString *)pattern;
- (BOOL)scrollToMatch:(NSString *)pattern searchOptions:(NSRegularExpressionOptions)options;
- (BOOL)scrollToMatch:(NSString *)pattern searchOptions:(NSRegularExpressionOptions)options range:(NSRange)range;
- (BOOL)scrollToMatch:(NSString *)pattern searchOptions:(NSRegularExpressionOptions)options animated:(BOOL)animated atScrollPosition:(ICTextViewScrollPosition)scrollPosition;
- (BOOL)scrollToMatch:(NSString *)pattern searchOptions:(NSRegularExpressionOptions)options range:(NSRange)range animated:(BOOL)animated atScrollPosition:(ICTextViewScrollPosition)scrollPosition;

// Scrolls to string (returns YES if found, NO otherwise)
- (BOOL)scrollToString:(NSString *)stringToFind;
- (BOOL)scrollToString:(NSString *)stringToFind searchOptions:(NSRegularExpressionOptions)options;
- (BOOL)scrollToString:(NSString *)stringToFind searchOptions:(NSRegularExpressionOptions)options range:(NSRange)range;
- (BOOL)scrollToString:(NSString *)stringToFind searchOptions:(NSRegularExpressionOptions)options animated:(BOOL)animated atScrollPosition:(ICTextViewScrollPosition)scrollPosition;
- (BOOL)scrollToString:(NSString *)stringToFind searchOptions:(NSRegularExpressionOptions)options range:(NSRange)range animated:(BOOL)animated atScrollPosition:(ICTextViewScrollPosition)scrollPosition;

#pragma mark -- Misc --

// Scrolls to visible range, eventually considering insets
- (void)scrollRangeToVisible:(NSRange)range consideringInsets:(BOOL)considerInsets;
- (void)scrollRangeToVisible:(NSRange)range consideringInsets:(BOOL)considerInsets animated:(BOOL)animated atScrollPosition:(ICTextViewScrollPosition)scrollPosition;

// Scrolls to visible rect, eventually considering insets
- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated consideringInsets:(BOOL)considerInsets;
- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated consideringInsets:(BOOL)considerInsets atScrollPosition:(ICTextViewScrollPosition)scrollPosition;

// Returns visible range, with start and end position, eventually considering insets
- (NSRange)visibleRangeConsideringInsets:(BOOL)considerInsets;
- (NSRange)visibleRangeConsideringInsets:(BOOL)considerInsets startPosition:(UITextPosition *__autoreleasing *)startPosition endPosition:(UITextPosition *__autoreleasing *)endPosition;

// Returns visible rect, eventually considering insets
- (CGRect)visibleRectConsideringInsets:(BOOL)considerInsets;

@end
