Purpose
--------------

The iConsole is a simple, pluggable class to enable more useful in-app logging
for your iPhone apps. It enables you to check error and crash logs within a
built application without needing to connect to the Xcode debugger. It also
allows non-technical beta testers of your applications to submit log information 
to you easily.

The iConsole also serves another purpose: Using the command interface it
provides an easy way to add debugging commands and let you toggle application
features on and off at runtime in a way that can be easily disabled in the
final release of your app, and doesn't require you to build additional throwaway
user interface components.


Installation
--------------

To install iConsole into your app, drag the iConsole and (optionally) GTM folder
into your project. iConsole has no other dependencies.

To enable iConsole in your application, replace your main window with an
instance of the iConsoleWindow. If you are using a standard project template,
the easiest way to do this is to change the class of your window in the
MainWindow.xib file. If you are already using a custom window subclass, change
the base class to iConsoleWindow.


Logging
--------------

To log to the console from within your app, include the iConsole.h header in
your class, and then add logging code of the form:

[iConsole log:@"some message"];

The message can have format parameters, and follows the same syntax as the
NSLog() command, and will log to both the in app and Xcode console. The
iConsole logging commands are also thread safe and so can be used anywhere in
place of NSLog().

In addition to the log: method, there are also the following additional log
functions that can be use in conjunction with the LOG_LEVEL constant to easily
control the amount of logging in a given app build:

[iConsole info:...]; // use for informational logs (e.g. object count)
[iConsole warn:...]; // use for warnings (e.g. low memory)
[iConsole error:...]; // use for errors (e.g. unexpected value)
[iConsole crash:...]; // use for logging conditions that lead to a crash

The console is shown/hidden using a screen swipe by default, but if that is not
appropriate for your app, you can show and hide it programmatically using:

[iConsole show];
[iConsole hide];

The console has a button for clearing the log, but if you ever need to clear it
programmatically then you can do so using the clear command:

[iConsole clear];


Command Interface
------------------

As well as displaying logs, the console can also allow user command input. This
is disabled by default. To enable it, you need to create a command delegate,
which you do as follows:

1) Implement the iConsoleDelegate protocol on one of your classes. It doesn't
matter which one, but it should be a persistent class that will exist for the
duration of the app's lifetime, e.g. your app delegate or main view controller.

2) Add the handleConsoleCommand: method to your delegate class. This receives
a single string representing the command that the user has typed. iConsole does
not place any restriction on the command syntax, or provide any helper methods
for processing commands at this time.

3) Use the following code to set your class as the delegate for the iConsole.
Note that this code must be called BEFORE the console is first shown, or the
input field will not appear:

[iConsole sharedConsole].delegate = myDelegate;

For an example of how to implement this, look at the HelloWorld app.


Configuration
--------------

To configure iConsole, there are a number of constants in the iConsole.h file
that can alter its behaviour and appearance. These should be mostly self-
explanatory, but key ones are documented below:

CONSOLE_ENABLED - set this to 0 to disable the console. It is a good idea to
set this using a compiler macro in your project target settings so it can be
switched off in your release build.

LOG_LEVEL - depending on your use of logging in the project, the log may fill
up quickly. Use the log level to selectively disable logs based on severity.
You can use the LOG_LEVEL_XXX constants for this. LOG_LEVEL_NONE will disable
all logging. LOG_LEVEL_INFO will enable all logging levels.

ADD_CRASH_HANDLER - if enabled this will automatically log a stack trace to the
console in event of a fatal exception.

USE_GOOGLE_STACK_TRACE - the GTM trace function provides a much more useful stack
trace than the default iPhone SDK provides. It is recommended to enable this if
you are using the ADD_CRASH_HANDLER feature. If this option is disabled however,
you can safely remove the GTM source files from the project.

SAVE_LOG_TO_DISK - if this option is disabled, logs will not be saved between
sessions. Note that the ADD_CRASH_HANDLER feature is useless if this is not set.

DEVICE/SIMULATOR_CONSOLE_TOUCHES - the number of fingers needed for the console
activation swipe. More than three is difficult to pull off on an iPhone unless
you have very small fingers. More than two is impossible to execute in the
simulator. If your app makes use of two or three fingered swipes for other
interactions you may wish to increase this however. If you do not wish to allow
swipe activation of the console, set the touches count to 0 or some in-feasibly
large number.

DEVICE/SIMULATOR_SHAKE_TO_SHOW_CONSOLE - if swiping is not an appropriate
activation method in your app, you can optionally enable shake-to-show instead.
This is certainly a less fiddly option in the simulator.

CONSOLE_BRANDING - the text that appears at the top of the console. This
contains the Charcoal Design copyright by default, but you are permitted to
remove the iConsole name and change this to reflect your own company branding,
as long as you do not add your own copyright, or otherwise imply that the
iConsole is your own work.

CONSOLE_INPUT_PLACEHOLDER - helper text that appears in the console input field.

LOG_SUBMIT_EMAIL - the default "to" address when sending console logs via email
from within the app.