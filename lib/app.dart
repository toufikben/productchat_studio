import 'package:flutter/material.dart';
import 'core/theme.dart';
class ProductChatApp extends StatelessWidget { const ProductChatApp({super.key}); @override Widget build(BuildContext context) => MaterialApp(title: 'ProductChat Studio', debugShowCheckedModeBanner: false, theme: AppTheme.dark, home: const _Home()); }
class _Home extends StatelessWidget { const _Home(); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('ProductChat Studio')), body: const Center(child: Text('Upload a product image to begin Smart Analysis'))); }
