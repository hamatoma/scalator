import 'package:scalator/src/page/application_data.dart';

class PageControllerCollector {
  final String pageName;
  final ApplicationData applicationData;
  PageControllerCollector(this.pageName, this.applicationData);

  void redraw(RedrawReason reason, {String? customString}) {
    //
  }
}
