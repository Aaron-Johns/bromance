import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:math';
import 'dart:ui'; // Import for ImageFilter

// --- API Configuration ---
const String baseUrl = 'http://127.0.0.1:5000'; // Replace with your Flask server address

void main() {
  runApp(const NotebookApp());
}

// --- BIONIC READING WIDGET ---
// A custom widget to display text with the Bionic Reading effect.
class BionicText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool enabled;
  final TextAlign textAlign;

  const BionicText(
    this.text, {
    super.key,
    this.style,
    this.enabled = true,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    // If bionic reading is disabled, return a normal Text widget.
    if (!enabled) {
      return Text(text, style: style, textAlign: textAlign);
    }

    // Process the text to create a list of TextSpans for bionic reading.
    final spans = _generateBionicSpans(context);

    return RichText(
      text: TextSpan(children: spans, style: style),
      textAlign: textAlign,
    );
  }

  // Helper function to split text and create styled spans.
  List<TextSpan> _generateBionicSpans(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = style ?? defaultStyle;
    final List<TextSpan> spans = [];
    final words = text.split(' ');

    for (var word in words) {
      if (word.isNotEmpty) {
        // Determine the split point (roughly half the word, rounded up).
        final splitPoint = (word.length / 2).ceil();
        final boldPart = word.substring(0, splitPoint);
        final normalPart = word.substring(splitPoint);

        // Create a bolded span for the first part of the word.
        spans.add(TextSpan(
          text: boldPart,
          style: effectiveStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        // Create a regular span for the rest of the word.
        spans.add(TextSpan(
          text: normalPart,
          style: effectiveStyle.copyWith(fontWeight: FontWeight.normal),
        ));
        spans.add(TextSpan(text: ' ', style: effectiveStyle)); // Add space
      }
    }
    // Remove the trailing space span if it exists
    if (spans.isNotEmpty) {
      spans.removeLast();
    }
    return spans;
  }
}

// --- THEME DATA ---
class AppThemes {
  static final List<Color> darkNotebookColors = [
    Colors.blue.shade400,
    Colors.red.shade400,
    Colors.green.shade400,
    Colors.purple.shade400,
    Colors.orange.shade400,
    Colors.teal.shade400,
  ];

  static final List<Color> oceanicNotebookColors = [
    Colors.cyan.shade400,
    Colors.lightBlue.shade400,
    Colors.indigo.shade300,
    Colors.deepPurple.shade300,
    Colors.teal.shade400,
    Colors.blueGrey.shade400,
  ];

  static final List<Color> mintNotebookColors = [
    Colors.teal.shade200,
    Colors.lightGreen.shade200,
    Colors.amber.shade200,
    Colors.lightBlue.shade200,
    Colors.red.shade200,
    Colors.purple.shade200,
  ];

  static final List<Color> sunsetNotebookColors = [
    const Color(0xFFF9A825), // Amber
    const Color(0xFFEF6C00), // Orange
    const Color(0xFFD84315), // Deep Orange
    const Color(0xFFC2185B), // Pink
    const Color(0xFF7B1FA2), // Purple
  ];

  static final List<Color> forestNotebookColors = [
    const Color(0xFF558B2F), // Light Green
    const Color(0xFF2E7D32), // Green
    const Color(0xFF388E3C), // Darker Green
    const Color(0xFF1B5E20), // Darkest Green
    const Color(0xFF6D4C41), // Brown
  ];

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueAccent,
    scaffoldBackgroundColor: const Color(0xFF1F1F1F),
    cardColor: const Color(0xFF2D2D2D),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70),
      headlineSmall:
          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.blueAccent,
      secondary: Colors.tealAccent,
    ),
  );

  static final ThemeData oceanicBlueTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.cyan,
    scaffoldBackgroundColor: const Color(0xFF0A2A43), // Deep ocean blue
    cardColor: const Color(0xFF1A3D5C),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A2A43),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70),
      headlineSmall:
          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.cyanAccent,
      secondary: Colors.lightBlueAccent,
    ),
  );

  static final ThemeData mintGreenTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.teal.shade300,
    scaffoldBackgroundColor:
        const Color(0xFFE8F5E9), // Softer, less bright green
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE8F5E9),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
          color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.black54),
      headlineSmall:
          TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.teal.shade400,
      secondary: Colors.greenAccent.shade400,
    ),
  );

  static final ThemeData sunsetTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFF9A825),
    scaffoldBackgroundColor: const Color(0xFF260e2f), // Deep purple
    cardColor: const Color(0xFF4b1e4f),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70),
      headlineSmall:
          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF9A825), // Amber
      secondary: Color(0xFFEF6C00), // Orange
    ),
  );

  static final ThemeData forestTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF558B2F), // Light Green
    scaffoldBackgroundColor: const Color(0xFF1b2e15), // Dark green-brown
    cardColor: const Color(0xFF2d422a),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70),
      headlineSmall:
          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF558B2F),
      secondary: Color(0xFF8BC34A),
    ),
  );
}

enum AppTheme { dark, oceanicBlue, mintGreen, sunset, forest }

class Notebook {
  final String title;
  List<PlatformFile> files; // Modified to allow adding new files

  Notebook({required this.title, required this.files});
}


// A class to represent different types of sources for a notebook
class NotebookSource {
  final String type; // 'pdf', 'web', 'text'
  final dynamic data; // PlatformFile for 'pdf', String for 'web'/'text'
  final String name; // Filename, URL, or "Pasted Text"

  NotebookSource({required this.type, required this.data, required this.name});
}


// Main application widget - Converted to StatefulWidget
class NotebookApp extends StatefulWidget {
  const NotebookApp({super.key});

  @override
  State<NotebookApp> createState() => _NotebookAppState();
}

class _NotebookAppState extends State<NotebookApp> {
  bool _useOpenDyslexic = false;
  bool _useBionicReading = false;
  ThemeData _currentTheme = AppThemes.darkTheme;
  AppTheme _currentThemeEnum = AppTheme.dark;

  int _leafBalance = 0; // Start at 0 and preload from server

  @override
  void initState() {
    super.initState();
    _fetchInitialLeaves();
  }

