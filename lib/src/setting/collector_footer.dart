import 'package:scalator/src/page/application_data.dart';
import 'package:flutter/material.dart';
import '../page/page_controller_collector.dart';
import 'package:url_launcher/url_launcher.dart';

class CollectorFooter implements FooterInterface {
  final Uri _url = Uri.parse('https://public.hamatoma.de');
  @override
  Widget widget(PageControllerCollector controller) {
    final rc = ButtonBar(alignment: MainAxisAlignment.spaceBetween, children: [
      InkWell(
        child: Text('Impressum'),
        onTap: () => _launchUrl,
      ),
      // SizedBox(
      //   width: 100,
      // ),
      InkWell(
        child: Text('Datenschutz'),
        onTap: () => _launchUrl,
      ),
      // SizedBox(
      //   width: 150,
      // ),
      Text('Version ${ApplicationData.applicationVersion}'),
    ]);
    // final rc2 = [
    //   GridView.count(crossAxisCount: 3, children: [
    //     Text('a'),
    //     Text('b'),
    //     Text('c'),
    //   ])
    // ];
    return rc;
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  /// Returns a method creating a footer.
  static CollectorFooter builder() => CollectorFooter();
}
