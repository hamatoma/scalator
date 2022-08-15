import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';

import 'helper.dart';

/// This exception should be used to jump out of in nested function calls
/// to finish the execution.
class ExitException {
  final String reason;

  ExitException(this.reason);
}

/// A data class for options to control a [FileSupplierAsync] object.
class FileOptions {
  bool recursive = false;
  RegExp? excluded;
  RegExp? excludedDirs;
  RegExp? included;
  bool processBinaries = false;
  bool yieldFile = true;
  bool yieldDirectory = true;
  bool yieldLinkToFile = true;
  bool yieldLinkToDirectory = true;
  String? blockedDirectory;

  FileOptions({
    this.recursive = false,
    this.excluded,
    this.excludedDirs,
    this.processBinaries = false,
    this.yieldFile = true,
    this.yieldDirectory = true,
    this.yieldLinkToFile = true,
    this.yieldLinkToDirectory = true,
    this.included,
    this.blockedDirectory,
  });

  FileOptions.fromArgument(ArgResults results) {
    recursive =
        results.options.contains('recursive') ? results['recursive'] : false;
    excluded = results['excluded'] == null ? null : RegExp(results['excluded']);
    excluded = results['included'] == null ? null : RegExp(results['excluded']);
    excludedDirs = results['excluded-dirs'] == null
        ? null
        : RegExp(results['excluded-dirs']);
    processBinaries = results.options.contains('process-binaries')
        ? results['process-binaries']
        : true;
    if (results.options.contains('file-type') && results['file-type'] != null) {
      yieldFile =
          yieldDirectory = yieldLinkToFile = yieldLinkToDirectory = false;
      for (var item in results['file-type'].split(',')) {
        if (item.startsWith('f')) {
          yieldFile = true;
        } else if (item.startWith('d')) {
          yieldDirectory = true;
        } else if (item == 'l' || item == 'link') {
          yieldLinkToFile = yieldLinkToDirectory = true;
        } else if (item == 'ld' ||
            item.startsWith('link)') && item.contains('dir')) {
          yieldLinkToDirectory = true;
        } else if (item == 'lf' ||
            item.contains('link') && item.contains('file')) {
          yieldLinkToFile = true;
        }
      }
    }
  }
}

/// Implements a generator delivering filenames from one or more file trees.
class FileSupplierAsync {
  final FileOptions? fileOptions;
  final int verboseLevel;
  int processedFiles = 0;
  int processedBytes = 0;
  int processedDirs = 0;
  int processedLinksDirectory = 0;
  int processedLinksFile = 0;
  int ignoredFiles = 0;
  int ignoredBytes = 0;
  int ignoredDirs = 0;
  int countBinaries = 0;
  FileSystemEntity? currentEntity;
  final List<String>? filePatterns;
  final summary = <String>[];
  int startPathLength = 0;
  bool stopRequired = false;

  FileSupplierAsync(
      {this.filePatterns, this.fileOptions, this.verboseLevel = 1});

  void clear() {
    processedFiles = 0;
    processedBytes = 0;
    processedDirs = 0;
    processedLinksDirectory = 0;
    processedLinksFile = 0;
    ignoredFiles = 0;
    ignoredBytes = 0;
    ignoredDirs = 0;
    countBinaries = 0;
  }