  Future<void> _fetchInitialLeaves() async {
    try {
      // Packet Sent: GET request to /get/leaves
      // Packet Received: JSON of the form {'leaves': 10}
      final response = await http.get(Uri.parse('$baseUrl/get/leaves'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _leafBalance = data['leaves'];
        });
      }
    } catch (e) {
      // Handle error, maybe set a default value
      debugPrint("Failed to fetch leaves: $e");
      setState(() {
        _leafBalance = 10; // Default value on error
      });
    }
  }

  Future<void> _updateLeafBalance(int amount) async {
    final newBalance = _leafBalance + amount;
    setState(() {
      _leafBalance = newBalance;
    });

    try {
      // Packet Sent: POST request to /count/leaves with JSON body {'leavesno': new_balance}
      // Packet Received: Success/failure status (not used here)
      await http.post(
        Uri.parse('$baseUrl/count/leaves'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'leavesno': newBalance}),
      );
    } catch (e) {
      debugPrint("Failed to update leaves on server: $e");
    }
  }

  void _toggleFont(bool value) {
    setState(() {
      _useOpenDyslexic = value;
    });
  }

  void _toggleBionicReading(bool value) {
    setState(() {
      _useBionicReading = value;
    });
  }

  void _setTheme(AppTheme theme) {
    setState(() {
      _currentThemeEnum = theme;
      switch (theme) {
        case AppTheme.dark:
          _currentTheme = AppThemes.darkTheme;
          break;
        case AppTheme.oceanicBlue:
          _currentTheme = AppThemes.oceanicBlueTheme;
          break;
        case AppTheme.mintGreen:
          _currentTheme = AppThemes.mintGreenTheme;
          break;
        case AppTheme.sunset:
          _currentTheme = AppThemes.sunsetTheme;
          break;
        case AppTheme.forest:
          _currentTheme = AppThemes.forestTheme;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotebookLM UI Clone',
      debugShowCheckedModeBanner: false,
      theme: _currentTheme.copyWith(
          textTheme: _currentTheme.textTheme.apply(
        fontFamily: _useOpenDyslexic ? 'OpenDyslexic' : 'Inter',
      )),
      home: DashboardScreen(
        isDyslexicFont: _useOpenDyslexic,
        onFontToggle: _toggleFont,
        onThemeSelected: _setTheme,
        currentTheme: _currentThemeEnum,
        leafBalance: _leafBalance,
        onUpdateLeaves: _updateLeafBalance,
        useBionicReading: _useBionicReading,
        onBionicReadingToggle: _toggleBionicReading,
      ),
    );
  }
}

// The main screen that holds the layout with Tab navigation
class DashboardScreen extends StatefulWidget {
  final bool isDyslexicFont;
  final ValueChanged<bool> onFontToggle;
  final ValueChanged<AppTheme> onThemeSelected;
  final AppTheme currentTheme;
  final int leafBalance;
  final ValueChanged<int> onUpdateLeaves;
  final bool useBionicReading;
  final ValueChanged<bool> onBionicReadingToggle;

  const DashboardScreen({
    super.key,
    required this.isDyslexicFont,
    required this.onFontToggle,
    required this.onThemeSelected,
    required this.currentTheme,
    required this.leafBalance,
    required this.onUpdateLeaves,
    required this.useBionicReading,
    required this.onBionicReadingToggle,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'Notebooks'),
            Tab(icon: Icon(Icons.timer_outlined), text: 'Timer'),
            Tab(icon: Icon(Icons.casino), text: 'Gamble'),
            Tab(icon: Icon(Icons.extension), text: 'Bored?'),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Icon(Icons.energy_savings_leaf, color: Colors.green.shade300),
                  const SizedBox(width: 4),
                  Text('${widget.leafBalance}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Row(
            children: [
              BionicText("Bionic Reading", enabled: widget.useBionicReading),
              Switch(
                value: widget.useBionicReading,
                onChanged: widget.onBionicReadingToggle,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              BionicText("Dyslexic Font", enabled: widget.useBionicReading),
              Switch(
                value: widget.isDyslexicFont,
                onChanged: widget.onFontToggle,
              ),
            ],
          ),
          const SizedBox(width: 16),
          _buildThemeSelector(),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MainContent(
              currentTheme: widget.currentTheme,
              useBionicReading: widget.useBionicReading),
          TimerScreen(
              onLeavesEarned: widget.onUpdateLeaves,
              useBionicReading: widget.useBionicReading),
          GambleQuizScreen(
            leafBalance: widget.leafBalance,
            onUpdateLeaves: widget.onUpdateLeaves,
            useBionicReading: widget.useBionicReading,
          ),
          const FidgetGameScreen(),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themeColors = {
      AppTheme.dark: AppThemes.darkTheme.colorScheme.primary,
      AppTheme.oceanicBlue: AppThemes.oceanicBlueTheme.colorScheme.primary,
      AppTheme.mintGreen: AppThemes.mintGreenTheme.colorScheme.primary,
      AppTheme.sunset: AppThemes.sunsetTheme.colorScheme.primary,
      AppTheme.forest: AppThemes.forestTheme.colorScheme.primary,
    };

    return Row(
      children: themeColors.entries.map((entry) {
        final theme = entry.key;
        final color = entry.value;
        final isSelected = widget.currentTheme == theme;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: InkWell(
            onTap: () => widget.onThemeSelected(theme),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).textTheme.bodyLarge!.color!,
                        width: 2)
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

enum TreeType { none, sapling, tree, largeTree }

enum TreeState { none, growing, grown, withered }

class TimerScreen extends StatefulWidget {
  final ValueChanged<int> onLeavesEarned;
  final bool useBionicReading;

  const TimerScreen(
      {super.key,
      required this.onLeavesEarned,
      required this.useBionicReading});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  Timer? _timer;
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  String _selectedMode = '';

  TreeState _treeState = TreeState.none;
  TreeType _treeType = TreeType.none;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_isRunning &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive)) {
      if (mounted) {
        _witherTree();
      }
    }
  }

  void _selectMode(String mode, int seconds) {
    setState(() {
      _selectedMode = mode;
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
      _isRunning = false;
      _timer?.cancel();
      _treeState = TreeState.none;

      if (seconds <= 15 * 60) {
        _treeType = TreeType.sapling;
      } else if (seconds <= 25 * 60) {
        _treeType = TreeType.tree;
      } else {
        _treeType = TreeType.largeTree;
      }
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _treeState = TreeState.growing;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          if (mounted) {
            setState(() {
              _remainingSeconds--;
            });
          }
        } else {
          _timer?.cancel();
          if (mounted) {
            setState(() {
              _plantTree();
              _isRunning = false;
            });
          }
        }
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _giveUp() {
    _witherTree();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _selectedMode = '';
      _totalSeconds = 0;
      _remainingSeconds = 0;
      _treeState = TreeState.none;
      _treeType = TreeType.none;
      _isRunning = false;
    });
  }

  void _plantTree() {
    int leavesEarned = 0;
    switch (_treeType) {
      case TreeType.sapling:
        leavesEarned = 2;
        break;
      case TreeType.tree:
        leavesEarned = 4;
        break;
      case TreeType.largeTree:
        leavesEarned = 8;
        break;
      case TreeType.none:
        break;
    }

    if (leavesEarned > 0) {
      widget.onLeavesEarned(leavesEarned);
    }

    setState(() {
      _treeState = TreeState.grown;
    });
  }

  void _witherTree() {
    _timer?.cancel();
    setState(() {
      _treeState = TreeState.withered;
      _isRunning = false;
    });
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_selectedMode.isEmpty) ...[
              BionicText("Earn Leaves by Focusing",
                  enabled: widget.useBionicReading,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 28)),
              const SizedBox(height: 24),
              _buildTimerSelectionRow(),
            ] else ...[
              _buildStatusMessage(),
              const SizedBox(height: 24),
              _buildTimerDisplay(),
              const SizedBox(height: 48),
              _buildControlButtons(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSelectionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTimerOptionButton(context, "Pomodoro", 25 * 60),
        _buildTimerOptionButton(context, "Short Session", 15 * 60),
        _buildTimerOptionButton(context, "Long Session", 45 * 60),
      ],
    );
  }

  Widget _buildStatusMessage() {
    String message;
    switch (_treeState) {
      case TreeState.growing:
        message = "Stay focused! Your tree is growing.";
        break;
      case TreeState.grown:
        message = "Great job! Tree planted.";
        break;
      case TreeState.withered:
        message = "Don't get distracted next time.";
        break;
      case TreeState.none:
      default:
        message = "Ready to plant a tree?";
        break;
    }
    return BionicText(
      message,
      enabled: widget.useBionicReading,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
    );
  }

  Widget _buildTimerDisplay() {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0,
            strokeWidth: 12,
            backgroundColor: Theme.of(context).cardColor,
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTreeVisual(),
                const SizedBox(height: 16),
                Text(
                  _formattedTime,
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeVisual() {
    IconData icon;
    Color color;
    double scale = 1.0;

    double growthPercentage = _totalSeconds > 0
        ? (_totalSeconds - _remainingSeconds) / _totalSeconds
        : 0.0;

    switch (_treeState) {
      case TreeState.grown:
        icon = Icons.park;
        color = Colors.green;
        scale = 1.0;
        break;
      case TreeState.withered:
        icon = Icons.do_not_disturb_on_total_silence_rounded;
        color = Colors.brown;
        scale = 1.0;
        break;
      case TreeState.growing:
        scale = 0.6 + (growthPercentage * 0.4);
        color = Colors.lightGreen;
        switch (_treeType) {
          case TreeType.sapling:
            icon = growthPercentage < 0.5 ? Icons.spa_outlined : Icons.spa;
            break;
          case TreeType.tree:
            icon = growthPercentage < 0.5
                ? Icons.energy_savings_leaf_outlined
                : Icons.energy_savings_leaf;
            break;
          case TreeType.largeTree:
          default:
            icon =
                growthPercentage < 0.5 ? Icons.forest_outlined : Icons.forest;
            break;
        }
        break;
      case TreeState.none:
      default:
        color = Colors.grey;
        if (_treeType != TreeType.none) {
          scale = 0.6;
          switch (_treeType) {
            case TreeType.sapling:
              icon = Icons.spa_outlined;
              break;
            case TreeType.tree:
              icon = Icons.energy_savings_leaf_outlined;
              break;
            case TreeType.largeTree:
            default:
              icon = Icons.forest_outlined;
              break;
          }
        } else {
          icon = Icons.grass;
          scale = 1.0;
        }
        break;
    }

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(child: child, opacity: animation);
        },
        child: Icon(
          icon,
          key: ValueKey<IconData>(icon),
          size: 80,
          color: color,
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    if (_isRunning) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.pause_circle_filled, size: 64),
            color: Theme.of(context).colorScheme.primary,
            onPressed: _toggleTimer,
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.cancel, size: 48),
            color: Colors.red.shade400,
            onPressed: _giveUp,
            tooltip: "Give Up",
          ),
        ],
      );
    }

    if (_treeState == TreeState.grown || _treeState == TreeState.withered) {
      return ElevatedButton(
        onPressed: _reset,
        child: BionicText("Start Another Session",
            enabled: widget.useBionicReading),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.play_circle_filled, size: 64),
          color: Theme.of(context).colorScheme.primary,
          onPressed: _toggleTimer,
          tooltip: "Start Timer",
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(Icons.arrow_back, size: 48),
          onPressed: _reset,
          tooltip: "Change Timer",
        ),
      ],
    );
  }

  Widget _buildTimerOptionButton(
      BuildContext context, String title, int seconds) {
    return ElevatedButton(
      onPressed: () => _selectMode(title, seconds),
      style: ElevatedButton.styleFrom(
        foregroundColor: _selectedMode == title
            ? (Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white)
            : Theme.of(context).textTheme.bodyLarge?.color,
        backgroundColor: _selectedMode == title
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: BionicText(title,
          enabled: widget.useBionicReading,
          style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// --- NEW GAMBLE QUIZ SCREEN ---

class GambleQuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  GambleQuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory GambleQuizQuestion.fromJson(Map<String, dynamic> json) {
    return GambleQuizQuestion(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'],
    );
  }
}

class GambleQuizScreen extends StatefulWidget {
  final int leafBalance;
  final ValueChanged<int> onUpdateLeaves;
  final bool useBionicReading;

  const GambleQuizScreen({
    super.key,
    required this.leafBalance,
    required this.onUpdateLeaves,
    required this.useBionicReading,
  });

  @override
  State<GambleQuizScreen> createState() => _GambleQuizScreenState();
}

class _GambleQuizScreenState extends State<GambleQuizScreen>
    with AutomaticKeepAliveClientMixin {
  GambleQuizQuestion? _currentQuestion;
  bool _isLoading = true;
  int _betAmount = 1;
  int? _selectedAnswerIndex;
  bool _showResult = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchQuestion();
  }

  Future<void> _fetchQuestion() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Packet Sent: GET request to /generate/gamblequiz/
      // Packet Received: JSON for a single question:
      // {
      //   "question": "What is the powerhouse of the cell?",
      //   "options": ["Nucleus", "Ribosome", "Mitochondrion", "Golgi apparatus"],
      //   "correctAnswerIndex": 2
      // }
      final response = await http.get(Uri.parse('$baseUrl/generate/gamblequiz/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentQuestion = GambleQuizQuestion.fromJson(data);
          _isLoading = false;
        });
      } else {
        // Handle error
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch gamble quiz question: $e");
      setState(() => _isLoading = false);
    }
  }

  void _submitAnswer() {
    if (_currentQuestion == null) return;
    setState(() {
      _showResult = true;
      bool isCorrect =
          _selectedAnswerIndex == _currentQuestion!.correctAnswerIndex;
      if (isCorrect) {
        widget.onUpdateLeaves(_betAmount);
      } else {
        widget.onUpdateLeaves(-_betAmount);
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _selectedAnswerIndex = null;
      _showResult = false;
      _betAmount = 1;
    });
    _fetchQuestion();
  }

  Color _getTileColor(int optionIndex) {
    if (!_showResult || _currentQuestion == null) {
      return Theme.of(context).cardColor;
    }
    if (optionIndex == _currentQuestion!.correctAnswerIndex) {
      return Colors.green.withOpacity(0.5);
    }
    if (optionIndex == _selectedAnswerIndex) {
      return Colors.red.withOpacity(0.5);
    }
    return Theme.of(context).cardColor;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentQuestion == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Failed to load question."),
            ElevatedButton(
              onPressed: _fetchQuestion,
              child: const Text("Try Again"),
            )
          ],
        ),
      );
    }

    final currentQuestion = _currentQuestion!;
    final canBetMore = _betAmount < widget.leafBalance;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BionicText("Gamble Your Leaves!",
                enabled: widget.useBionicReading,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            BionicText(
              currentQuestion.question,
              enabled: widget.useBionicReading,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...List.generate(currentQuestion.options.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: RadioListTile<int>(
                  value: index,
                  groupValue: _selectedAnswerIndex,
                  tileColor: _getTileColor(index),
                  onChanged: _showResult
                      ? null
                      : (value) => setState(() => _selectedAnswerIndex = value),
                  title: BionicText(currentQuestion.options[index],
                      enabled: widget.useBionicReading),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            }),
            const SizedBox(height: 32),
            _buildBettingControls(canBetMore),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBettingControls(bool canBetMore) {
    return Column(
      children: [
        BionicText("Your Bet",
            enabled: widget.useBionicReading,
            style: Theme.of(context).textTheme.titleMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _showResult || _betAmount <= 1
                  ? null
                  : () => setState(() => _betAmount--),
            ),
            Text("$_betAmount",
                style: Theme.of(context).textTheme.headlineSmall),
            Icon(Icons.energy_savings_leaf, color: Colors.green.shade300),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _showResult || !canBetMore
                  ? null
                  : () => setState(() => _betAmount++),
            ),
          ],
        ),
        if (!canBetMore && !_showResult)
          BionicText("You can't bet more than you have!",
              enabled: widget.useBionicReading,
              style: TextStyle(color: Colors.orange.shade300)),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_showResult) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.arrow_forward),
        label: BionicText("Next Question", enabled: widget.useBionicReading),
        onPressed: _nextQuestion,
      );
    }
    return ElevatedButton.icon(
      icon: const Icon(Icons.casino),
      label: BionicText("Place Bet", enabled: widget.useBionicReading),
      onPressed: _selectedAnswerIndex == null ? null : _submitAnswer,
    );
  }
}

