library angular.app.static;

import 'package:di/static_injector.dart';
import 'package:di/di.dart' show TypeFactory, Injector;
import 'package:angular/bootstrap.dart';
import 'package:angular/core/module_internal.dart';
import 'package:angular/core/parser/parser.dart';
import 'package:angular/core/parser/dynamic_parser.dart';
import 'package:angular/core/registry_static.dart';
import 'package:angular/change_detection/change_detection.dart';
import 'package:angular/change_detection/dirty_checking_change_detector_static.dart';

class _StaticApplication extends Application {
  final Map<Type, TypeFactory> typeFactories;

  _StaticApplication(Map<Type, TypeFactory> this.typeFactories,
               Map<Type, Object> metadata,
               Map<String, FieldGetter> fieldGetters,
               Map<String, FieldSetter> fieldSetters,
               Map<String, Symbol> symbols) {
    ngModule
        ..value(MetadataExtractor, new StaticMetadataExtractor(metadata))
        ..value(FieldGetterFactory, new StaticFieldGetterFactory(fieldGetters))
        ..value(ClosureMap, new StaticClosureMap(fieldGetters, fieldSetters,
            symbols));
  }

  Injector createInjector() =>
      new StaticInjector(modules: modules, typeFactories: typeFactories);
}

class StaticClosureMap extends ClosureMap {
  final Map<String, Getter> getters;
  final Map<String, Setter> setters;
  final Map<String, Symbol> symbols;

  StaticClosureMap(this.getters, this.setters, this.symbols);

  Getter lookupGetter(String name) {
    Getter getter = getters[name];
    if (getter == null) throw "No getter for '$name'.";
    return getter;
  }

  Setter lookupSetter(String name) {
    Setter setter = setters[name];
    if (setter == null) throw "No setter for '$name'.";
    return setter;
  }

  MethodClosure lookupFunction(String name, CallArguments arguments) {
    var fn = lookupGetter(name);
    return (o, posArgs, namedArgs) {
      var sNamedArgs = {};
      namedArgs.forEach((name, value) => sNamedArgs[symbols[name]] = value);
      if (o is Map) {
        var fn = o[name];
        if (fn is Function) {
          return Function.apply(fn, posArgs, sNamedArgs);
        } else {
          throw "Property '$name' is not of type function.";
        }
      } else {
        return Function.apply(fn(o), posArgs, sNamedArgs);
      }
    };
  }
}

Application staticApplication(
    Map<Type, TypeFactory> typeFactories,
    Map<Type, Object> metadata,
    Map<String, FieldGetter> fieldGetters,
    Map<String, FieldSetter> fieldSetters,
    Map<String, Symbol> symbols) {
  return new _StaticApplication(typeFactories, metadata, fieldGetters, fieldSetters,
      symbols);
}