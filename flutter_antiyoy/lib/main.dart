import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'ui/home_page.dart';

void main() {
  runApp(const AntiyoyApp());
}

class AntiyoyApp extends StatelessWidget {
  const AntiyoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antiyoy',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          background: AppColors.background,
          primary: AppColors.highlight,
          secondary: AppColors.highlight,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