// Data class for a single conversation entry
class Interaction {
  final String prompt;
  final String selectedMode;
  Widget? result;
  bool isLoading;

  Interaction({
    required this.prompt,
    required this.selectedMode,
    this.result,
    this.isLoading = false,
  });
}

class MainContent extends StatefulWidget {
  final AppTheme currentTheme;
  final bool useBionicReading;
  const MainContent(
      {super.key, required this.currentTheme, required this.useBionicReading});

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent>
    with AutomaticKeepAliveClientMixin {
  final List<Notebook> _notebooks = [];
  Notebook? _selectedNotebook;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchInitialNotebooks();
  }

  Future<void> _fetchInitialNotebooks() async {
    setState(() => _isLoading = true);
    try {
      // Packet Sent: GET request to /notebooks
      // Packet Received: JSON array of notebooks, e.g.,
      // [
      //   {"title": "Biology Notes", "files": ["cell.pdf", "dna.pdf"]},
      //   {"title": "History 101", "files": ["ww2.pdf"]}
      // ]
      final response = await http.get(Uri.parse('$baseUrl/notebooks'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Notebook> notebooks = data.map((item) {
          final List<dynamic> filesData = item['files'];
          final List<PlatformFile> files = filesData.map((fileName) {
            return PlatformFile(name: fileName, size: 0, path: null); // Dummy size and path
          }).toList();
          return Notebook(title: item['title'], files: files);
        }).toList();

        setState(() {
          _notebooks.addAll(notebooks);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Failed to fetch initial notebooks: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNotebook(String title, List<NotebookSource> sources) async {
    // Packet Sent: Multipart POST request to /create/notebook
    // - 'title': The notebook title (string)
    // - 'files': One or more file parts for PDFs
    // - 'web_sources': A comma-separated string of URLs
    // - 'text_sources': A JSON string array of pasted texts
    // Packet Received: Success/failure status
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/create/notebook'));
    request.fields['title'] = title;

    List<String> webSources = [];
    List<String> textSources = [];
    List<PlatformFile> uiFiles = [];

    for (var source in sources) {
      switch (source.type) {
        case 'pdf':
          PlatformFile file = source.data as PlatformFile;
          request.files.add(await http.MultipartFile.fromPath(
            'files',
            file.path!, // Note: file.path is only available on native platforms
            filename: file.name,
            contentType: MediaType('application', 'pdf'),
          ));
          uiFiles.add(file);
          break;
        case 'web':
          webSources.add(source.data as String);
           uiFiles.add(PlatformFile(name: source.name, size: 0, path: null));
          break;
        case 'text':
          textSources.add(source.data as String);
           uiFiles.add(PlatformFile(name: source.name, size: 0, path: null));
          break;
      }
    }

    if (webSources.isNotEmpty) {
      request.fields['web_sources'] = webSources.join(',');
    }
    if (textSources.isNotEmpty) {
      request.fields['text_sources'] = json.encode(textSources);
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        setState(() {
          _notebooks.add(Notebook(title: title, files: uiFiles));
        });
      } else {
        // Handle error, show a snackbar maybe
        final responseBody = await response.stream.bytesToString();
        debugPrint("Failed to create notebook on server: ${response.statusCode} $responseBody");
      }
    } catch (e) {
      debugPrint("Error creating notebook: $e");
    }
  }

  Future<void> _deleteNotebook(Notebook notebookToDelete) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: BionicText("Delete Notebook?", enabled: widget.useBionicReading),
        content: BionicText(
          "Are you sure you want to delete '${notebookToDelete.title}'? This action cannot be undone.",
          enabled: widget.useBionicReading,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: BionicText("Cancel", enabled: widget.useBionicReading),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: BionicText("Delete", enabled: widget.useBionicReading),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('$baseUrl/delete/notebook/${notebookToDelete.title}'),
        );
        if (mounted && response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: BionicText('Notebook "${notebookToDelete.title}" deleted.', enabled: widget.useBionicReading)),
          );
          setState(() {
            _notebooks.removeWhere((notebook) => notebook.title == notebookToDelete.title);
            if (_selectedNotebook?.title == notebookToDelete.title) {
              _selectedNotebook = null;
            }
          });
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete notebook. Status: ${response.statusCode}')),
          );
          debugPrint("Failed to delete notebook on server: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("Error deleting notebook: $e");
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An error occurred while deleting.')),
            );
          }
      }
    }
  }

  Future<void> _addSourcesToNotebook(Notebook notebookToUpdate, List<NotebookSource> newSources) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/add-sources/${notebookToUpdate.title}'));
    
    List<String> webSources = [];
    List<String> textSources = [];
    List<PlatformFile> uiFiles = [];

    for (var source in newSources) {
      switch (source.type) {
        case 'pdf':
          PlatformFile file = source.data as PlatformFile;
          // Note: On web, file.path is null. We'd need to use file.bytes.
          // This implementation assumes non-web platforms for file uploads.
          if (file.path != null) {
             request.files.add(await http.MultipartFile.fromPath(
              'files',
              file.path!,
              filename: file.name,
              contentType: MediaType('application', 'pdf'),
            ));
          }
          uiFiles.add(file);
          break;
        case 'web':
          webSources.add(source.data as String);
           uiFiles.add(PlatformFile(name: source.name, size: 0, path: null));
          break;
        case 'text':
          textSources.add(source.data as String);
           uiFiles.add(PlatformFile(name: source.name, size: 0, path: null));
          break;
      }
    }

    if (webSources.isNotEmpty) {
      request.fields['web_sources'] = webSources.join(',');
    }
    if (textSources.isNotEmpty) {
      request.fields['text_sources'] = json.encode(textSources);
    }
    
    try {
      final response = await request.send();
      if (mounted && response.statusCode == 200) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: BionicText('Sources added to "${notebookToUpdate.title}".', enabled: widget.useBionicReading)),
          );
        setState(() {
          final notebook = _notebooks.firstWhere((n) => n.title == notebookToUpdate.title);
          notebook.files.addAll(uiFiles);
        });
      } else if (mounted){
         final responseBody = await response.stream.bytesToString();
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add sources. Status: ${response.statusCode}')),
          );
        debugPrint("Failed to add sources on server: ${response.statusCode} $responseBody");
      }
    } catch (e) {
      debugPrint("Error adding sources: $e");
       if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An error occurred while adding sources.')),
            );
          }
    }
  }


  void _selectNotebook(Notebook notebook) {
    setState(() {
      _selectedNotebook = notebook;
    });
  }

  void _unselectNotebook() {
    setState(() {
      _selectedNotebook = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_selectedNotebook != null) {
      return Row(
        children: [
          SizedBox(
            width: 300,
            child: NotebooksSidebar(
              notebooks: _notebooks,
              onNotebookSelected: _selectNotebook,
              onAddNotebook: _addNotebook,
              onDeleteNotebook: _deleteNotebook,
              currentTheme: widget.currentTheme,
              useBionicReading: widget.useBionicReading,
            ),
          ),
          VerticalDivider(width: 1, color: Colors.grey[800]),
          Expanded(
            child: NotebookDetailView(
              notebook: _selectedNotebook!,
              onBack: _unselectNotebook,
              useBionicReading: widget.useBionicReading,
              onAddSources: (newSources) => _addSourcesToNotebook(_selectedNotebook!, newSources),
            ),
          ),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 40),
            BionicText(
              "Your Notebooks",
              enabled: widget.useBionicReading,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 160,
                        child: CreateNewCard(
                          onCreate: _addNotebook,
                          useBionicReading: widget.useBionicReading,
                        ),
                      ),
                      ..._notebooks.asMap().entries.map((entry) {
                        int index = entry.key;
                        Notebook notebook = entry.value;
                        return SizedBox(
                          width: 250,
                          height: 160,
                          child: NotebookCard(
                            notebook: notebook,
                            index: index,
                            currentTheme: widget.currentTheme,
                            onTap: () => _selectNotebook(notebook),
                            onDelete: () => _deleteNotebook(notebook),
                            useBionicReading: widget.useBionicReading,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              )
          ],
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: 'Hey There, What do we feel like learning today?',
            hintStyle:
                TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class NotebooksSidebar extends StatelessWidget {
  final List<Notebook> notebooks;
  final Function(Notebook) onNotebookSelected;
  final Function(String, List<NotebookSource>) onAddNotebook;
  final Function(Notebook) onDeleteNotebook;
  final AppTheme currentTheme;
  final bool useBionicReading;

  const NotebooksSidebar({
    super.key,
    required this.notebooks,
    required this.onNotebookSelected,
    required this.onAddNotebook,
    required this.onDeleteNotebook,
    required this.currentTheme,
    required this.useBionicReading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BionicText(
              "Your Notebooks",
              enabled: useBionicReading,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 120,
              child: CreateNewCard(
                  onCreate: onAddNotebook, useBionicReading: useBionicReading),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: notebooks.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: NotebookCard(
                      notebook: notebooks[index],
                      index: index,
                      currentTheme: currentTheme,
                      onTap: () => onNotebookSelected(notebooks[index]),
                      onDelete: () => onDeleteNotebook(notebooks[index]),
                      useBionicReading: useBionicReading,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotebookDetailView extends StatefulWidget {
  final Notebook notebook;
  final VoidCallback onBack;
  final bool useBionicReading;
  final Function(List<NotebookSource>) onAddSources;

  const NotebookDetailView(
      {super.key,
      required this.notebook,
      required this.onBack,
      required this.useBionicReading,
      required this.onAddSources});

  @override
  State<NotebookDetailView> createState() => _NotebookDetailViewState();
}

class _NotebookDetailViewState extends State<NotebookDetailView> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedValue = 'Quick question';
  final List<Interaction> _conversationHistory = [];
  bool _isToolActive = false;

  Future<void> _handleSubmit() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty &&
        _selectedValue != 'Concentration Game' &&
        _selectedValue != 'Quiz') {
      return;
    }

    final interaction = Interaction(
      prompt: prompt,
      selectedMode: _selectedValue,
      isLoading: true,
    );

    setState(() {
      _conversationHistory.add(interaction);
      _promptController.clear();
    });
    _scrollToBottom();

    Widget? resultWidget;
    try {
      if (_selectedValue == 'Quick question') {
        // Packet Sent: POST to /generate/qq with JSON {'topic': 'user_prompt', 'notebook': 'notebook_title'}
        final response = await http.post(
          Uri.parse('$baseUrl/generate/qq'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'topic': prompt, 'notebook': widget.notebook.title}),
        );
        final data = json.decode(response.body);
        resultWidget = QuestionAnswerWidget(
          question: prompt,
          answer: data['answer'],
          useBionicReading: widget.useBionicReading,
        );
      } else if (_selectedValue == 'Quiz') {
        final int? count = await _showQuizCountDialog();
        if (count != null && count > 0) {
          setState(() => _isToolActive = true);
          // Packet Sent: POST to /generate/quiz with JSON {'topic': 'user_prompt', 'n': count, 'notebook': 'notebook_title'}
          final response = await http.post(
            Uri.parse('$baseUrl/generate/quiz'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'topic': prompt, 'n': count, 'notebook': widget.notebook.title}),
          );
          final List<dynamic> data = json.decode(response.body);
          final questions = data.map((item) => QuizItem.fromJson(item)).toList();
          resultWidget = QuizWidget(
            questions: questions,
            onQuizCompleted: () => setState(() => _isToolActive = false),
            useBionicReading: widget.useBionicReading,
          );
        }
      } else if (_selectedValue == 'Concentration Game') {
        final int? cardCount = await _showConcentrationCountDialog();
        if (cardCount != null && cardCount > 0) {
          setState(() => _isToolActive = true);
           // Packet Sent: POST to /generate/concentrate with JSON {'topic': 'user_prompt', 'n': card_count, 'notebook': 'notebook_title'}
          final response = await http.post(
            Uri.parse('$baseUrl/generate/concentrate'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'topic': prompt, 'n': cardCount, 'notebook': widget.notebook.title}),
          );
          final List<dynamic> data = json.decode(response.body);
          final qaPairs = data.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;
            return QAPair.fromJson(item, index);
          }).toList();
          resultWidget = FlashcardGameFlow(
            qaPairs: qaPairs,
            useBionicReading: widget.useBionicReading,
            onGameCompleted: () {
              setState(() => _isToolActive = false);
            },
          );
        }
      }
    } catch (e) {
      debugPrint("API Error on submit: $e");
      resultWidget = const Text("Sorry, an error occurred.");
    }

    setState(() {
      interaction.isLoading = false;
      interaction.result = resultWidget;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<int?> _showConcentrationCountDialog() {
    TextEditingController countController = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: BionicText('Number of Card Pairs',
              enabled: widget.useBionicReading),
          content: TextField(
            controller: countController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: "Enter a number (e.g., 8)"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: BionicText('Cancel', enabled: widget.useBionicReading)),
            TextButton(
                onPressed: () => Navigator.of(context)
                    .pop(int.tryParse(countController.text)),
                child: BionicText('OK', enabled: widget.useBionicReading)),
          ],
        );
      },
    );
  }

  Future<int?> _showQuizCountDialog() {
    TextEditingController countController = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: BionicText('Number of Questions',
              enabled: widget.useBionicReading),
          content: TextField(
            controller: countController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter a number"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: BionicText('Cancel', enabled: widget.useBionicReading)),
            TextButton(
                onPressed: () => Navigator.of(context)
                    .pop(int.tryParse(countController.text)),
                child: BionicText('OK', enabled: widget.useBionicReading)),
          ],
        );
      },
    );
  }

  Future<void> _showAddSourceDialog() async {
    final newSources = await showDialog<List<NotebookSource>>(
      context: context,
      builder: (context) => AddSourceDialog(useBionicReading: widget.useBionicReading),
    );

    if (newSources != null && newSources.isNotEmpty) {
      widget.onAddSources(newSources);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isToolSelected = _selectedValue != 'Quick question';

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BionicText(widget.notebook.title,
                        enabled: widget.useBionicReading,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 28)),
                    BionicText('${widget.notebook.files.length} sources',
                        enabled: widget.useBionicReading,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _showAddSourceDialog,
                tooltip: "Add new source",
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: isToolSelected ? 4.0 : 0.0,
                      sigmaY: isToolSelected ? 4.0 : 0.0,
                    ),
                    child: AbsorbPointer(
                      absorbing: isToolSelected,
                      child: _conversationHistory.isEmpty
                          ? Center(
                              child: BionicText(
                              "Ask a question or generate a study tool to get started.",
                              enabled: widget.useBionicReading,
                              textAlign: TextAlign.center,
                            ))
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _conversationHistory.length,
                              itemBuilder: (context, index) {
                                final interaction = _conversationHistory[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      BionicText(
                                          interaction.prompt.isNotEmpty
                                              ? interaction.prompt
                                              : "Generate ${interaction.selectedMode}",
                                          enabled: widget.useBionicReading,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary)),
                                      const SizedBox(height: 16),
                                      if (interaction.isLoading)
                                        const Center(
                                            child: CircularProgressIndicator())
                                      else if (interaction.selectedMode ==
                                          'Quick question')
                                        interaction.result ??
                                            const SizedBox.shrink(),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
                if (isToolSelected) ...[
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _buildToolView(),
                  ),
                ]
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
            child: _buildInputControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolView() {
    final lastInteraction =
        _conversationHistory.isNotEmpty ? _conversationHistory.last : null;
    if (lastInteraction != null &&
        lastInteraction.selectedMode != 'Quick question') {
      if (lastInteraction.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return lastInteraction.result ?? const SizedBox.shrink();
    }
    return Center(
        child: BionicText("Submit to generate your selected study tool.",
            enabled: widget.useBionicReading));
  }

  Widget _buildInputControls() {
    final Map<String, IconData> modeIcons = {
      'Quick question': Icons.question_answer_outlined,
      'Quiz': Icons.quiz_outlined,
      'Concentration Game': Icons.style_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _promptController,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'Enter a prompt...',
              hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: _isToolActive
                          ? Colors.grey.shade800
                          : Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8)),
                  child: DropdownButton<String>(
                    value: _selectedValue,
                    isExpanded: true,
                    underline: const SizedBox(),
                    onChanged: _isToolActive
                        ? null
                        : (String? newValue) =>
                            setState(() => _selectedValue = newValue!),
                    items: <String>[
                      'Quick question',
                      'Quiz',
                      'Concentration Game'
                    ]
                        .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      Icon(modeIcons[value],
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color),
                                      const SizedBox(width: 12),
                                      BionicText(value,
                                          enabled: widget.useBionicReading),
                                    ],
                                  ),
                                ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isToolActive ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: BionicText('Submit', enabled: widget.useBionicReading),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreateNewCard extends StatelessWidget {
  final Function(String, List<NotebookSource>) onCreate;
  final bool useBionicReading;
  const CreateNewCard(
      {super.key, required this.onCreate, required this.useBionicReading});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color:
                Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.5),
            width: 1.5),
      ),
      child: InkWell(
        onTap: () async {
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (BuildContext context) {
              return UploadSourceDialog(useBionicReading: useBionicReading);
            },
          );
          if (result != null &&
              result['title'] != null &&
              result['sources'] != null) {
            onCreate(result['title'], result['sources']);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  size: 36),
              const SizedBox(height: 12),
              BionicText(
                "Create new notebook",
                enabled: useBionicReading,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadSourceDialog extends StatefulWidget {
  final bool useBionicReading;
  const UploadSourceDialog({super.key, required this.useBionicReading});

  @override
  State<UploadSourceDialog> createState() => _UploadSourceDialogState();
}

class _UploadSourceDialogState extends State<UploadSourceDialog> {
  final TextEditingController _titleController = TextEditingController();
  final List<NotebookSource> _sources = [];

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        for (var file in result.files) {
           _sources.add(NotebookSource(type: 'pdf', data: file, name: file.name));
        }
      });
    }
  }

  Future<void> _addWebSource() async {
    final TextEditingController urlController = TextEditingController();
    final url = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Add Website"),
              content: TextField(
                controller: urlController,
                decoration: const InputDecoration(hintText: "https://example.com"),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(urlController.text),
                    child: const Text("Add")),
              ],
            ));
    if (url != null && url.isNotEmpty) {
      setState(() {
        _sources.add(NotebookSource(type: 'web', data: url, name: url));
      });
    }
  }

    Future<void> _addTextSource() async {
    final TextEditingController textController = TextEditingController();
    final text = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Paste Text"),
              content: TextField(
                controller: textController,
                maxLines: 10,
                decoration: const InputDecoration(hintText: "Paste your text here..."),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(textController.text),
                    child: const Text("Add")),
              ],
            ));
    if (text != null && text.isNotEmpty) {
      setState(() {
         _sources.add(NotebookSource(type: 'text', data: text, name: 'Pasted Text (${text.substring(0, min(15, text.length))}...)'));
      });
    }
  }

  void _showDrivePicker() {
    // This is a placeholder for a real Drive picker implementation
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Google Drive integration is not yet implemented.'),
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BionicText('Create new notebook',
                    enabled: widget.useBionicReading,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 20)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notebook Title',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            BionicText('Add up to 20 sources to get started.',
                enabled: widget.useBionicReading,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSourceOption(context,
                    icon: Icons.drive_folder_upload, label: 'Drive', onTap: _showDrivePicker),
                _buildSourceOption(context,
                    icon: Icons.upload_file,
                    label: 'Upload file',
                    onTap: _pickFiles),
                _buildSourceOption(context,
                    icon: Icons.paste, label: 'Paste text', onTap: _addTextSource),
                _buildSourceOption(context,
                    icon: Icons.public, label: 'Website', onTap: _addWebSource),
              ],
            ),
            if (_sources.isNotEmpty) ...[
              const SizedBox(height: 16),
              BionicText('Selected sources:',
                  enabled: widget.useBionicReading,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: _sources.length,
                  itemBuilder: (context, index) {
                    final source = _sources[index];
                    IconData icon;
                    switch (source.type) {
                      case 'pdf': icon = Icons.picture_as_pdf_outlined; break;
                      case 'web': icon = Icons.public_outlined; break;
                      case 'text': icon = Icons.paste_outlined; break;
                      default: icon = Icons.insert_drive_file_outlined;
                    }
                    return ListTile(
                      leading: Icon(icon),
                      title: BionicText(source.name,
                          enabled: widget.useBionicReading,
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _sources.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _sources.isEmpty ||
                        _titleController.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context)
                        .pop({'title': _titleController.text, 'sources': _sources}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  disabledBackgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  disabledForegroundColor: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withOpacity(0.7),
                ),
                child: BionicText('Create', enabled: widget.useBionicReading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(BuildContext context,
      {required IconData icon, required String label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: Theme.of(context).textTheme.bodyMedium?.color, size: 28),
            const SizedBox(height: 8),
            BionicText(label,
                enabled: widget.useBionicReading,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color)),
          ],
        ),
      ),
    );
  }
}

