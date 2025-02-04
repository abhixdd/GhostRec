import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(GhostRecApp());
}

class GhostRecApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GhostRec',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DefaultTabController(
            length: 2,
            child: GhostRecHome(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: FooterWidget(),
          ),
        ],
      ),
    );
  }
}

class GhostRecHome extends StatefulWidget {
  @override
  _GhostRecHomeState createState() => _GhostRecHomeState();
}

class _GhostRecHomeState extends State<GhostRecHome> {
  static const platform = MethodChannel('com.example.Ghostrec/recorder');

  String _statusMessage = 'Idle';
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startRecording() async {
    String result;
    try {
      result = await platform.invokeMethod('startRecording');
      setState(() {
        _isRecording = true;
      });
    } on PlatformException catch (e) {
      result = "Error starting recording: '${e.message}'.";
    }
    setState(() {
      _statusMessage = result;
    });
  }

  Future<void> _stopRecording() async {
    String result;
    try {
      result = await platform.invokeMethod('stopRecording');
      setState(() {
        _isRecording = false;
      });
      if (result.contains("File saved to: ")) {}
    } on PlatformException catch (e) {
      result = "Error stopping recording: '${e.message}'.";
    }
    setState(() {
      _statusMessage = result;
    });

    setState(() {});
  }

  Future<void> _playRecording(String filePath) async {
    String result;
    try {
      result =
          await platform.invokeMethod('playRecording', {'filePath': filePath});
    } on PlatformException catch (e) {
      result = "Error playing recording: '${e.message}'.";
    }
    setState(() {
      _statusMessage = result;
    });
  }

  Future<List<FileSystemEntity>> _getRecordings() async {
    final Directory? baseDir = await getExternalStorageDirectory();
    if (baseDir == null) return [];
    final Directory recordingsDir =
        Directory('${baseDir.path}/GhostRecRecordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
      return [];
    }
    return recordingsDir.list().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🕸️ GhostRec'),
        backgroundColor: Colors.black87,
        actions: [
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(Icons.fiber_manual_record, color: Colors.redAccent),
            ),
        ],
        bottom: TabBar(
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(icon: Icon(Icons.fiber_manual_record), text: "Record"),
            Tab(icon: Icon(Icons.library_music), text: "Recordings"),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          RecordTab(
            startRecording: _startRecording,
            stopRecording: _stopRecording,
            statusMessage: _statusMessage,
          ),
          RecordingsListTab(
            getRecordings: _getRecordings,
            playRecording: _playRecording,
          ),
        ],
      ),
    );
  }
}

class RecordTab extends StatefulWidget {
  final Future<void> Function() startRecording;
  final Future<void> Function() stopRecording;
  final String statusMessage;

  const RecordTab({
    Key? key,
    required this.startRecording,
    required this.stopRecording,
    required this.statusMessage,
  }) : super(key: key);

  @override
  _RecordTabState createState() => _RecordTabState();
}

class _RecordTabState extends State<RecordTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Widget _glassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: _glassContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Status:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(widget.statusMessage),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.mic),
              label: const Text('Start Recording'),
              onPressed: widget.startRecording,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.stop),
              label: const Text('Stop Recording'),
              onPressed: widget.stopRecording,
            ),
          ],
        ),
      ),
    );
  }
}

class RecordingsListTab extends StatefulWidget {
  final Future<List<FileSystemEntity>> Function() getRecordings;
  final Future<void> Function(String filePath) playRecording;

  const RecordingsListTab({
    Key? key,
    required this.getRecordings,
    required this.playRecording,
  }) : super(key: key);

  @override
  _RecordingsListTabState createState() => _RecordingsListTabState();
}

class _RecordingsListTabState extends State<RecordingsListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<FileSystemEntity>>(
      future: widget.getRecordings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No recordings found.'));
        }
        final recordings = snapshot.data!;
        recordings.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        return ListView.builder(
          itemCount: recordings.length,
          itemBuilder: (context, index) {
            final file = recordings[index];
            final fileName = file.path.split('/').last;
            final modified = file.statSync().modified;
            return ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.white70),
              title: Text(fileName),
              subtitle: Text('Modified: ${modified.toLocal()}'),
              onTap: () => widget.playRecording(file.path),
            );
          },
        );
      },
    );
  }
}

class FooterWidget extends StatelessWidget {
  const FooterWidget({Key? key}) : super(key: key);

  Future<void> _launchURL() async {
    const url = 'https://abhix.me/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: InkWell(
          onTap: _launchURL,
          child: Text(
            'Created by ABHI',
            style: TextStyle(
              color: const Color.fromARGB(255, 217, 221, 225),
            ),
          ),
        ),
      ),
    );
  }
}
