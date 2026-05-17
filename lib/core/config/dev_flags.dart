import 'package:flutter/foundation.dart';

const bool _bypassLoginForDevelopment = true;

bool get devBypassLogin => kDebugMode && _bypassLoginForDevelopment;
