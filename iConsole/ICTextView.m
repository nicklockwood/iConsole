/**
* ICTextView.m - 1.1.0
* --------------------
*
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

#import "ICTextView.h"
#import <QuartzCore/QuartzCore.h>

// For old SDKs
#ifndef NSFoundationVersionNumber_iOS_5_0
#define NSFoundationVersionNumber_iOS_5_0 881.00
#endif

#ifndef NSFoundationVersionNumber_iOS_6_0
#define NSFoundationVersionNumber_iOS_6_0 993.00
#endif

#ifndef NSFoundationVersionNumber_iOS_6_1
#define NSFoundationVersionNumber_iOS_6_1 993.00
#endif

// Debug logging
#if DEBUG
#define ICTextViewLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define ICTextViewLog(...)
#endif

#pragma mark Constants

enum
{
    ICTagTextSubview = 181337
};

#pragma mark - Globals

// Search results highlighting supported starting from iOS 5.x
static BOOL highlightingSupported;

#pragma mark - Extension

@interface ICTextView ()
{
    // Highlights
    NSMutableDictionary *_highlightsByRange;
    NSMutableArray *_primaryHighlights;
    NSMutableOrderedSet *_secondaryHighlights;
    
    // Work variables
    NSRegularExpression *_regex;
    NSTimer *_autoRefreshTimer;
    NSRange _searchRange;
    NSUInteger _scanIndex;
    BOOL _performedNewScroll;
    BOOL _shouldUpdateScanIndex;
    
    // TODO: remove iOS 7 bugfixes when an official fix is available
    BOOL _appliedCharacterRangeAtPointBugfix;
}
@end

#pragma mark - Implementation

@implementation ICTextView

#pragma mark - Synthesized properties

@synthesize primaryHighlightColor = _primaryHighlightColor;
@synthesize secondaryHighlightColor = _secondaryHighlightColor;
@synthesize highlightCornerRadius = _highlightCornerRadius;
@synthesize highlightSearchResults = _highlightSearchResults;
@synthesize maxHighlightedMatches = _maxHighlightedMatches;
@synthesize scrollAutoRefreshDelay = _scrollAutoRefreshDelay;
@synthesize rangeOfFoundString = _rangeOfFoundString;

#pragma mark - Class methods

+ (void)initialize
{
    if (self == [ICTextView class])
        highlightingSupported = [self conformsToProtocol:@protocol(UITextInput)];
}

#pragma mark - Private methods

// Return value: highlight UIView
- (UIView *)addHighlightAtRect:(CGRect)frame
{
    UIView *highlight = [[UIView alloc] initWithFrame:frame];
    highlight.layer.cornerRadius = _highlightCornerRadius < 0.0 ? frame.size.height * 0.2 : _highlightCornerRadius;
    highlight.backgroundColor = _secondaryHighlightColor;
    [_secondaryHighlights addObject:highlight];
    [self insertSubview:highlight belowSubview:[self viewWithTag:ICTagTextSubview]];
    return highlight;
}

// Return value: array of highlights for text range
- (NSMutableArray *)addHighlightAtTextRange:(UITextRange *)textRange
{
    NSMutableArray *highlightsForRange = [[NSMutableArray alloc] init];
    
#ifdef __IPHONE_6_0
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_6_0)
    {
        // iOS 6.x+ implementation
        CGRect previousRect = CGRectZero;
        NSArray *highlightRects = [self selectionRectsForRange:textRange];
        // Merge adjacent rects
        for (UITextSelectionRect *selectionRect in highlightRects)
        {
            CGRect currentRect = selectionRect.rect;
            if ((currentRect.origin.y == previousRect.origin.y) && (currentRect.origin.x == CGRectGetMaxX(previousRect)) && (currentRect.size.height == previousRect.size.height))
            {
                // Adjacent, add to previous rect
                previousRect = CGRectMake(previousRect.origin.x, previousRect.origin.y, previousRect.size.width + currentRect.size.width, previousRect.size.height);
            }
            else
            {
                // Not adjacent, add previous rect to highlights array
                [highlightsForRange addObject:[self addHighlightAtRect:previousRect]];
                previousRect = currentRect;
            }
        }
        // Add last highlight
        [highlightsForRange addObject:[self addHighlightAtRect:previousRect]];
    }
    else
#endif
    {
        // iOS 5.x implementation (a bit slower)
        CGRect previousRect = CGRectZero;
        UITextPosition *start = textRange.start;
        UITextPosition *end = textRange.end;
        id <UITextInputTokenizer> tokenizer = [self tokenizer];
        BOOL hasMoreLines;
        do {
            UITextPosition *lineEnd = [tokenizer positionFromPosition:start toBoundary:UITextGranularityLine inDirection:UITextStorageDirectionForward];
            
            // Check if string is on multiple lines
            if ([self offsetFromPosition:lineEnd toPosition:end] <= 0)
            {
                hasMoreLines = NO;
                textRange = [self textRangeFromPosition:start toPosition:end];
            }
            else
            {
                hasMoreLines = YES;
                textRange = [self textRangeFromPosition:start toPosition:lineEnd];
                start = lineEnd;
            }
            previousRect = [self firstRectForRange:textRange];
            [highlightsForRange addObject:[self addHighlightAtRect:previousRect]];
        } while (hasMoreLines);
    }
    return highlightsForRange;
}

- (void)removeHighlightsTooFarFromRange:(NSRange)range
{
    NSInteger tempMin = range.location - range.length;
    NSUInteger min = tempMin > 0 ? tempMin : 0;
    NSUInteger max = min + 3 * range.length;
    
    // Scan highlighted ranges
    NSMutableArray *keysToRemove = [[NSMutableArray alloc] init];
    [_highlightsByRange enumerateKeysAndObjectsUsingBlock:^(NSValue *rangeValue, NSArray *highlightsForRange, BOOL *stop){
        
        // Selectively remove highlights
        NSUInteger location = [rangeValue rangeValue].location;
        if ((location < min || location > max) && location != _rangeOfFoundString.location)
        {
            for (UIView *hl in highlightsForRange)
            {
                [hl removeFromSuperview];
                [_secondaryHighlights removeObject:hl];
            }
            [keysToRemove addObject:rangeValue];
        }
    }];
    [_highlightsByRange removeObjectsForKeys:keysToRemove];
}

// Highlight occurrences of found string in visible range masked by the user specified range
- (void)highlightOccurrencesInMaskedVisibleRange
{
    if (!_regex)
        return;
    
    if (_performedNewScroll)
    {
        // Initial data
        UITextPosition *visibleStartPosition;
        NSRange visibleRange = [self visibleRangeConsideringInsets:YES startPosition:&visibleStartPosition endPosition:NULL];
        
        // Perform search in masked range
        NSRange maskedRange = NSIntersectionRange(_searchRange, visibleRange);
        NSMutableArray *rangeValues = [[NSMutableArray alloc] init];
        [_regex enumerateMatchesInString:self.text options:0 range:maskedRange usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
            NSValue *rangeValue = [NSValue valueWithRange:match.range];
            [rangeValues addObject:rangeValue];
        }];
        
        ///// ADD SECONDARY HIGHLIGHTS /////
        
        if (rangeValues.count)
        {
            // Remove already present highlights
            NSMutableArray *rangesArray = [rangeValues mutableCopy];
            NSMutableIndexSet *indexesToRemove = [[NSMutableIndexSet alloc] init];
            [rangeValues enumerateObjectsUsingBlock:^(NSValue *rangeValue, NSUInteger idx, BOOL *stop){
                if ([_highlightsByRange objectForKey:rangeValue])
                    [indexesToRemove addIndex:idx];
            }];
            [rangesArray removeObjectsAtIndexes:indexesToRemove];
            indexesToRemove = nil;
            
            if (rangesArray.count)
            {
                // Get text range of first result
                NSValue *firstRangeValue = [rangesArray objectAtIndex:0];
                NSRange previousRange = [firstRangeValue rangeValue];
                UITextPosition *start = [self positionFromPosition:visibleStartPosition offset:(previousRange.location - visibleRange.location)];
                UITextPosition *end = [self positionFromPosition:start offset:previousRange.length];
                UITextRange *textRange = [self textRangeFromPosition:start toPosition:end];
                
                // First range
                [_highlightsByRange setObject:[self addHighlightAtTextRange:textRange] forKey:firstRangeValue];
                
                if (rangesArray.count > 1)
                {
                    for (NSUInteger idx = 1; idx < rangesArray.count; idx++)
                    {
                        NSValue *rangeValue = [rangesArray objectAtIndex:idx];
                        NSRange range = [rangeValue rangeValue];
                        start = [self positionFromPosition:end offset:range.location - (previousRange.location + previousRange.length)];
                        end = [self positionFromPosition:start offset:range.length];
                        textRange = [self textRangeFromPosition:start toPosition:end];
                        [_highlightsByRange setObject:[self addHighlightAtTextRange:textRange] forKey:rangeValue];
                        previousRange = range;
                    }
                }
                
                // Memory management
                NSInteger remaining = _maxHighlightedMatches - _highlightsByRange.count;
                if (remaining < 0)
                    [self removeHighlightsTooFarFromRange:visibleRange];
            }
        }
        
        // Eventually update _scanIndex to match visible range
        if (_shouldUpdateScanIndex)
            _scanIndex = maskedRange.location + (_regex ? maskedRange.length : 0);
    }
    
    [self setPrimaryHighlightAtRange:_rangeOfFoundString];
}

// Used in init overrides
- (void)initialize
{
    _highlightCornerRadius = -1.0;
    _highlightsByRange = [[NSMutableDictionary alloc] init];
    _highlightSearchResults = YES;
    _maxHighlightedMatches = 100;
    _scrollAutoRefreshDelay = 0.2;
    _primaryHighlights = [[NSMutableArray alloc] init];
    _primaryHighlightColor = [UIColor colorWithRed:150.0/255.0 green:200.0/255.0 blue:1.0 alpha:1.0];
    _secondaryHighlights = [[NSMutableOrderedSet alloc] init];
    _secondaryHighlightColor = [UIColor colorWithRed:215.0/255.0 green:240.0/255.0 blue:1.0 alpha:1.0];
    
    // Detect _UITextContainerView or UIWebDocumentView (subview with text) for highlight placement
    for (UIView *view in self.subviews)
    {
        if ([view isKindOfClass:NSClassFromString(@"_UITextContainerView")] || [view isKindOfClass:NSClassFromString(@"UIWebDocumentView")])
        {
            view.tag = ICTagTextSubview;
            break;
        }
    }
    
    // TODO: remove iOS 7 caret bugfix when an official fix is available
#ifdef __IPHONE_7_0
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textChanged)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:self];
    }
#endif
}

- (void)initializeHighlights
{
    [self initializePrimaryHighlights];
    [self initializeSecondaryHighlights];
}

- (void)initializePrimaryHighlights
{
    // Move primary highlights to secondary highlights array
    for (UIView *hl in _primaryHighlights)
    {
        hl.backgroundColor = _secondaryHighlightColor;
        [_secondaryHighlights addObject:hl];
    }
    [_primaryHighlights removeAllObjects];
}

- (void)initializeSecondaryHighlights
{
    for (UIView *hl in _secondaryHighlights)
        [hl removeFromSuperview];
    [_secondaryHighlights removeAllObjects];
    
    // Remove all objects in _highlightsByRange, except _rangeOfFoundString (primary)
    if (_primaryHighlights.count)
    {
        NSValue *rangeValue = [NSValue valueWithRange:_rangeOfFoundString];
        NSMutableArray *primaryHighlights = [_highlightsByRange objectForKey:rangeValue];
        [_highlightsByRange removeAllObjects];
        [_highlightsByRange setObject:primaryHighlights forKey:rangeValue];
    }
    else
        [_highlightsByRange removeAllObjects];
    
    // This allows highlights to be refreshed
    _performedNewScroll = YES;
}

// TODO: remove iOS 7 characterRangeAtPoint: bugfix when an official fix is available
#ifdef __IPHONE_7_0
- (void)characterRangeAtPointBugFix
{
    [self select:self];
    [self setSelectedTextRange:nil];
    _appliedCharacterRangeAtPointBugfix = YES;
}
#endif

- (void)scrollEnded
{
    [self highlightOccurrencesInMaskedVisibleRange];
    
    [_autoRefreshTimer invalidate];
    _autoRefreshTimer = nil;
    
    _performedNewScroll = NO;
}

// Scrolls to y coordinate without breaking the frame and (eventually) insets
- (void)scrollToY:(CGFloat)y animated:(BOOL)animated consideringInsets:(BOOL)considerInsets
{
    CGFloat min = 0.0;
    CGFloat max = self.contentSize.height - self.bounds.size.height;
    
    if (considerInsets)
    {
        UIEdgeInsets contentInset = self.contentInset;
        min -= contentInset.top;
        max += contentInset.bottom;
    }
    
    // Calculates new content offset
    CGPoint contentOffset = self.contentOffset;
    
    if (y > max)
        contentOffset.y = max;
    else if (y < min)
        contentOffset.y = min;
    else
        contentOffset.y = y;
    
    [self setContentOffset:contentOffset animated:animated];
}

- (void)setPrimaryHighlightAtRange:(NSRange)range
{
    [self initializePrimaryHighlights];
    NSValue *rangeValue = [NSValue valueWithRange:range];
    NSMutableArray *highlightsForRange = [_highlightsByRange objectForKey:rangeValue];
    
    for (UIView *hl in highlightsForRange)
    {
        hl.backgroundColor = _primaryHighlightColor;
        [_primaryHighlights addObject:hl];
        [_secondaryHighlights removeObject:hl];
    }
}

// TODO: remove iOS 7 caret bugfix when an official fix is available
#ifdef __IPHONE_7_0
- (void)textChanged
{
    UITextRange *selectedTextRange = self.selectedTextRange;
    if (selectedTextRange)
        [self scrollRectToVisible:[self caretRectForPosition:selectedTextRange.end] animated:NO consideringInsets:YES];
}
#endif

#pragma mark - Overrides

// TODO: remove iOS 7 characterRangeAtPoint: bugfix when an official fix is available
#ifdef __IPHONE_7_0
- (void)awakeFromNib
{
    [super awakeFromNib];
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1 && !_appliedCharacterRangeAtPointBugfix)
        [self characterRangeAtPointBugFix];
}
#endif

- (BOOL)becomeFirstResponder
{
    // Reset search if editable
    if (self.editable)
        [self resetSearch];
    return [super becomeFirstResponder];
}

// TODO: remove iOS 7 caret bugfix when an official fix is available
#ifdef __IPHONE_7_0
- (void)dealloc
{
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1)
        [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#endif

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]) && highlightingSupported)
        [self initialize];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
#ifdef __IPHONE_7_0
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1)
        return [self initWithFrame:frame textContainer:nil];
    else
#endif
    {
        if ((self = [super initWithFrame:frame]) && highlightingSupported)
            [self initialize];
        return self;
    }
}

// TODO: remove iOS 7 NSTextContainer bugfix when an official fix is available
#ifdef __IPHONE_7_0
- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    NSTextStorage *textStorage = [[NSTextStorage alloc] init];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    if (!textContainer)
        textContainer = [[NSTextContainer alloc] initWithSize:frame.size];
    textContainer.heightTracksTextView = YES;
    [layoutManager addTextContainer:textContainer];
    
    if ((self = [super initWithFrame:frame textContainer:textContainer]) && highlightingSupported)
        [self initialize];
    return self;
}
#endif

- (void)setContentOffset:(CGPoint)contentOffset
{
    [super setContentOffset:contentOffset];
    if (highlightingSupported && _highlightSearchResults)
    {
        _performedNewScroll = YES;
        
        if (!_shouldUpdateScanIndex)
            _shouldUpdateScanIndex = ([self.panGestureRecognizer velocityInView:self].y != 0.0);
        
        // Eventually start auto-refresh timer
        if (_regex && _scrollAutoRefreshDelay && !_autoRefreshTimer)
        {
            _autoRefreshTimer = [NSTimer timerWithTimeInterval:_scrollAutoRefreshDelay target:self selector:@selector(highlightOccurrencesInMaskedVisibleRange) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:_autoRefreshTimer forMode:UITrackingRunLoopMode];
        }
        
        // Cancel previous request and perform new one
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollEnded) object:nil];
        [self performSelector:@selector(scrollEnded) withObject:nil afterDelay:0.1];
    }
}

- (void)setFrame:(CGRect)frame
{
    // Reset highlights on frame change
    if (highlightingSupported && _highlightsByRange.count)
        [self initializeHighlights];
    [super setFrame:frame];
}

// Don't allow _scrollAutoRefreshDelay values between 0.0 and 0.1
- (void)setScrollAutoRefreshDelay:(NSTimeInterval)scrollAutoRefreshDelay
{
    _scrollAutoRefreshDelay = (scrollAutoRefreshDelay > 0.0 && scrollAutoRefreshDelay < 0.1) ? 0.1 : scrollAutoRefreshDelay;
}

// TODO: remove iOS 7 caret bugfix when an official fix is available
#ifdef __IPHONE_7_0
- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
    [super setSelectedTextRange:selectedTextRange];
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1 && selectedTextRange)
        [self scrollRectToVisible:[self caretRectForPosition:selectedTextRange.end] animated:NO consideringInsets:YES];
}
#endif

// TODO: remove iOS 7 characterRangeAtPoint: bugfix when an official fix is available
#ifdef __IPHONE_7_0
- (void)setText:(NSString *)text
{
    [super setText:text];
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1 && !_appliedCharacterRangeAtPointBugfix && text.length > 1)
        [self characterRangeAtPointBugFix];
}
#endif

#pragma mark - Public methods

#pragma mark -- Search --

- (NSString *)foundString
{
    return [self.text substringWithRange:_rangeOfFoundString];
}

- (void)resetSearch
{
    if (highlightingSupported)
    {
        [self initializeHighlights];
        [_autoRefreshTimer invalidate];
        _autoRefreshTimer = nil;
    }
    _rangeOfFoundString = NSMakeRange(0,0);
    _regex = nil;
    _scanIndex = 0;
    _searchRange = NSMakeRange(0,0);
    _matchingCount = 0;
}

#pragma mark ---- Regex search ----

- (BOOL)scrollToMatch:(NSString *)pattern
{
    return [self scrollToMatch:pattern searchOptions:0 range:NSMakeRange(0, self.text.length) animated:YES atScrollPosition:ICTextViewScrollPositionNone];
}

- (BOOL)scrollToMatch:(NSString *)pattern searchOptions:(NSRegularExpressionOptions)options
{
    return [self scrollToMatch:pattern searchOptions:options range:NSMakeRange(0, self.text.length) animated:YES atScrollPosition:ICTextViewScrollPositionNone];
}

- (BOOL)scrollToMatch:(NSString *)pattern searchOptions:(NSRegularExpressionOptions)options range:(NSRange)range
{
    return [self scrollToMatch:pattern searchOptions:options range:range animated:YES atScrollPosition:ICTextViewScrollPositionNone];
}

- (BOOL)scrollToMatch:(NSString *)pattern searchOptions:(NSRegularExpressionOptions)options animated:(BOOL)animated atScrollPosition:(ICTextViewScrollPosition)scrollPosition
{
    return [self scrollToMatch:pattern searchOptions:options range:NSMakeRange(0, self.text.length) animated:animated atScrollPosition:scrollPosition];
}

- (BOOL)scrollToMatch:(NSString *)pattern searchOptions:(NSRegularExpressionOptions)options range:(NSRange)range animated:(BOOL)animated atScrollPosition:(ICTextViewScrollPosition)scrollPosition
{
    // Calculate valid range
    range = NSIntersectionRange(NSMakeRange(0, self.text.length), range);
    
    BOOL abort = NO;
    if (!pattern)
    {
        ICTextViewLog(@"Pattern cannot be nil.");
        abort = YES;
    }
    else if (range.length == 0)
    {
        ICTextViewLog(@"Specified range is out of bounds.");
        abort = YES;
    }
    if (abort)
    {
        [self resetSearch];
        return NO;
    }
    
    // Optimization and coherence checks
    BOOL samePattern = [pattern isEqualToString:_regex.pattern];
    BOOL sameOptions = (options == _regex.options);
    BOOL sameSearchRange = NSEqualRanges(range, _searchRange);
    
    // Regex allocation
    _searchRange = range;
    
    NSError *__autoreleasing error = nil;
    _regex = [[NSRegularExpression alloc] initWithPattern:pattern options:options error:&error];
    _matchingCount = [_regex numberOfMatchesInString:self.text options:NSMatchingReportCompletion range:range];
    if (error)
    {
        ICTextViewLog(@"Error while creating regex: %@", error);
        [self resetSearch];
        return NO;
    }
    
    // Reset highlights
    if (highlightingSupported && _highlightSearchResults)
    {
        [self initializePrimaryHighlights];
        if (!(samePattern && sameOptions && sameSearchRange))
            [self initializeSecondaryHighlights];
    }
    
    // Scan index logic
    if (sameSearchRange && sameOptions)
    {
        // Same search pattern, go to next match
        if (samePattern)
            _scanIndex += _rangeOfFoundString.length;
        // Scan index out of range
        if (_scanIndex < range.location || _scanIndex >= (range.location + range.length))
            _scanIndex = range.location;
    }
    else
        _scanIndex = range.location;
    
    // Get match
    NSRange matchRange = [_regex rangeOfFirstMatchInString:self.text options:0 range:NSMakeRange(_scanIndex, range.location + range.length - _scanIndex)];
    
    // Match not found
    if (matchRange.location == NSNotFound)
    {
        _rangeOfFoundString = NSMakeRange(NSNotFound, 0);
        if (_scanIndex)
        {
            // Start from top
            _scanIndex = range.location;
            return [self scrollToMatch:pattern searchOptions:options range:range animated:animated atScrollPosition:scrollPosition];
        }
        _regex = nil;
        return NO;
    }
    
    // Match found, save state
    _rangeOfFoundString = matchRange;
    _scanIndex = matchRange.location;
    _shouldUpdateScanIndex = NO;
    
    // Add highlights
    if (highlightingSupported && _highlightSearchResults)
        [self highlightOccurrencesInMaskedVisibleRange];
    
    // Scroll
    [self scrollRangeToVisible:matchRange consideringInsets:YES animated:animated atScrollPosition:scrollPosition];
    
    return YES;
}

#pragma mark ---- String search ----

- (BOOL)scrollToString:(NSString *)stringToFind
{
    return [self scrollToString:stringToFind searchOptions:0 range:NSMakeRange(0, self.text.length) animated:YES atScrollPosition:ICTextViewScrollPositionNone];
}

- (BOOL)scrollToString:(NSString *)stringToFind searchOptions:(NSRegularExpressionOptions)options
{
    return [self scrollToString:stringToFind searchOptions:options range:NSMakeRange(0, self.text.length) animated:YES atScrollPosition:ICTextViewScrollPositionNone];
}

- (BOOL)scrollToString:(NSString *)stringToFind searchOptions:(NSRegularExpressionOptions)options range:(NSRange)range
{
    return [self scrollToString:stringToFind searchOptions:options range:range animated:YES atScrollPosition:ICTextViewScrollPositionNone];
}

- (BOOL)scrollToString:(NSString *)stringToFind searchOptions:(NSRegularExpressionOptions)options animated:(BOOL)animated atScrollPosition:(ICTextViewScrollPosition)scrollPosition
{
    return [self scrollToString:stringToFind searchOptions:options range:NSMakeRange(0, self.text.length) animated:animated atScrollPosition:scrollPosition];
}

- (BOOL)scrollToString:(NSString *)stringToFind searchOptions:(NSRegularExpressionOptions)options range:(NSRange)range animated:(BOOL)animated atScrollPosition:(ICTextViewScrollPosition)scrollPosition
{
    if (!stringToFind)
    {
        ICTextViewLog(@"Search string cannot be nil.");
        [self resetSearch];
        return NO;
    }
    
    // Escape metacharacters
    stringToFind = [NSRegularExpression escapedPatternForString:stringToFind];
    
    // Better automatic search on UITextField or UISearchBar text change
    if (_regex)
    {
        NSString *lcStringToFind = [stringToFind lowercaseString];
        NSString *lcFoundString = [_regex.pattern lowercaseString];
        if (!([lcStringToFind hasPrefix:lcFoundString] || [lcFoundString hasPrefix:lcStringToFind]))
            _scanIndex += _rangeOfFoundString.length;
    }
    
    // Perform search
    return [self scrollToMatch:stringToFind searchOptions:options range:range animated:animated atScrollPosition:scrollPosition];
}

#pragma mark -- Misc --

- (void)scrollRangeToVisible:(NSRange)range consideringInsets:(BOOL)considerInsets
{
    [self scrollRangeToVisible:range consideringInsets:considerInsets animated:YES atScrollPosition:ICTextViewScrollPositionNone];
}

- (void)scrollRangeToVisible:(NSRange)range consideringInsets:(BOOL)considerInsets animated:(BOOL)animated atScrollPosition:(ICTextViewScrollPosition)scrollPosition
{
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_5_0)
    {
        // considerInsets, animated and scrollPosition are ignored in iOS 4.x
        // as UITextView doesn't conform to the UITextInput protocol
        [self scrollRangeToVisible:range];
        return;
    }
    
    // Calculate rect for range
    UITextPosition *startPosition = [self positionFromPosition:self.beginningOfDocument offset:range.location];
    UITextPosition *endPosition = [self positionFromPosition:startPosition offset:range.length];
    UITextRange *textRange = [self textRangeFromPosition:startPosition toPosition:endPosition];
    CGRect rect = [self firstRectForRange:textRange];
    
    // Scroll to visible rect
    [self scrollRectToVisible:rect animated:animated consideringInsets:considerInsets atScrollPosition:scrollPosition];
}

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated consideringInsets:(BOOL)considerInsets
{
    [self scrollRectToVisible:rect animated:animated consideringInsets:considerInsets atScrollPosition:ICTextViewScrollPositionNone];
}

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated consideringInsets:(BOOL)considerInsets atScrollPosition:(ICTextViewScrollPosition)scrollPosition
{
    UIEdgeInsets contentInset = considerInsets ? self.contentInset : UIEdgeInsetsZero;
    CGRect visibleRect = [self visibleRectConsideringInsets:considerInsets];
    CGRect toleranceArea = visibleRect;
    CGFloat y = rect.origin.y - contentInset.top;
    
    switch (scrollPosition)
    {
        case ICTextViewScrollPositionTop:
            toleranceArea.size.height = rect.size.height * 1.5;
            break;
            
        case ICTextViewScrollPositionMiddle:
            toleranceArea.size.height = rect.size.height * 1.5;
            toleranceArea.origin.y += ((visibleRect.size.height - toleranceArea.size.height) * 0.5);
            y -= ((visibleRect.size.height - rect.size.height) * 0.5);
            break;
            
        case ICTextViewScrollPositionBottom:
            toleranceArea.size.height = rect.size.height * 1.5;
            toleranceArea.origin.y += (visibleRect.size.height - toleranceArea.size.height);
            y -= (visibleRect.size.height - rect.size.height);
            break;
            
        case ICTextViewScrollPositionNone:
        default:
            if (rect.origin.y >= visibleRect.origin.y)
                y -= (visibleRect.size.height - rect.size.height);
            break;
    }
    
    if (!CGRectContainsRect(toleranceArea, rect))
        [self scrollToY:y animated:animated consideringInsets:considerInsets];
}

- (NSRange)visibleRangeConsideringInsets:(BOOL)considerInsets
{
    return [self visibleRangeConsideringInsets:considerInsets startPosition:NULL endPosition:NULL];
}

- (NSRange)visibleRangeConsideringInsets:(BOOL)considerInsets startPosition:(UITextPosition *__autoreleasing *)startPosition endPosition:(UITextPosition *__autoreleasing *)endPosition
{
    CGRect visibleRect = [self visibleRectConsideringInsets:considerInsets];
    CGPoint startPoint = visibleRect.origin;
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(visibleRect), CGRectGetMaxY(visibleRect));
    
    UITextPosition *start = [self characterRangeAtPoint:startPoint].start;
    UITextPosition *end = [self characterRangeAtPoint:endPoint].end;
    
    if (startPosition)
        *startPosition = start;
    if (endPosition)
        *endPosition = end;
    
    return NSMakeRange([self offsetFromPosition:self.beginningOfDocument toPosition:start], [self offsetFromPosition:start toPosition:end]);
}

- (CGRect)visibleRectConsideringInsets:(BOOL)considerInsets
{
    CGRect bounds = self.bounds;
    if (considerInsets)
    {
        UIEdgeInsets contentInset = self.contentInset;
        bounds.origin.x += contentInset.left;
        bounds.origin.y += contentInset.top;
        bounds.size.width -= (contentInset.left + contentInset.right);
        bounds.size.height -= (contentInset.top + contentInset.bottom);
    }
    return bounds;
}

@end
