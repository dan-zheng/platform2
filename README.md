# Hello

A minimal reproducer for https://bugs.swift.org/browse/TF-1252.

```console
$ swift test
[6/6] Linking HelloPackageTests
2020-04-18 11:55:28.795 xctest[47161:4300039] The bundle “HelloPackageTests.xctest” couldn’t be loaded. Try reinstalling the bundle.
2020-04-18 11:55:28.795 xctest[47161:4300039] (dlopen(/tmp/Hello/.build/x86_64-apple-macosx/debug/HelloPackageTests.xctest/Contents/MacOS/HelloPackageTests, 265): Symbol not found: _$s13TangentVectors14DifferentiablePTl
  Referenced from: /tmp/Hello/.build/x86_64-apple-macosx/debug/HelloPackageTests.xctest/Contents/MacOS/HelloPackageTests
  Expected in: /usr/lib/swift/libswiftCore.dylib
 in /tmp/Hello/.build/x86_64-apple-macosx/debug/HelloPackageTests.xctest/Contents/MacOS/HelloPackageTests)
```

Reproducible via both Swift for TensorFlow and http://swift.org/download toolchains:

* https://storage.googleapis.com/swift-tensorflow/mac/swift-tensorflow-DEVELOPMENT-2020-04-17-a-osx.pkg
* https://swift.org/builds/development/xcode/swift-DEVELOPMENT-SNAPSHOT-2020-04-17-a/swift-DEVELOPMENT-SNAPSHOT-2020-04-17-a-osx.pkg
