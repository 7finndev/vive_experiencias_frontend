import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Servicio centralizado para gestionar logs y errores.
class Logger {
  
  // 1. INFO: Para cosas normales 
  static void info(String message, [String name = 'APP']) {
    if (kDebugMode) {
      // Usamos developer.log para que no se corte si el texto es largo
      developer.log('ℹ️ $message', name: name);
      debugPrint('ℹ️ [$name] $message');
    }
  }

  // 1.1 INFO: Para mostrar información pero por pantalla o terminal
  static void infoPrint(String message, [String name = 'APP']) {
    if (kDebugMode) {
      debugPrint('ℹ️ [$name] $message');
    }
  }
  // 2. WARNING: 
  static void warning(String message, [String name = 'APP']) {
    if (kDebugMode) {
      developer.log('⚠️ $message', name: name);
      debugPrint('⚠️ [$name] $message');
    }
  }

  // 3. ERROR: 
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // A. Mostrar en consola 
    if (kDebugMode) {
      developer.log(
        '🛑 $message', 
        name: 'ERROR', 
        error: error, 
        stackTrace: stackTrace
      );
      debugPrint('🛑 [ERROR] $message');
    }
  
    // B. (FUTURO) Aquí conectaríamos con Firebase Crashlytics
    // if (!kDebugMode) {
    //    FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
    // }
  }
}