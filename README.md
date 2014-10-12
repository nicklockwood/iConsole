Purpose
--------------

iConsole is a simple, pluggable class to enable more useful in-app logging for your iPhone apps. It enables you to check error and crash logs within a built application without needing to connect to the Xcode debugger. It also allows non-technical beta testers of your applications to submit log information to you easily.

iConsole also serves another purpose: Using the command interface it provides an easy way to add debugging commands and let you toggle application features on and off at runtime in a way that can be easily disabled in the final release of your app, and doesn't require you to build additional throwaway user interface components.


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 8.0 (Xcode 6.0, Apple LLVM compiler 6.0)
* Earliest supported deployment target - iOS 5.0
* Earliest compatible deployment target - iOS 4.3

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

As of version 1.5, iConsole requires ARC. If you wish to use iConsole in a non-ARC project, just add the -fobjc-arc compiler flag to the iConsole.m class file. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click iConsole.m in the list and type -fobjc-arc into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in iConsole.m, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including iConsole.m) are checked.


Installation
--------------

To install iConsole into your app, drag the iConsole and (optionally) GTM folder into your project. iConsole has no other dependencies. If you need to update the GTM classes, you can check out the latest version using:

    svn checkout http://google-toolbox-for-mac.googlecode.com/svn/trunk/ google-toolbox-for-mac-read-only

To enable iConsole in your application, replace your main window with an instance of the iConsoleWindow. If you are using a standard project template, the easiest way to do this is to change the class of your window in the MainWindow.xib file, or the AppDelegate.m if your window is created programmatically. If you are already using a custom window subclass, change the base class to iConsoleWindow.


Logging
--------------

To log to the console from within your app, include the iConsole.h header in your class (or in your .pch file to make it available throughout your project), and then add logging code of the form:

    [iConsole log:@"some message"];

The message can have format parameters, and follows the same syntax as the NSLog() command, and will log to both the in app and Xcode console. The iConsole logging commands are also thread safe and so can be used anywhere in place of NSLog().

In addition to the log: method, there are also the following additional log functions that can be use in conjunction with the LOG_LEVEL constant to easily control the amount of logging in a given app build:

    [iConsole info:...]; // use for informational logs (e.g. object count)
    [iConsole warn:...]; // use for warnings (e.g. low memory)
    [iConsole error:...]; // use for errors (e.g. unexpected value)
    [iConsole crash:...]; // use for logging conditions that lead to a crash

The console is shown/hidden using a screen swipe by default, but if that is not appropriate for your app, you can show and hide it programmatically using:

    [iConsole show];
    [iConsole hide];

The console has a button for clearing the log, but if you ever need to clear it programmatically then you can do so using the clear command:

    [iConsole clear];


Command Interface
------------------

As well as displaying logs, the console can also allow user command input. This is disabled by default. To enable it, you need to create a command delegate, which you do as follows:

1) Implement the iConsoleDelegate protocol on one of your classes. It doesn't matter which one, but it should be a persistent class that will exist for the duration of the app's lifetime, e.g. your app delegate or main view controller.
    
2) Add the handleConsoleCommand: method to your delegate class. This receives a single string representing the command that the user has typed. iConsole does not place any restriction on the command syntax, or provide any helper methods for processing commands at this time.
    
3) Use the following code to set your class as the delegate for the iConsole. Note that this code must be called BEFORE the console is first shown, or the input field will not appear:

    [iConsole sharedConsole].delegate = myDelegate;

For an example of how to implement this, look at the HelloWorld app.


Exception Handling
------------------

By default, iConsole intercepts unhandled exceptions (crashes) and deciphers the stack trace using the GTM library. You may wish to disable this feature if your app already implements a crash handler, or if you do not want to include GTM as a dependency. To do that, set one or both of these macros to 0:

    ICONSOLE_ADD_EXCEPTION_HANDLER
    ICONSOLE_USE_GOOGLE_STACK_TRACE
    
The GTM trace function provides a much more useful stack trace than the default iPhone SDK provides. It is recommended to enable this if you are using the `ICONSOLE_ADD_EXCEPTION_HANDLER` option. If the `ICONSOLE_USE_GOOGLE_STACK_TRACE` option is disabled, you can safely remove the GTM source files from the project.

**Note:** if the `ICONSOLE_ADD_EXCEPTION_HANDLER` option is disabled, you should call `[[NSUserDefaults standardDefaults] synchronize]` in your own crash handler to ensure that logs are preserved in the event of a crash.
    

