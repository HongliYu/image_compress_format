import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MaterialApp(
    home: ConvertPage(),
  ));
}

class ConvertPage extends StatefulWidget {
  const ConvertPage({super.key});

  @override
  ConvertPageState createState() => ConvertPageState();
}

class ConvertPageState extends State<ConvertPage> {
  String _selectedDirectory = "";
  String _quality = "50"; // Default compression quality
  // String _output = 'Running shell script...';
  String _selectedFormat = 'JPEG';
  final List<String> _outputLines = [];

  Future<void> selectDirectory() async {
    String? directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null) {
      setState(() {
        _selectedDirectory = directory;
      });
    }
  }

  Future<void> startConversion() async {
    if (_selectedDirectory.isEmpty || _quality.isEmpty) {
      setState(() {
        _outputLines.clear();
        _outputLines.add('❌ Please select a directory and enter quality!');
      });
      return;
    }

    // Call shell script execution function
    await runShellScript(_selectedDirectory, _quality);
  }

  Future<void> runShellScript(String directory, String quality) async {
    setState(() {
      _outputLines.clear(); // Clear previous output
    });
    String bundlePath = Directory(Platform.resolvedExecutable)
        .parent
        .path
        .replaceAll('/MacOS', '');
    final scriptPath = "$bundlePath/Resources/convert_and_compress.sh";
    debugPrint("📜 Running script at: $scriptPath");

    Process process = await Process.start(
      'bash',
      [scriptPath, directory, quality, _selectedFormat.toLowerCase()],
    );

    // Listen to standard output (stdout)
    process.stdout.transform(const SystemEncoding().decoder).listen((line) {
      setState(() {
        _outputLines.add(line); // Add new line to UI
      });
    });

    // Listen to errors (stderr)
    process.stderr.transform(const SystemEncoding().decoder).listen((line) {
      setState(() {
        _outputLines.add("Error: $line");
      });
    });

    int exitCode = await process.exitCode;
    setState(() {
      _outputLines
          .add(exitCode == 0 ? "✅ Conversion Complete!" : "❌ Error occurred!");
    });
  }

  //   ProcessResult result = await Process.run('bash', [
  //     scriptPath,
  //     directory,
  //     quality,
  //     _selectedFormat.toLowerCase(),
  //   ]);
  //   setState(() {
  //     _output = result.exitCode == 0
  //         ? result.stdout
  //         : 'Error: ${result.stderr}, stdout: ${result.stdout}, exitCode: ${result.exitCode}';
  //   });

  //   debugPrint(result.stdout);
  //   if (result.stderr.isNotEmpty) {
  //     debugPrint("❌ Error: ${result.stderr}");
  //   } else {
  //     debugPrint("✅ Script executed successfully!");
  //   }
  // } catch (e) {
  //   debugPrint("❌ Exception: $e");
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HEIC format Converter")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("HEIC to "),
                DropdownButton<String>(
                  value: _selectedFormat,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFormat = newValue!;
                    });
                  },
                  items: <String>['JPEG', 'PNG']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: selectDirectory,
              child: const Text("📂 Select Source Directory"),
            ),
            const SizedBox(height: 10),
            Text(
                "Selected: ${_selectedDirectory.isNotEmpty ? _selectedDirectory : 'None'}"),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                  labelText: "Compression Quality (1-100, defualt is 50)"),
              keyboardType: TextInputType.number,
              onChanged: (value) => _quality = value,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startConversion,
              child: const Text("🚀 Convert & Compress"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.black,
                child: ListView.builder(
                  itemCount: _outputLines.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _outputLines[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