  /// Returns the full name of the next file specified by the options.
  /// The last yield is null to inform the caller about the end.
  Stream<String?> next() async* {
    clear();
    stopRequired = false;
    String? exitMessage;
    final paths = <String>[];
    final regExpList = <RegExp?>[];
    final isFile = <bool>[];
    if (fileOptions!.blockedDirectory != null) {
      fileOptions!.blockedDirectory =
          Directory(fileOptions!.blockedDirectory!).absolute.path;
    }
    for (var item in filePatterns ?? ['.*']) {
      if (stopRequired) {
        break;
      }
      if (await FileSystemEntity.isDirectory(item)) {
        paths.add(item);
        regExpList.add(null);
        isFile.add(false);
      } else {
        if (!fileOptions!.recursive && await FileSystemEntity.isFile(item)) {
          isFile.add(true);
          paths.add(item);
          regExpList.add(null);
        } else {
          isFile.add(false);
          final directory = dirname(item);
          final filePattern = basename(item);
          paths.add(directory.isEmpty ? '.' : directory);
          regExpList.add(RegExp(shellPatternToRegExp(filePattern)));
        }
      }
    }
    try {
      for (var ix = 0; ix < paths.length; ix++) {
        if (stopRequired) {
          break;
        }
        startPathLength = paths[ix].length;
        if (!isFile[ix]) {
          yield* searchFilePattern(regExpList[ix], paths[ix], 0);
        } else {
          if (fileOptions!.yieldFile) {
            processedFiles++;
            processedBytes += await (currentEntity as File).length();
            yield paths[ix];
          }
        }
      }
      yield null;
    } on ExitException catch (exc) {
      exitMessage = '= search stopped: ${exc.reason}';
    }
    if (verboseLevel >= 1) {
      var bytes = humanSize(processedBytes);
      summary.add(
          '= processed directories: $processedDirs processed files: $processedFiles ($bytes)');
      bytes = humanSize(processedBytes);
      summary.add(
          '= ignored directories: $ignoredDirs ignored files: $ignoredFiles ($bytes) binary files: $countBinaries');
      summary.add(
          '= directory links (ignored): $processedLinksDirectory file links: $processedLinksFile');
      if (exitMessage != null) {
        summary.add(exitMessage);
      }
    }
  }

  /// Searches the files matching the [filePattern] in a [directory].
  /// This method is recursive on subdirectories.
  Stream<String> searchFilePattern(
      RegExp? filePattern, String directory, int depth) async* {
    if (verboseLevel >= 2 && depth <= 1 || verboseLevel >= 3) {
      print('= processing $directory ...');
    }
    final subDirectories = <String>[];
    try {
      final currentDir = Directory(directory);
      if (fileOptions!.blockedDirectory == null ||
          currentDir.absolute.path != fileOptions!.blockedDirectory) {
        processedDirs++;
        for (currentEntity in currentDir.listSync()) {
          if (stopRequired) {
            break;
          }
          final name = currentEntity!.path;
          final node = basename(name);
          if (await FileSystemEntity.isDirectory(name)) {
            if (await FileSystemEntity.isLink(name)) {
              processedLinksDirectory++;
              if (fileOptions!.yieldLinkToDirectory) {
                yield name;
              }
              continue;
            }
            if (fileOptions!.excludedDirs != null &&
                fileOptions!.excludedDirs!.firstMatch(node) != null) {
              if (verboseLevel >= 4) {
                print('= ignoring not matching directory $name');
              }
              ignoredDirs++;
            } else {
              if (fileOptions!.yieldDirectory) {
                yield name;
              }
              subDirectories.add(name);
            }
            continue;
          }
          if (filePattern != null && filePattern.firstMatch(node) == null) {
            ignoredFiles++;
            ignoredBytes += await (currentEntity as File).length();

            if (verboseLevel >= 4) {
              print('= ignoring not matching $name');
            }
            continue;
          }
          if (fileOptions!.excluded != null &&
                  fileOptions!.excluded!.firstMatch(node) != null ||
              fileOptions!.included != null &&
                  fileOptions!.included!.firstMatch(node) == null) {
            ignoredFiles++;
            if (currentEntity is File) {
              ignoredBytes += await (currentEntity as File).length();
            }
            if (verboseLevel >= 4) {
              print('= ignoring excluded $name');
            }
            continue;
          }
          if (!fileOptions!.processBinaries && isBinary(name)) {
            if (verboseLevel >= 4) {
              print('= ignoring binary $name');
            }
            countBinaries++;
            continue;
          }
          processedFiles++;
          processedBytes += await (currentEntity as File).length();
          if (await FileSystemEntity.isLink(name)) {
            processedLinksFile++;
            if (fileOptions!.yieldLinkToFile) {
              yield name;
            }
            continue;
          }
          if (fileOptions!.yieldFile) {
            yield name;
          }
        }
      }
    } on FileSystemException catch (exc) {
      processedDirs--;
      ignoredDirs++;
      if (verboseLevel >= 4) {
        print('= ignored: $exc');
      }
    }
    if (!stopRequired && fileOptions!.recursive) {
      for (var subDir in subDirectories) {
        if (stopRequired) {
          break;
        }
        yield* searchFilePattern(filePattern, subDir, depth + 1);
      }
    }
  }

  String relPath() {
    final path = currentEntity!.parent.path;
    final rc = path.length <= startPathLength
        ? ''
        : path.substring(startPathLength + 1);
    return rc;
  }
}