// New Dialog for adding sources to an existing notebook
class AddSourceDialog extends StatefulWidget {
  final bool useBionicReading;
  const AddSourceDialog({super.key, required this.useBionicReading});

  @override
  State<AddSourceDialog> createState() => _AddSourceDialogState();
}

class _AddSourceDialogState extends State<AddSourceDialog> {
  final List<NotebookSource> _sources = [];

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        for (var file in result.files) {
           _sources.add(NotebookSource(type: 'pdf', data: file, name: file.name));
        }
      });
    }
  }

  Future<void> _addWebSource() async {
    final TextEditingController urlController = TextEditingController();
    final url = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Add Website"),
              content: TextField(
                controller: urlController,
                decoration: const InputDecoration(hintText: "https://example.com"),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(urlController.text),
                    child: const Text("Add")),
              ],
            ));
    if (url != null && url.isNotEmpty) {
      setState(() {
        _sources.add(NotebookSource(type: 'web', data: url, name: url));
      });
    }
  }

  Future<void> _addTextSource() async {
    final TextEditingController textController = TextEditingController();
    final text = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Paste Text"),
              content: TextField(
                controller: textController,
                maxLines: 10,
                decoration: const InputDecoration(hintText: "Paste your text here..."),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(textController.text),
                    child: const Text("Add")),
              ],
            ));
    if (text != null && text.isNotEmpty) {
      setState(() {
         _sources.add(NotebookSource(type: 'text', data: text, name: 'Pasted Text (${text.substring(0, min(15, text.length))}...)'));
      });
    }
  }
  
  void _showDrivePicker() {
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Google Drive integration is not yet implemented.'),
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BionicText('Add new sources',
                    enabled: widget.useBionicReading,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 20)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 16),
            BionicText('Add sources to the current notebook.',
                enabled: widget.useBionicReading,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSourceOption(context,
                    icon: Icons.drive_folder_upload, label: 'Drive', onTap: _showDrivePicker),
                _buildSourceOption(context,
                    icon: Icons.upload_file,
                    label: 'Upload file',
                    onTap: _pickFiles),
                _buildSourceOption(context,
                    icon: Icons.paste, label: 'Paste text', onTap: _addTextSource),
                _buildSourceOption(context,
                    icon: Icons.public, label: 'Website', onTap: _addWebSource),
              ],
            ),
            if (_sources.isNotEmpty) ...[
              const SizedBox(height: 16),
              BionicText('New sources:',
                  enabled: widget.useBionicReading,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: _sources.length,
                  itemBuilder: (context, index) {
                    final source = _sources[index];
                    IconData icon;
                    switch (source.type) {
                      case 'pdf': icon = Icons.picture_as_pdf_outlined; break;
                      case 'web': icon = Icons.public_outlined; break;
                      case 'text': icon = Icons.paste_outlined; break;
                      default: icon = Icons.insert_drive_file_outlined;
                    }
                    return ListTile(
                      leading: Icon(icon),
                      title: BionicText(source.name,
                          enabled: widget.useBionicReading,
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _sources.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _sources.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_sources),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  disabledBackgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  disabledForegroundColor: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withOpacity(0.7),
                ),
                child: BionicText('Add Sources', enabled: widget.useBionicReading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(BuildContext context,
      {required IconData icon, required String label, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: Theme.of(context).textTheme.bodyMedium?.color, size: 28),
            const SizedBox(height: 8),
            BionicText(label,
                enabled: widget.useBionicReading,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color)),
          ],
        ),
      ),
    );
  }
}


