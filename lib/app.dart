import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme.dart';
class ProductChatApp extends StatelessWidget { const ProductChatApp({super.key}); @override Widget build(BuildContext context) => MaterialApp.router(title: 'ProductChat Studio', debugShowCheckedModeBanner: false, theme: AppTheme.dark, routerConfig: routerProvider); }
