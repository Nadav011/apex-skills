/// Flutter RTL-First Application Template
///
/// This template provides the correct RTL setup for Hebrew/Arabic applications.
/// Copy this to your lib/main.dart file.
///
/// Key RTL requirements:
/// - Locale set to Hebrew (he_IL) or Arabic (ar_SA)
/// - Directionality widget with TextDirection.rtl
/// - Proper MaterialApp localization configuration
///
/// @version 1.0.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// =============================================================================
// Main Entry Point
// =============================================================================

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (optional)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for RTL
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

// =============================================================================
// Root Application Widget
// =============================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // =======================================================================
      // Localization Configuration (CRITICAL for RTL)
      // =======================================================================

      // Primary locale - Hebrew (Israel)
      // Change to Locale('ar', 'SA') for Arabic
      locale: const Locale('he', 'IL'),

      // Supported locales
      supportedLocales: const [
        Locale('he', 'IL'), // Hebrew - Israel
        Locale('ar', 'SA'), // Arabic - Saudi Arabia (if needed)
        Locale('en', 'US'), // English - fallback
      ],

      // Localization delegates
      localizationsDelegates: const [
        // Flutter built-in localizations
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Add your app-specific localizations here:
        // AppLocalizations.delegate,
      ],

      // =======================================================================
      // App Configuration
      // =======================================================================
      title: 'שם האפליקציה', // Hebrew app name
      debugShowCheckedModeBanner: false,

      // =======================================================================
      // Theme Configuration
      // =======================================================================
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),

        // Hebrew-optimized font family
        fontFamily: 'Heebo',

        // AppBar theme
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),

        // Card theme with RTL-friendly border radius
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          // Note: Use textDirection in TextField for LTR inputs (email, URL)
        ),

        // Button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Dark theme (optional)
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Heebo',
      ),

      // Theme mode
      themeMode: ThemeMode.system,

      // =======================================================================
      // Home Screen
      // =======================================================================
      home: const HomeScreen(),
    );
  }
}

// =============================================================================
// Home Screen Example
// =============================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('דף הבית'), // Hebrew: "Home Page"
        // RTL-aware leading/trailing icons
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
          tooltip: 'תפריט', // Hebrew: "Menu"
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
            tooltip: 'הגדרות', // Hebrew: "Settings"
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Use EdgeInsetsDirectional for RTL-aware padding
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Example: RTL-aware card with border
              _buildExampleCard(context),

              const SizedBox(height: 16),

              // Example: RTL-aware list item
              _buildExampleListItem(context),

              const SizedBox(height: 16),

              // Example: LTR content in RTL context (numbers, code)
              _buildLtrContentExample(context),

              const SizedBox(height: 16),

              // Example: RTL-aware form
              _buildFormExample(context),
            ],
          ),
        ),
      ),

      // RTL-aware FAB position (automatically handled by Flutter)
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'הוסף', // Hebrew: "Add"
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Example: RTL-aware card with directional border
  Widget _buildExampleCard(BuildContext context) {
    return Card(
      child: Container(
        // Use BorderDirectional for RTL-aware borders
        decoration: const BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: Colors.blue, width: 4),
          ),
        ),
        // Use EdgeInsetsDirectional for RTL-aware padding
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'כותרת הכרטיס', // Hebrew: "Card Title"
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'תוכן הכרטיס בעברית. טקסט זה מיושר אוטומטית לימין בזכות הגדרת RTL.',
              // Hebrew: "Card content in Hebrew. This text is automatically
              // aligned to the right thanks to RTL settings."
            ),
          ],
        ),
      ),
    );
  }

  /// Example: RTL-aware list item with icon
  Widget _buildExampleListItem(BuildContext context) {
    return Card(
      child: ListTile(
        // Leading icon (appears on the right in RTL)
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.info_outline, color: Colors.blue),
        ),
        title: const Text('פריט ברשימה'), // Hebrew: "List Item"
        subtitle: const Text('תיאור הפריט'), // Hebrew: "Item description"
        // Trailing icon - use directional icons with mirroring
        trailing: const Icon(Icons.chevron_left), // Chevron points left in RTL
        onTap: () {},
      ),
    );
  }

  /// Example: LTR content within RTL context
  Widget _buildLtrContentExample(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'תוכן LTR בתוך RTL', // Hebrew: "LTR content within RTL"
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Phone number (LTR)
            Row(
              children: [
                const Text('טלפון: '), // Hebrew: "Phone:"
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '+972-50-123-4567',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price (LTR numbers with Hebrew currency)
            Row(
              children: [
                const Text('מחיר: '), // Hebrew: "Price:"
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '₪1,234.56',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Code snippet (LTR)
            const Text('קוד: '), // Hebrew: "Code:"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  'pnpm add @package/name',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Example: RTL-aware form with LTR email input
  Widget _buildFormExample(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'טופס דוגמה', // Hebrew: "Example Form"
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Hebrew text input (RTL)
            const TextField(
              decoration: InputDecoration(
                labelText: 'שם מלא', // Hebrew: "Full Name"
                hintText: 'הזן את שמך המלא', // Hebrew: "Enter your full name"
                prefixIcon: Icon(Icons.person_outline),
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),

            // Email input (LTR)
            const TextField(
              decoration: InputDecoration(
                labelText: 'אימייל', // Hebrew: "Email"
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            // Phone input (LTR numbers)
            const TextField(
              decoration: InputDecoration(
                labelText: 'טלפון', // Hebrew: "Phone"
                hintText: '050-123-4567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('שלח'), // Hebrew: "Submit"
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Helper Widgets for RTL
// =============================================================================

/// A widget that flips its child horizontally in RTL mode.
/// Use for directional icons like arrows, chevrons, etc.
class DirectionalIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final bool flip;

  const DirectionalIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.flip = true,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (flip && isRtl) {
      return Transform.flip(
        flipX: true,
        child: Icon(icon, size: size, color: color),
      );
    }

    return Icon(icon, size: size, color: color);
  }
}

/// Example usage:
/// DirectionalIcon(Icons.arrow_forward) // Flips in RTL
/// DirectionalIcon(Icons.check, flip: false) // Never flips

// =============================================================================
// Usage Notes
// =============================================================================

/// RTL-First Checklist for Flutter:
///
/// 1. App Configuration:
///    ✅ locale: Locale('he', 'IL')
///    ✅ supportedLocales includes Hebrew
///    ✅ GlobalMaterialLocalizations.delegate
///    ✅ GlobalWidgetsLocalizations.delegate
///    ✅ GlobalCupertinoLocalizations.delegate
///
/// 2. Layout:
///    ✅ Use EdgeInsetsDirectional instead of EdgeInsets
///    ✅ Use BorderDirectional instead of Border
///    ✅ Use AlignmentDirectional instead of Alignment
///    ✅ Use TextDirection.ltr for LTR content (numbers, code, email)
///
/// 3. Icons:
///    ✅ Directional icons should flip (arrows, chevrons)
///    ✅ Non-directional icons should NOT flip (check, close, menu)
///
/// 4. Text:
///    ✅ Hebrew text is automatically RTL
///    ✅ Wrap numbers/code in Directionality(textDirection: TextDirection.ltr)
///    ✅ Set textDirection: TextDirection.ltr on email/URL TextFields
///
/// 5. Dependency:
///    Add to pubspec.yaml:
///    dependencies:
///      flutter_localizations:
///        sdk: flutter