class NotebookCard extends StatelessWidget {
  final Notebook notebook;
  final int index;
  final AppTheme currentTheme;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final bool useBionicReading;
  const NotebookCard(
      {super.key,
      required this.notebook,
      this.onTap,
      required this.index,
      required this.currentTheme,
      required this.onDelete,
      required this.useBionicReading});

  @override
  Widget build(BuildContext context) {
    List<Color> colorPalette;
    switch (currentTheme) {
      case AppTheme.dark:
        colorPalette = AppThemes.darkNotebookColors;
        break;
      case AppTheme.oceanicBlue:
        colorPalette = AppThemes.oceanicNotebookColors;
        break;
      case AppTheme.mintGreen:
        colorPalette = AppThemes.mintNotebookColors;
        break;
      case AppTheme.sunset:
        colorPalette = AppThemes.sunsetNotebookColors;
        break;
      case AppTheme.forest:
        colorPalette = AppThemes.forestNotebookColors;
        break;
    }
    final color = colorPalette[index % colorPalette.length];

    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 32.0), // Space for button
                      child: BionicText(
                        notebook.title,
                        enabled: useBionicReading,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: textColor),
                      ),
                    ),
                    BionicText('${notebook.files.length} sources',
                        enabled: useBionicReading,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: textColor.withOpacity(0.7))),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red.shade400),
                          const SizedBox(width: 8),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(Icons.more_vert, color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionAnswerWidget extends StatelessWidget {
  final String question;
  final String answer;
  final bool useBionicReading;
  const QuestionAnswerWidget(
      {super.key,
      required this.question,
      required this.answer,
      required this.useBionicReading});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BionicText(answer,
              enabled: useBionicReading,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class QuizItem {
  final String question;
  final List<String> options;
  final String correctAnswer;
  QuizItem(
      {required this.question,
      required this.options,
      required this.correctAnswer});

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    return QuizItem(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
    );
  }
}

class QuizWidget extends StatefulWidget {
  final List<QuizItem> questions;
  final VoidCallback onQuizCompleted;
  final bool useBionicReading;
  const QuizWidget(
      {super.key,
      required this.questions,
      required this.onQuizCompleted,
      required this.useBionicReading});

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  final Map<int, String> _selectedAnswers = {};
  bool _showResults = false;

  void _checkAnswers() {
    setState(() => _showResults = true);
    int correctCount = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (_selectedAnswers[i] == widget.questions[i].correctAnswer) {
        correctCount++;
      }
    }

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title:
                  BionicText("Quiz Results", enabled: widget.useBionicReading),
              content: BionicText(
                  "You got $correctCount out of ${widget.questions.length} correct!",
                  enabled: widget.useBionicReading),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: BionicText("OK", enabled: widget.useBionicReading))
              ],
            ));
  }

  void _finishQuiz() {
    widget.onQuizCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.questions.length,
            itemBuilder: (context, index) {
              final question = widget.questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BionicText("Question ${index + 1}: ${question.question}",
                          enabled: widget.useBionicReading,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ...question.options.map((option) {
                        Color? tileColor;
                        if (_showResults) {
                          if (option == question.correctAnswer) {
                            tileColor = Colors.green.withOpacity(0.5);
                          } else if (option == _selectedAnswers[index]) {
                            tileColor = Colors.red.withOpacity(0.5);
                          }
                        }

                        return RadioListTile<String>(
                          title: BionicText(option,
                              enabled: widget.useBionicReading),
                          value: option,
                          groupValue: _selectedAnswers[index],
                          onChanged: _showResults
                              ? null
                              : (value) {
                                  setState(
                                      () => _selectedAnswers[index] = value!);
                                },
                          tileColor: tileColor,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_showResults)
              ElevatedButton(
                  onPressed: _finishQuiz,
                  child: BionicText('Finish Quiz',
                      enabled: widget.useBionicReading)),
            const SizedBox(width: 16),
            ElevatedButton(
                onPressed: _showResults ? null : _checkAnswers,
                child: BionicText('Check Answers',
                    enabled: widget.useBionicReading)),
          ],
        )
      ],
    );
  }
}

