# Unreleased
Change | Issue | Impact
:--- | :---: | :---:

# 3.3.1
Change | Issue | Impact
:--- | :---: | :---:
ChatBroadcastListener improvements. | PRIMEIOS-996 | PATCH

# 3.3.0
Change | Issue | Impact
:--- | :---: | :---:
Improved handling of network errors. | PRIMEIOS-959 | MAJOR

# 3.2.3
Change | Issue | Impact
:--- | :---: | :---:
Reduced messages list redraw count. | PRIMEIOS-962 | MINOR
Disabled termination when messages list datasource is inconsistent. | PRIMEIOS-962 | MINOR

# 3.2.2
Change | Issue | Impact
:--- | :---: | :---:
'preinstalledText' variable cleared after being set | NO | MINOR

# 3.2.1
Change | Issue | Impact
:--- | :---: | :---:
'skip' method calls changed to 'filter' | NO | PATCH

# 3.2.0
Change | Issue | Impact
:--- | :---: | :---:
Messages downloading process refactored | PRIMEIOS-877 | MAJOR
Some layers of abstraction in ChatSDK removed as redundant | PRIMEIOS-877 | MAJOR
Reload of messages UICollectionView fixed | PRIMEIOS-877 | MINOR
Added unit tests | PRIMEIOS-916 | PATCH
Refactored internally-used symbols | PRIMEIOS-916 | PATCH

# 3.1.0
Change | Issue | Impact
:--- | :---: | :---:
Added tests-target specification to `ChatSDK.podspec` | PRIMEIOS-897 | MINOR
Created `ChatSDKTests` (to be removed later) | PRIMEIOS-897 | PATCH

# 3.0.0
Change | Issue | Impact
:--- | :---: | :---:
Added `ChatSDK.podspec` for distributing the framework via CocoaPods | PRIMEIOS-884 | MINOR
Removed `Podfile` and `Podfile.lock` | PRIMEIOS-884 | MAJOR
Removed the Xcode project | PRIMEIOS-884 | MAJOR
Removed the unused sample files | PRIMEIOS-884 | MAJOR
Removed the unused config files (e.g. Fastlane config, GitHub Actions workflows, etc.) | PRIMEIOS-884 | MAJOR
