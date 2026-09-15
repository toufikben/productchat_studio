import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/voice_service.dart';
import '../features/chat/chat_studio_screen.dart';
import '../features/home/home_screen.dart';
import '../widgets/floating_nav_bar.dart';

export '../core/theme.dart' show AppColors, AppTheme;
export '../services/voice_service.dart'
    show VoiceService, VoiceState, voiceProvider;
export '../features/chat/chat_studio_screen.dart' show ChatStudioScreen;
export '../features/home/home_screen.dart' show HomeScreen;
export '../widgets/floating_nav_bar.dart' show FloatingNavBar, NavItem;

/// Feature gates for the ProductChat Studio 2.0 interface.
class FeatureFlags {
  static const backgroundRemoval = true;
  static const shadowPresets = true;
  static const basicEnhance = true;
  static const textEditor = true;
  static const layerEditor = true;
  static const export = true;
  static const history = true;
  static const billing = true;
  static const modelCenter = true;
  static const voiceCommands = true;
  static const miGan = false;
  static const realEsrgan = false;
  static const relight = false;
  static const conversationalEdit = false;
  static const recipesAutomation = false;
  static const compliance = false;
  static const batchProcessing = false;
  static const brandIdentity = false;
  static const referral = false;
}

/// Shared entry points for the redesigned UI.
class ProductChatUiOverhaul {
  const ProductChatUiOverhaul._();
  static ThemeData get darkTheme => AppTheme.dark;
  static ThemeData get lightTheme => AppTheme.light;
}