class Flashcard {
  final String front;
  final String back;
  Flashcard({required this.front, required this.back});
}

class FlashcardViewer extends StatefulWidget {
  final List<Flashcard> flashcards;
  final VoidCallback onFinished;
  final bool showStartGameButton;
  final bool useBionicReading;
  const FlashcardViewer({
    super.key,
    required this.flashcards,
    required this.onFinished,
    this.showStartGameButton = true,
    required this.useBionicReading,
  });

  @override
  State<FlashcardViewer> createState() => _FlashcardViewerState();
}

class _FlashcardViewerState extends State<FlashcardViewer> {
  int _currentIndex = 0;
  bool _isFlipped = false;

  final List<Color> _flashcardColors = [
    Colors.lightBlue.shade100,
    Colors.lightGreen.shade100,
    Colors.orange.shade100,
    Colors.purple.shade100,
    Colors.pink.shade100,
    Colors.teal.shade100
  ];

  void _flipCard() => setState(() => _isFlipped = !_isFlipped);
  void _nextCard() => setState(() {
        _isFlipped = false;
        _currentIndex = (_currentIndex + 1) % widget.flashcards.length;
      });
  void _prevCard() => setState(() {
        _isFlipped = false;
        _currentIndex = (_currentIndex - 1 + widget.flashcards.length) %
            widget.flashcards.length;
      });

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return const Center(child: Text("No flashcards to display."));
    }

    final cardColor = _flashcardColors[_currentIndex % _flashcardColors.length];
    final textColor =
        ThemeData.estimateBrightnessForColor(cardColor) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _flipCard,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
              return AnimatedBuilder(
                animation: rotateAnim,
                child: child,
                builder: (context, child) {
                  final isUnder = (ValueKey(_isFlipped) != child?.key);
                  var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
                  tilt *= isUnder ? -1.0 : 1.0;
                  final value = min(rotateAnim.value, pi / 2);
                  return Transform(
                    transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
              );
            },
            child: _isFlipped
                ? _buildCard(
                    cardColor, textColor, widget.flashcards[_currentIndex].back)
                : _buildCard(cardColor, textColor,
                    widget.flashcards[_currentIndex].front),
          ),
        ),
        const SizedBox(height: 24),
        Text("${_currentIndex + 1} / ${widget.flashcards.length}"),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back_ios), onPressed: _prevCard),
            const SizedBox(width: 48),
            IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _nextCard),
          ],
        ),
        if (widget.showStartGameButton) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onFinished,
            child: BionicText("Start Game", enabled: widget.useBionicReading),
          )
        ]
      ],
    );
  }

  Widget _buildCard(Color cardColor, Color textColor, String text) {
    return Card(
      key: ValueKey(_isFlipped),
      color: cardColor,
      elevation: 8,
      child: Container(
        width: 400,
        height: 250,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: BionicText(
          text,
          enabled: widget.useBionicReading,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: textColor),
        ),
      ),
    );
  }
}

