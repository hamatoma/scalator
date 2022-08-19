import 'dart:io';

import 'package:dart_bones/dart_bones.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:scalator/src/helper/os_info.dart';
import 'package:sprintf/sprintf.dart';

import '../helper/file_supplier_async.dart';
import '../helper/helper.dart';
import '../helper/validators.dart' as validators;
import 'application_data.dart';

class PageScalator extends StatefulWidget {
  final ApplicationData applicationData;
  PageScalator(this.applicationData, {Key? key}) : super(key: key);

  @override
  PageScalatorState createState() {
    final rc = PageScalatorState(applicationData);
    return rc;
  }
}

class PageScalatorState extends State<PageScalator> {
  static RegExp regExpJPeg = RegExp(r'\.jpe?g$', caseSensitive: false);

  final ApplicationData applicationData;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'collection');
  final sourceDirectoryController = TextEditingController();
  final targetDirectoryController = TextEditingController();
  final portraitController = TextEditingController();
  final landscapeController = TextEditingController();
  final squareController = TextEditingController();

  PageScalatorState(this.applicationData);

  @override
  Widget build(BuildContext context) {
    final padding = 16.0;
    final buttonWidth = 150.0;
    final comboWidth = 300.0;
    final applicationData = ApplicationData();
    sourceDirectoryController.text = applicationData.sourceDirectory.path ?? '';
    targetDirectoryController.text = applicationData.targetDirectory.path ?? '';
    portraitController.text =
        '${applicationData.portrait.maxWidth}x${applicationData.portrait.maxHeight}';
    landscapeController.text =
        '${applicationData.landscape.maxWidth}x${applicationData.landscape.maxHeight}';
    squareController.text = '${applicationData.square.maxWidth}';
    final fileList = applicationData.listLines
        .map((e) => Text(e, style: TextStyle(color: Colors.blue)))
        .toList();
    final colWidth = 125.0;
    final scrollController = ScrollController();
    applicationData.readHistories();
    final sources = applicationData.historySources
        .asList()
        .map((e) => DropdownMenuItem(child: Text(e), value: e))
        .toList();
    sources.insert(0, DropdownMenuItem(child: Text('Wähle'), value: ''));
    final targets = applicationData.historyTargets
        .asList()
        .map((e) => DropdownMenuItem(child: Text(e), value: e))
        .toList();
    targets.insert(0, DropdownMenuItem(child: Text('Wähle'), value: ''));
    final ranges = applicationData.historyRanges
        .asList()
        .map((e) => DropdownMenuItem(child: Text(e), value: e))
        .toList();
    ranges.insert(0, DropdownMenuItem(child: Text('Wähle'), value: ''));
    final rc = Scaffold(
        appBar: applicationData.appBarBuilder('Bilder skalieren'),
        drawer: applicationData.drawerBuilder(context),
        body: Form(
          key: _formKey,
          child: Card(
              margin:
                  EdgeInsets.symmetric(vertical: padding, horizontal: padding),
              child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: padding, horizontal: padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              validator: validators.checkDirectory,
                              decoration: InputDecoration(
                                  labelText: 'Quellverzeichnis'),
                              onSaved: (input) =>
                                  applicationData.sourceDirectory.path = input!,
                              controller: sourceDirectoryController,
                            ),
                          ),
                          Container(
                              width: buttonWidth,
                              padding: EdgeInsets.only(
                                  left: padding, right: padding),
                              child: ElevatedButton(
                                onPressed: () => selectDirectory(
                                    context,
                                    sourceDirectoryController.text,
                                    applicationData.sourceDirectory),
                                child: Text('Auswahl'),
                              )),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(applicationData.historySources.label),
                                  Row(children: [
                                    Expanded(
                                      child: DropdownButton<String>(
                                        value: '',
                                        items: sources,
                                        onChanged: (value) {
                                          if (value != null) {
                                            sourceDirectoryController.text =
                                                value;
                                            applicationData
                                                .sourceDirectory.path = value;
                                          }
                                        },
                                      ),
                                    ),
                                  ]),
                                ]),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: Row(children: [
                            Expanded(
                              child: TextFormField(
                                validator: validators.checkDirectory,
                                decoration: InputDecoration(
                                    labelText: 'Zielverzeichnis'),
                                onSaved: (input) => applicationData
                                    .targetDirectory.path = input!,
                                controller: targetDirectoryController,
                              ),
                            ),
                            Container(
                              width: buttonWidth,
                              padding: EdgeInsets.only(left: padding),
                              child: ElevatedButton(
                                onPressed: () => createDir(),
                                child: Text('Erzeugen'),
                              ),
                            ),
                          ])),
                          Container(
                            width: buttonWidth,
                            padding:
                                EdgeInsets.only(left: padding, right: padding),
                            child: ElevatedButton(
                              onPressed: () => selectDirectory(
                                  context,
                                  targetDirectoryController.text,
                                  applicationData.targetDirectory),
                              child: Text('Auswahl'),
                            ),
                          ),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(applicationData.historyTargets.label),
                                  Row(children: [
                                    Expanded(
                                      child: DropdownButton<String>(
                                        value: '',
                                        items: targets,
                                        onChanged: (value) {
                                          if (value != null) {
                                            targetDirectoryController.text =
                                                value;
                                            applicationData
                                                .targetDirectory.path = value;
                                          }
                                        },
                                      ),
                                    ),
                                  ])
                                ]),
                          ),
                        ],
                      ),
                      SizedBox(height: padding),
                      Text("Die folgenden Angaben sind immer <Breite>x<Höhe>"),
                      Row(children: <Widget>[
                        Container(
                            width: colWidth,
                            child: TextFormField(
                              validator: (input) =>
                                  validate(input!, validators.checkDimensions),
                              decoration:
                                  InputDecoration(labelText: 'Hochformat:'),
                              onSaved: (input) => applicationData.portrait =
                                  ImageDimensions.fromString(input!),
                              controller: portraitController,
                            )),
                        Container(
                            width: colWidth,
                            child: TextFormField(
                              validator: (input) =>
                                  validate(input, validators.checkDimensions),
                              decoration:
                                  InputDecoration(labelText: 'Querformat:'),
                              onSaved: (input) => applicationData.landscape =
                                  ImageDimensions.fromString(input!),
                              controller: landscapeController,
                            )),
                        Container(
                          width: colWidth,
                          child: TextFormField(
                            validator: (input) =>
                                validate(input, validators.checkNat),
                            decoration:
                                InputDecoration(labelText: 'Quadratformat:'),
                            onSaved: (input) => applicationData.square =
                                ImageDimensions.fromString('$input x $input'),
                            controller: squareController,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: padding),
                          width: comboWidth,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(applicationData.historyRanges.label),
                                DropdownButton<String>(
                                  value: '',
                                  items: ranges,
                                  onChanged: (value) {
                                    if (value != null) {
                                      portraitController.text = value;
                                      landscapeController.text = value;
                                      squareController.text =
                                          value.split('x')[1];
                                    }
                                  },
                                ),
                              ]),
                        ),
                      ]),
                      SizedBox(height: padding),
                      Row(children: [
                        Container(
                            width: colWidth,
                            child: TextFormField(
                              validator: (input) => validate(
                                  input,
                                  (input) => RegExp(r'^\w+(,\w+)*$')
                                              .firstMatch(input!) ==
                                          null
                                      ? 'Keine mit Kommas getrennte Liste von Dateiendungen: $input Korrektes Beispiel: jpg,png'
                                      : null),
                              initialValue: 'jpg,png',
                              decoration:
                                  InputDecoration(labelText: 'Dateiendungen'),
                              // ignore: prefer_interpolation_to_compose_strings
                              onSaved: (input) => applicationData.extensions =
                                  '(${input!.replaceAll(',', '|')})\$',
                            )),
                        Container(
                            width: colWidth,
                            child: TextFormField(
                              validator: (input) => validate(
                                  input,
                                  (input) => validators.checkIntWithCondition(
                                      input,
                                      (number) => number < 10 || number > 100
                                          ? 'Unzulässige Qualität: muss zwischen 10 und 100 liegen'
                                          : null)),
                              initialValue: applicationData.quality.toString(),
                              decoration:
                                  InputDecoration(labelText: 'Qualität (%)'),
                              onSaved: (input) =>
                                  applicationData.quality = int.parse(input!),
                            )),
                        Container(
                            width: colWidth,
                            child: Row(children: [
                              Checkbox(
                                value: applicationData.recursive,
                                onChanged: (state) => setState(() =>
                                    applicationData.recursive =
                                        !applicationData.recursive),
                              ),
                              Text("rekursiv"),
                            ])),
                      ]),
                      SizedBox(
                        height: padding,
                      ),
                      Container(
                          width: colWidth,
                          child: ElevatedButton(
                            onPressed: () => run(context),
                            child: Text(applicationData.isRunning
                                ? 'Halt'
                                : 'Los gehts'),
                          )),
                      SizedBox(
                        height: padding,
                      ),
                      TextField(
                        style: TextStyle(
                          color: applicationData.messageController.text
                                  .startsWith('+++ ')
                              ? Colors.red
                              : Colors.blue,
                        ),
                        controller: applicationData.messageController,
                        readOnly: true,
                      ),
                      SizedBox(
                        height: padding,
                      ),
                      Text('Protokoll'),
                      SizedBox(
                        height: padding,
                      ),
                      Expanded(
                          child: Container(
                              child: ListView(
                        controller: scrollController,
                        children: fileList,
                      )))
                    ],
                  ))),
        ));
    return rc;
  }

  void createDir() {
    final path = targetDirectoryController.text;
    applicationData.targetDirectory.path = path;
    if (path.isNotEmpty) {
      final directory = Directory(path);
      if (directory.existsSync()) {
        log('existiert schon: $path');
      } else {
        directory.createSync(recursive: true);
        if (directory.existsSync()) {
          log('erzeugt: $path');
        }
      }
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    sourceDirectoryController.dispose();
    targetDirectoryController.dispose();
    super.dispose();
  }

  /// Logs a [message] to the logger and to the screen.
  void log(String message) {
    applicationData.logger.log(message);
    applicationData.messageController.text = message;
    redraw();
  }

  void redraw() {
    setState(() => 1);
  }

  void run(context) async {
    if (applicationData.isRunning) {
      applicationData.isRunning = false;
      applicationData.currentSupplier!.stopRequired = true;
      setState(() => 1);
    } else if (_formKey.currentState!.validate()) {
      applicationData.historyRanges.addEntry(portraitController.text);
      applicationData.historyRanges.addEntry(landscapeController.text);
      applicationData.historySources.addEntry(sourceDirectoryController.text);
      applicationData.historyTargets.addEntry(targetDirectoryController.text);
      applicationData.storeHistories();
      _formKey.currentState!.save();
      applicationData.isRunning = true;
      final supplier = FileSupplierAsync(
          filePatterns: [applicationData.sourceDirectory.path!],
          fileOptions: FileOptions(
              processBinaries: true,
              recursive: applicationData.recursive,
              yieldDirectory: false,
              yieldLinkToDirectory: false,
              blockedDirectory: applicationData.targetDirectory.path,
              included:
                  RegExp(applicationData.extensions!, caseSensitive: false)),
          verboseLevel: 4);
      applicationData.currentSupplier = supplier;
      applicationData.clear();
      Stream<String?> files = supplier.next();
      files.listen((filename) async {
        // no more files:
        if (filename == null) {
          applicationData.isRunning = false;
        } else {
          if (await FileSystemEntity.isDirectory(filename)) {
            applicationData.logger.error('directory found: $filename');
          } else {
            final entry = File(filename);
            try {
              await scaleOne(entry, supplier.relPath());
            } on Exception catch (exc) {
              applicationData.logger.error(exc.toString());
            }
          }
        }
        log(status(supplier));
      });
    }
  }

  Future scaleOne(File source, String relPath) async {
    // Read an image from file.
    // decodeImage will identify the format of the image and use the appropriate
    // decoder.
    img.Image? image = img.decodeImage(await source.readAsBytes());
    FileSync fileSync = FileSync(globalLogger);
    img.Image? newImage;
    ImageDimensions? dimensions;
    int width, height;
    if (image == null) {
      applicationData.logger.error('unbekanntes Format in ${source.path}');
    } else {
      if ((width = image.width) == (height = image.height)) {
        dimensions = applicationData.square;
      } else if (width < height) {
        dimensions = applicationData.portrait;
      } else {
        dimensions = applicationData.landscape;
      }
      if (width > dimensions.maxWidth) {
        newImage = img.copyResize(image, width: dimensions.maxWidth);
      } else if (height > dimensions.maxHeight) {
        newImage = img.copyResize(image, height: dimensions.maxHeight);
      }
      final target = path.join(applicationData.targetDirectory.path!, relPath,
          path.basename(source.path));
      fileSync.ensureDirectory(path.dirname(target));
      if (newImage == null) {
        source.copy(target);
        applicationData.copiedFiles++;
        applicationData.toList('${source.path} ${width}x$height');
      } else {
        File file = File(target);
        if (regExpJPeg.firstMatch(target) != null) {
          await file.writeAsBytes(
              img.encodeJpg(newImage, quality: applicationData.quality));
        } else {
          await file.writeAsBytes(img.encodePng(newImage));
        }
        final size = await file.length();
        final sourceSize = humanSize(await source.length());
        final targetSize = humanSize(await file.length());
        applicationData.convertedBytes += size;
        applicationData.processedFiles++;
        applicationData.processedBytes += await source.length();

        applicationData.toList(
            '${source.path} ${width}x$height $sourceSize -> $targetSize');
      }
    }
  }

  /// Selects a directory with an dialog.
  /// [preferredDirectory]: the start directory (if not empty)
  /// [dirInfo]: if [preferredDirectory] this directory defines the start directory.
  /// The selection was stored into [dirInfo].
  void selectDirectory(
      context, String preferredDirectory, DirInfo dirInfo) async {
    final start = preferredDirectory.isNotEmpty
        ? preferredDirectory
        : dirInfo.path ?? OsInfo().homeDirectory;
    final ignoreDot =
        start.length <= 1 || !path.basename(start).startsWith('.');
    dirInfo.path = await FilesystemPicker.open(
      context: context,
      title: '${dirInfo.label} auswählen',
      rootDirectory: Directory(OsInfo().root()),
      rootName: '',
      directory: Directory(start),
      fsType: FilesystemType.folder,
      itemFilter: (FileSystemEntity fsEntity, String path, String name) =>
          !ignoreDot || !name.startsWith('.'),
      pickText: 'Den aktuellen Ordner auswählen',
      //folderIconColor: Colors.teal,
    );
    if (dirInfo.path != null && dirInfo.path!.startsWith('//')) {
      dirInfo.path = dirInfo.path!.substring(1);
    }
    redraw();
  }

  String status(supplier) {
    final rc = applicationData.processedFiles == 0
        ? 'Keine Dateien bearbeitet.'
        : sprintf(
            'Bearbeitet: %d Datei(en) (mit %s) in %d Verzeichnis(sen) Konvertiert: %s (%.0f%%) Nur kopiert: %d Datei(en)',
            [
                applicationData.processedFiles,
                humanSize(applicationData.processedBytes),
                supplier.processedDirs,
                humanSize(applicationData.convertedBytes),
                applicationData.processedBytes == 0.0
                    ? 0.0
                    : applicationData.convertedBytes *
                        100.0 /
                        applicationData.processedBytes,
                applicationData.copiedFiles
              ]);
    return rc;
  }

  /// Writes the error message of a [validator] into the log line.
  /// [input] is the text to test with [validator].
  /// Returns the result of [validator].
  String? validate(String? input, String? Function(String?) validator) {
    final rc = validator(input);
    if (rc != null) {
      log('+++ $rc');
    }
    return rc;
  }
}
