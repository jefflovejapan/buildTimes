1. Generate a build times output file using the following command:

`xcodebuild -workspace <myworkspace> -scheme <myscheme> clean build OTHER_SWIFT_FLAGS=\"-Xfrontend -debug-time-function-bodies\" | grep \".[0-9]ms\" | grep -v \"^0.[0-9]ms\" | sort -nr > culprits.txt`

(This works in zsh, but might not in bash. If not, use the command shown [here](http://irace.me/swift-profiling))

2. Run Build Time Inspector and hit Cmd + O to open the culprits file.
3. Use Cmd + 1 and Cmd + 2 to switch between list and histogram view
4. Double-click on a table row or histogram bar to open the function in Xcode. Scroll to the first line of the highlighted section to find the associated function.