enum CardType { question, answer }

class QAPair {
  final int id;
  final String question;
  final String answer;
  QAPair({required this.id, required this.question, required this.answer});

  factory QAPair.fromJson(Map<String, dynamic> json, int id) {
    return QAPair(
      id: id,
      question: json['question'],
      answer: json['answer'],
    );
  }
}

class FlashcardGameFlow extends StatelessWidget {
  final List<QAPair> qaPairs;
  final bool useBionicReading;
  final VoidCallback onGameCompleted;

  const FlashcardGameFlow(
      {super.key,
      required this.qaPairs,
      required this.useBionicReading,
      required this.onGameCompleted});

  @override
  Widget build(BuildContext context) {
    final flashcards = qaPairs
        .map((p) => Flashcard(front: p.question, back: p.answer))
        .toList();

    return FlashcardViewer(
      flashcards: flashcards,
      showStartGameButton: true,
      useBionicReading: useBionicReading,
      onFinished: () {
        showDialog(
            context: context,
            builder: (context) => Dialog(
                    child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: ConcentrationGameWidget(
                      qaPairs: qaPairs,
                      useBionicReading: useBionicReading,
                      onGameFinished: () {
                        Navigator.of(context).pop();
                        onGameCompleted();
                      }),
                )));
      },
    );
  }
}

