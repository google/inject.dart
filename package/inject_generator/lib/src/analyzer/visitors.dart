// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:inject_generator/src/analyzer/utils.dart';
import 'package:inject_generator/src/context.dart';
import 'package:inject_generator/src/source/symbol_path.dart';

/// Scans a resolved [LibraryElement] looking for metadata-annotated members.
///
/// Looks for:
/// - [visitInjectable]: Classes or constructors annotated with `@provide`.
/// - [visitInjector]: Classes annotated with `@injector`.
/// - [visitModule]: Classes annotated with `@module`.
abstract class InjectLibraryVisitor {
  /// Call to start visiting [library].
  void visitLibrary(LibraryElement library) {
    new _LibraryVisitor(this).visitLibraryElement(library);
  }

  /// Called when [clazz] is annotated with `@provide`.
  ///
  /// If [clazz] is annotated with `@singleton`, then [singleton] is true.
  void visitInjectable(ClassElement clazz, bool singleton);

  /// Called when [clazz] is annotated with `@injector`.
  ///
  /// [modules] is the list of types supplied as modules in the annotation.
  ///
  /// Example:
  ///
  ///     @Injector(const [FooModule, BarModule])
  ///     class Services {
  ///       ...
  ///     }
  ///
  /// In this example, [modules] will contain references to `FooModule` and
  /// `BarModule` types.
  void visitInjector(ClassElement clazz, List<SymbolPath> modules);

  /// Called when [clazz] is annotated with `@module`.
  void visitModule(ClassElement clazz);
}

class _LibraryVisitor extends RecursiveElementVisitor<Null> {
  final InjectLibraryVisitor _injectLibraryVisitor;

  _LibraryVisitor(this._injectLibraryVisitor);

  @override
  Null visitClassElement(ClassElement element) {
    var isInjectable = false;
    var isModule = false;
    var isInjector = false;

    int count = 0;
    if (isModuleClass(element)) {
      isModule = true;
      count++;
    }
    if (isInjectableClass(element)) {
      isInjectable = true;
      count++;
    }
    if (isInjectorClass(element)) {
      isInjector = true;
      count++;
    }

    if (count > 1) {
      var types = [
        isInjectable ? 'injectable' : null,
        isModule ? 'module' : null,
        isInjector ? 'injector' : null,
      ].where((t) => t != null);

      builderContext.log.severe(
        element,
        'A class may be an injectable, a module or an injector, '
            'but not more than one of these types. However class '
            '${element.name} was found to be ${types.join(' and ')}',
      );
      return null;
    }

    if (isModule) {
      _injectLibraryVisitor.visitModule(element);
    }
    if (isInjectable) {
      bool singleton = isSingletonClass(element);
      bool asynchronous = hasAsynchronousAnnotation(element) ||
          element.constructors.any(hasAsynchronousAnnotation);
      if (asynchronous) {
        builderContext.log.severe(
          element,
          'Classes and constructors cannot be annotated with @Asynchronous().',
        );
      }
      _injectLibraryVisitor.visitInjectable(
        element,
        singleton,
      );
    }
    if (isInjector) {
      _injectLibraryVisitor.visitInjector(
        element,
        _extractModules(element),
      );
    }
    return null;
  }
}

List<SymbolPath> _extractModules(ClassElement clazz) {
  ElementAnnotation annotation = getInjectorAnnotation(clazz);
  List<DartObject> modules =
      annotation.constantValue.getField('modules').toListValue();
  if (modules == null) {
    return const <SymbolPath>[];
  }
  return modules
      .map((DartObject obj) => getSymbolPath(obj.toTypeValue().element))
      .toList();
}

/// Scans a resolved [ClassElement] looking for metadata-annotated members.
abstract class InjectClassVisitor {
  final bool _isForInjector;

  /// Constructor.
  InjectClassVisitor(this._isForInjector);

  /// Whether we are collecting providers for an injector class.
  ///
  /// Unlike modules, the `@provide` annotation is optional in injectors.
  bool get isForInjector => _isForInjector;

  /// Call to start visiting [clazz].
  void visitClass(ClassElement clazz) {
    for (var supertype in clazz.allSupertypes.where((t) => !t.isObject)) {
      new _AnnotatedClassVisitor(this).visitClassElement(supertype.element);
    }
    new _AnnotatedClassVisitor(this).visitClassElement(clazz);
  }

  /// Called when a method is annotated with `@provide`.
  ///
  /// [singleton] is `true` when the method is also annotated with
  /// `@singleton`.
  ///
  /// [asynchronous] is `true` when the method is also annotated with
  /// `@asynchronous`.
  ///
  /// [qualifier] is non-null when the method is also annotated with
  /// an annotation created by `const Qualifier(...)`.
  void visitProvideMethod(
    MethodElement method,
    bool singleton,
    bool asynchronous, {
    SymbolPath qualifier,
  });

  /// Called when a getter is annotated with `@provide`.
  ///
  /// [singleton] is `true` when the getter is also annotated with
  /// `@singleton`.
  void visitProvideGetter(FieldElement method, bool singleton);
}

class _AnnotatedClassVisitor extends GeneralizingElementVisitor<Null> {
  final InjectClassVisitor _classVisitor;

  _AnnotatedClassVisitor(this._classVisitor);

  bool _isProvider(ExecutableElement element) =>
      hasProvideAnnotation(element) ||
      (_classVisitor._isForInjector && element.isAbstract);

  @override
  Null visitMethodElement(MethodElement method) {
    if (_isProvider(method)) {
      bool singleton = hasSingletonAnnotation(method);
      bool asynchronous = hasAsynchronousAnnotation(method);
      _classVisitor.visitProvideMethod(
        method,
        singleton,
        asynchronous,
        qualifier: hasQualifier(method) ? extractQualifier(method) : null,
      );
    }
    return null;
  }

  @override
  Null visitFieldElement(FieldElement field) {
    if (_isProvider(field.getter)) {
      bool singleton = hasSingletonAnnotation(field);
      bool asynchronous = hasAsynchronousAnnotation(field);
      if (asynchronous) {
        builderContext.log.severe(
          field,
          'Getters cannot be annotated with @Asynchronous().',
        );
      }
      _classVisitor.visitProvideGetter(field, singleton);
    }
    return null;
  }
}
