
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:flutter/services.dart';


const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  int _precision = 2;
String _currency = '\$';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = (prefs.getBool('darkMode') ?? false) ? ThemeMode.dark : ThemeMode.light;
      _precision = prefs.getInt('precision') ?? 2;
     _currency = prefs.getString('currency') ?? '\$';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compounding Calculator',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: HomePage(
        onSettingsChanged: _loadSettings,
        precision: _precision,
        currency: _currency,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onSettingsChanged;
  final int precision;
  final String currency;

  const HomePage({super.key, required this.onSettingsChanged, required this.precision, required this.currency});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _timeUnit = 'Years';
  String _frequency = 'Annual';
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: \$error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _timeController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final double P = double.parse(_principalController.text);
    final double r = double.parse(_rateController.text) / 100;
    final double tInput = double.parse(_timeController.text);
    double t;
    switch (_timeUnit) {
      case 'Years':
        t = tInput;
        break;
      case 'Months':
        t = tInput / 12;
        break;
      case 'Weeks':
        t = tInput / 52;
        break;
      case 'Days':
        t = tInput / 365;
        break;
      default:
        t = tInput;
    }
    final freqMap = {'Daily': 365, 'Weekly': 52, 'Monthly': 12, 'Semi-Annual': 2, 'Annual': 1};
    final n = freqMap[_frequency]!;
    final amount = P * pow((1 + r / n), n * t);
    final result = amount.toStringAsFixed(widget.precision);

  showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.4,  // Slightly smaller initial size
    minChildSize: 0.4,
    maxChildSize: 0.9,
    expand: false,
    builder: (context, scrollController) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Improved drag handle with better visibility
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Header with title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calculated Result',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          // Main content area with proper spacing
          Expanded(
            child: ListView(
              controller: scrollController,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                const SizedBox(height: 16),
                // Result display with improved styling
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.currency}$result',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
               
                // const SizedBox(height: 8),
                // Add more content here as needed
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compounding Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(onChange: widget.onSettingsChanged),
                ),
              );
            },
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _principalController,
                decoration: const InputDecoration(labelText: 'Principal Amount'),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,10}'))],
                keyboardType: TextInputType.number,
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val < 0) return 'Enter non-negative amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(labelText: 'Annual Interest (%)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val < 0) return 'Enter non-negative rate';
                  if (val > 100) return 'Rate ≤ 100%';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(labelText: 'Time'),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,10}'))],
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 0) return 'Enter non-negative time';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _timeUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const ['Years', 'Months', 'Weeks', 'Days']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _timeUnit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(labelText: 'Compounding Frequency'),
                items: const ['Daily', 'Weekly', 'Monthly', 'Semi-Annual', 'Annual']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Calculate'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isAdLoaded && _bannerAd != null
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }
}

class SettingsPage extends StatefulWidget {
  final VoidCallback onChange;
  const SettingsPage({super.key, required this.onChange});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  int _precision = 2;
  String _currency = '\$';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = p.getBool('darkMode') ?? false;
      _precision = p.getInt('precision') ?? 2;
      _currency = p.getString('currency') ?? '\$';
    });
  }

  Future<void> _saveBool(String key, bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, val);
    widget.onChange();
  }

  Future<void> _saveInt(String key, int val) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(key, val);
    widget.onChange();
  }

  Future<void> _saveString(String key, String val) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, val);
    widget.onChange();
  }

  void _launchPrivacy() async {
    const url = 'https://your-privacy-policy-url.com';
    if (await canLaunch(url)) await launch(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (v) => setState(() {
                _darkMode = v;
                _saveBool('darkMode', v);
              }),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Result Precision'),
              trailing: DropdownButton<int>(
                value: _precision,
                items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text('$i'))).toList(),
                onChanged: (v) {
                  setState(() { _precision = v!; });
                  _saveInt('precision', v!);
                },
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Currency Symbol'),
              trailing: DropdownButton<String>(
                value: _currency,
                items: const ['\$', '€', '₹', '£'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  setState(() { _currency = v!; });
                  _saveString('currency', v!);
                },
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Privacy Policy'),
              onTap: _launchPrivacy,
            ),
          ],
        ),
      ),
    );
  }
}