class ConcentrationGameWidget extends StatefulWidget {
  final List<QAPair> qaPairs;
  final bool useBionicReading;
  final VoidCallback onGameFinished;
  const ConcentrationGameWidget(
      {super.key,
      required this.qaPairs,
      required this.useBionicReading,
      required this.onGameFinished});

  @override
  State<ConcentrationGameWidget> createState() =>
      _ConcentrationGameWidgetState();
}

class _ConcentrationGameWidgetState extends State<ConcentrationGameWidget> {
  late List<GameCard> _questionCards;
  late List<GameCard> _answerCards;
  final List<GameCard> _flippedCards = [];
  int _pairsFound = 0;

  @override
  void initState() {
    super.initState();
    _setupGame();
  }

  void _setupGame() {
    setState(() {
      _pairsFound = 0;
      _flippedCards.clear();
      List<GameCard> questions = [];
      List<GameCard> answers = [];
      for (var qaPair in widget.qaPairs) {
        questions.add(GameCard(
            id: qaPair.id, text: qaPair.question, type: CardType.question));
        answers.add(GameCard(
            id: qaPair.id, text: qaPair.answer, type: CardType.answer));
      }
      questions.shuffle();
      answers.shuffle();
      _questionCards = questions;
      _answerCards = answers;
    });
  }

  void _onCardTapped(GameCard card) {
    if (card.isMatched ||
        _flippedCards.length >= 2 ||
        _flippedCards.contains(card)) return;

    setState(() {
      card.isFlipped = true;
      _flippedCards.add(card);
    });

    if (_flippedCards.length == 2) {
      final firstCard = _flippedCards[0];
      final secondCard = _flippedCards[1];
      if (firstCard.id == secondCard.id && firstCard.type != secondCard.type) {
        setState(() {
          firstCard.isMatched = true;
          secondCard.isMatched = true;
          _pairsFound++;
          _flippedCards.clear();
        });

        if (_pairsFound == widget.qaPairs.length) _showGameEndDialog();
      } else {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() {
              firstCard.isFlipped = false;
              secondCard.isFlipped = false;
              _flippedCards.clear();
            });
          }
        });
      }
    }
  }

  void _showGameEndDialog() {
    showDialog(
      context: context,
      // Prevents closing the dialog by tapping outside
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: BionicText("Great Job!", enabled: widget.useBionicReading),
        content: BionicText("You found all the pairs. Play another round?",
            enabled: widget.useBionicReading),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close this alert
              widget.onGameFinished(); // Then close the game view
            },
            child: BionicText("No, Finish", enabled: widget.useBionicReading),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close this alert
              _setupGame(); // And reset the game board
            },
            child: BionicText("Play Again", enabled: widget.useBionicReading),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: BionicText("Questions",
              enabled: widget.useBionicReading,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: _questionCards.length,
            itemBuilder: (context, index) {
              final card = _questionCards[index];
              return _buildGameCard(card);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: BionicText("Answers",
              enabled: widget.useBionicReading,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: _answerCards.length,
            itemBuilder: (context, index) {
              final card = _answerCards[index];
              return _buildGameCard(card);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: widget.onGameFinished,
                child:
                    BionicText('Finish Game', enabled: widget.useBionicReading),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard(GameCard card) {
    return GestureDetector(
      onTap: () => _onCardTapped(card),
      child: AnimatedFlipCard(
        isFlipped: card.isFlipped,
        front: Card(
            color: card.type == CardType.question
                ? Colors.indigo.shade800
                : Colors.teal.shade800),
        back: Card(
            color: card.isMatched
                ? Colors.grey.shade800
                : (card.type == CardType.question
                    ? Colors.indigo.shade400
                    : Colors.teal.shade400),
            child: Center(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BionicText(card.text,
                  enabled: widget.useBionicReading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white)),
            ))),
      ),
    );
  }
}

class GameCard {
  final int id;
  final String text;
  final CardType type;
  bool isFlipped;
  bool isMatched;

  GameCard({
    required this.id,
    required this.text,
    required this.type,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class FallingLeaf {
  final UniqueKey id;
  Offset position;
  final Color color;
  final double speed;

  FallingLeaf({
    required this.id,
    required this.position,
    required this.color,
    required this.speed,
  });
}

class FidgetGameScreen extends StatefulWidget {
  const FidgetGameScreen({super.key});

  @override
  State<FidgetGameScreen> createState() => _FidgetGameScreenState();
}

class _FidgetGameScreenState extends State<FidgetGameScreen>
    with AutomaticKeepAliveClientMixin {
  final List<FallingLeaf> _leaves = [];
  double _basketPosition = 0;
  final double _basketWidth = 100.0;
  final double _basketHeight = 50.0;
  final double _basketSpeed = 30.0;
  int _score = 0;
  Timer? _gameTimer;
  final Random _random = Random();
  final FocusNode _focusNode = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _basketPosition =
            (MediaQuery.of(context).size.width - _basketWidth) / 2;
      });
      _startGame();
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _startGame() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_random.nextDouble() < 0.05 && _leaves.length < 20) {
        _spawnLeaf();
      }

      final List<FallingLeaf> caughtLeaves = [];
      final screenSize = MediaQuery.of(context).size;
      final basketRect = Rect.fromLTWH(_basketPosition,
          screenSize.height - _basketHeight - 100, _basketWidth, _basketHeight);

      setState(() {
        for (var leaf in _leaves) {
          leaf.position =
              Offset(leaf.position.dx, leaf.position.dy + leaf.speed);

          final leafRect =
              Rect.fromCenter(center: leaf.position, width: 24, height: 24);

          if (basketRect.overlaps(leafRect)) {
            caughtLeaves.add(leaf);
            _score++;
          }
        }

        _leaves.removeWhere((leaf) => caughtLeaves.contains(leaf));

        _leaves.removeWhere((leaf) => leaf.position.dy > screenSize.height);
      });
    });
  }

  void _spawnLeaf() {
    final screenSize = MediaQuery.of(context).size;
    final x = _random.nextDouble() * screenSize.width;
    final speed = _random.nextDouble() * 3 + 2;
    final color =
        Colors.green.shade300.withOpacity(_random.nextDouble() * 0.5 + 0.5);

    _leaves.add(FallingLeaf(
      id: UniqueKey(),
      position: Offset(x, -24),
      color: color,
      speed: speed,
    ));
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _basketPosition = max(0, _basketPosition - _basketSpeed);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _basketPosition = min(
              screenSize.width - _basketWidth, _basketPosition + _basketSpeed);
        }
      });
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(_focusNode),
        child: Scaffold(
          body: Stack(
            children: [
              ..._leaves.map((leaf) {
                return Positioned(
                  left: leaf.position.dx,
                  top: leaf.position.dy,
                  child: Icon(
                    Icons.energy_savings_leaf,
                    color: leaf.color,
                    size: 24,
                  ),
                );
              }).toList(),
              Positioned(
                left: _basketPosition,
                bottom: 100,
                child: Icon(
                  Icons.shopping_basket,
                  size: _basketWidth,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BionicText(
                    'Score: $_score',
                    enabled:
                        false, // Score probably doesn't need bionic reading
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedFlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool isFlipped;

  const AnimatedFlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.isFlipped,
  });

  @override
  State<AnimatedFlipCard> createState() => _AnimatedFlipCardState();
}

class _AnimatedFlipCardState extends State<AnimatedFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double angle = _animation.value * pi;
        final bool isFront = _animation.value < 0.5;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isFront
              ? widget.front
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: widget.back,
                ),
        );
      },
    );
  }
}

