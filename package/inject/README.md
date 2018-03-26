# `package:inject`

[![Build Status](https://travis-ci.org/google/inject.dart.svg?branch=master)](https://travis-ci.org/google/inject.dart)

Compile-time dependency injection for Dart and Flutter, similar to [Dagger][].

[Dagger]: https://google.github.io/dagger/

**NOTE**: This is _not_ an official Google or Dart team project.

Example code TBD.

## Getting Started

TBD.

## FAQ

* [Why is the issue tracker disabled?](#why-is-the-issue-tracker-disabled)
* [What do you mean by compile-time?](#what-do-you-mean-by-compile-time)
* [Can I use this with Flutter](#can-i-use-this-with-flutter)
* [Can I use this with AngularDart?](#can-i-use-this-with-angulardart)
* [Can I use this with server-side Dart?](#can-i-use-this-with-server-side-dart)

### Why is the issue tracker disabled?

This library is currently offered _as-is_ (developer preview) as it is
open-sourced from an internal repository inside Google. As such we are not able
to act on bugs or feature requests at this time.

### What do you mean by compile-time?

All dependency injection is analyzed, configured, and generated at compile-time
as part of a build process, and does not rely on any runtime setup or
configuration (such as reflection with `dart:mirrors`). This provides the best
experience in terms of code-size and performance (it's nearly identical to hand
written code) and allows us to provide compile-time errors and warnings instead
of relying on runtime.

### Can I use this with Flutter?

_Yes_, `package:inject` is framework and platform agnostic, and works perfectly
well with Flutter or any other framework. We'll be releasing more
documentation and samples of using this package with `flutter` in the future.

### Can I use this with AngularDart?

While technically, _yes_ (`package:inject` is framework and platform agnostic),
the existing dependency injection framework in AngularDart is better suited for
the idioms of that framework. We welcome experimentation and new ideas, though!

### Can I use this with server-side Dart?

_Yes_, `package:inject` is framework and platform agnostic, and works perfectly
well with any server-side Dart framework. You may want to consult your specific
framework though - they might already have a preferred dependency injection
pattern.