Configuration
--------------

To configure iConsole, there are a number of properties of the iConsole class that can alter the behaviour and appearance of iConsole. These should be mostly self-explanatory, but they are documented below:

    @property (nonatomic, assign) BOOL enabled;
    
Set this to 0 to disable the console. It is a good idea to set this using a compiler macro in your project target settings so it can be switched off in your release build.

    @property (nonatomic, assign) iConsoleLogLevel logLevel;
    
Depending on your use of logging in the project, the log may fill up quickly. Use the log level to selectively disable logs based on severity. You can use the `iConsoleLogLevel` constants for this. `iConsoleLogLevelNone` will disable all logging. `iConsoleLogLevelInfo` will enable all logging levels.

    @property (nonatomic, assign) BOOL saveLogToDisk;
    
If this option is disabled, logs will not be saved between sessions. Note that the `ICONSOLE_ADD_EXCEPTION_HANDLER` feature is useless if this option is not enabled.

    @property (nonatomic, assign) NSUInteger maxLogItems;
    
Appending additional lines to the log has a small performance cost. The larger the log gets, the greater this performance impact. For this reason, the maximum size of the log is limited to 1000 lines. You can increase or decrease this limit by settings this property.

    @property (nonatomic, weak) id<iConsoleDelegate> delegate;
    
This property is used to set the delegate for implementing the console command interface.

    @property (nonatomic, assign) NSUInteger simulatorTouchesToShow;
    @property (nonatomic, assign) NSUInteger deviceTouchesToShow;
    
The number of fingers needed for the consoleactivation swipe. More than three is difficult to pull off on an iPhone unless you have very small fingers. More than two is impossible to execute in the simulator. If your app makes use of two or three fingered swipes for other interactions you may wish to increase this however. If you do not wish to allow swipe activation of the console, set the touches count to 0 or some infeasibly large number. The default is 2 fingers on the simulator and 3 on the device.

    @property (nonatomic, assign) BOOL simulatorShakeToShow;
    @property (nonatomic, assign) BOOL deviceShakeToShow;
    
If swiping is not an appropriate activation method in your app, you can optionally enable shake-to-show instead. This is certainly a less fiddly option in the simulator, but may already be used for another purpose in your app. By default, this feature is enabled on the simulator and disabled on the device.

    @property (nonatomic, copy) NSString *infoString;
    
The text that appears at the top of the console. This contains the Charcoal Design copyright by default, but you are permitted to
remove the iConsole name and change this to reflect your own company branding, as long as you do not add your own copyright, or otherwise imply that iConsole is your own work.

    @property (nonatomic, copy) NSString *inputPlaceholderString;
    
Helper text that appears in the console input field.

    @property (nonatomic, copy) NSString *logSubmissionEmail;
    
The default "to" address when sending console logs via email from within the app (blank by default).

    @property (nonatomic, strong) UIColor *backgroundColor;
    
The background color for the console (black by default).
    
    @property (nonatomic, strong) UIColor *textColor;
    
The color of the console text and action button icon (white by default).


Release notes
---------------

Version 1.5.3

- Quick fixes for iOS 8
- Added va_list method version for Swift compatibility
- Added Swift example project
- Known issue: only supports portrait mode on iOS 8

Version 1.5.2

- Fixed problem with swipe gestures after displaying console
- Added ability to specify scrollbar color

Version 1.5.1

- Fixed problem when emailing log if app name contains a space

Version 1.5

- Now requires ARC (see README for details)
- Now correctly URL-encodes log when sending via email
- Fixed rotation issue
- Added podspec file

Version 1.4.1

- Fixed crash when inserting first log

Version 1.4

- iConsole now uses properties for configuration instead of macros
- Updated GTMlibrary to latest version, which fixes analyzer warnings
- Console action button now uses more intuitive icon

Version 1.3

- Updated project structure
- Added ARC support

Version 1.2

- Fixed swipe direction when device is rotated
- Added instruction text to HelloWorld screen

Version 1.1

- Added shake-to-show option
- Fully tested on iPad
- Logging is now thread safe
- Fixed issue with pressing info button when keyboard is open
- Correctly handles interface rotation
- Correctly handles in-call status bar
- Fixed bug when console exceeds max rows

Version 1.0

- Initial release.

