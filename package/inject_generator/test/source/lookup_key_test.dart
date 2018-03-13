import 'dart:convert';

import 'package:inject_generator/src/source/lookup_key.dart';
import 'package:inject_generator/src/source/symbol_path.dart';
import 'package:quiver/testing/equality.dart';
import 'package:test/test.dart';

final typeName1 = 'TypeName1';
final typeSymbolPath1 = new SymbolPath.global(typeName1);

final typeName2 = 'TypeName2';
final typeSymbolPath2 = new SymbolPath.global(typeName2);

final qualifierName = 'fakeQualifier';
final qualifier = new SymbolPath.global(qualifierName);

void main() {
  group(LookupKey, () {
    group('toPrettyString', () {
      test('only root', () {
        final type = new LookupKey(typeSymbolPath1);

        final prettyString = type.toPrettyString();

        expect(prettyString, typeName1);
      });

      test('qualified type', () {
        final type = new LookupKey(typeSymbolPath1, qualifier: qualifier);

        final prettyString = type.toPrettyString();

        expect(prettyString, '@$qualifierName $typeName1');
      });
    });

    group('serialization', () {
      test('with all fields', () {
        final type = new LookupKey(typeSymbolPath1, qualifier: qualifier);

        final deserialized = deserialize(type);

        expect(deserialized, type);
      });

      test('without qualifier', () {
        final type = new LookupKey(typeSymbolPath1);

        final deserialized = deserialize(type);

        expect(deserialized, type);
      });
    });

    test('equality', () {
      expect({
        'only root': [
          new LookupKey(typeSymbolPath1),
          new LookupKey(typeSymbolPath1)
        ],
        'with qualifier': [
          new LookupKey(typeSymbolPath1, qualifier: qualifier),
          new LookupKey(typeSymbolPath1, qualifier: qualifier)
        ],
      }, areEqualityGroups);
    });
  });
}

LookupKey deserialize(LookupKey type) {
  final json = const JsonEncoder().convert(type);
  return new LookupKey.fromJson(const JsonDecoder().convert(json));
}
