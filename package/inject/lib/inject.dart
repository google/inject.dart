// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A DI framework for Dart
library inject;

export 'src/api/annotations.dart'
    show
        asynchronous,
        injector,
        module,
        provide,
        singleton,
        Injector,
        Qualifier;
