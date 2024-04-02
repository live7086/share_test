import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translator/flutter_translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageGenerator(),
    );
  }
}

class ImageGenerator extends StatefulWidget {
  @override
  _ImageGeneratorState createState() => _ImageGeneratorState();
}

class _ImageGeneratorState extends State<ImageGenerator> {
  final TextEditingController _textController = TextEditingController();
  late ui.Image _image;

  Future<void> _generateImage() async {
    final text = _textController.text;
    final translation = await _translateText(text);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final painter = TextPainter(textDirection: TextDirection.ltr);

    // 繪製原始文字
    painter.text = TextSpan(
      text: text,
      style: TextStyle(fontSize: 24, color: Colors.black),
    );
    painter.layout();
    painter.paint(canvas, Offset(20, 20));

    // 繪製翻譯結果
    painter.text = TextSpan(
      text: translation,
      style: GoogleFonts.dancingScript(fontSize: 20, color: Colors.grey),
    );
    painter.layout();
    painter.paint(canvas, Offset(20, 60));

    final picture = recorder.endRecording();
    final image = await picture.toImage(500, 200);
    setState(() {
      _image = image;
    });
  }

  Future<String> _translateText(String text) async {
    final translator = FlutterTranslator(from: 'zh-CN', to: 'en');
    final translation = await translator.translate(text);
    return translation.text;
  }

  Future<void> _saveImage() async {
    if (_image != null) {
      final bytes = await _image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = bytes.buffer;
      await ImageGallerySaver.saveImage(buffer.asUint8List());
    }
  }

  Future<void> _shareToInstagram() async {
    if (_image != null) {
      final bytes = await _image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = bytes.buffer;
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/image.png')
          .writeAsBytes(buffer.asUint8List());
      final url =
          'https://www.instagram.com/share?image=${Uri.encodeComponent(file.path)}';
      if (await canLaunch(url)) {
        await launch(url);
      }
    }
  }

  Future<void> _shareToLINE() async {
    if (_image != null) {
      final bytes = await _image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = bytes.buffer;
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/image.png')
          .writeAsBytes(buffer.asUint8List());
      final url =
          'https://social-plugins.line.me/lineit/share?url=${Uri.encodeComponent(file.path)}';
      if (await canLaunch(url)) {
        await launch(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Generator')),
      body: Column(
        children: [
          TextField(controller: _textController),
          ElevatedButton(
            onPressed: _generateImage,
            child: Text('轉換'),
          ),
          if (_image != null)
            Image.memory(
              Uint8List.view(_image.buffer),
              fit: BoxFit.contain,
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _saveImage,
                child: Text('儲存圖片'),
              ),
              ElevatedButton(
                onPressed: _shareToInstagram,
                child: Text('分享到 Instagram'),
              ),
              ElevatedButton(
                onPressed: _shareToLINE,
                child: Text('分享到 LINE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
