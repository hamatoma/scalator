import 'package:dart_bones/dart_bones.dart';
import 'package:flutter/material.dart';

import '../page/application_data.dart';
import '../page/page_configuration.dart';
import '../page/page_scalator.dart';

enum AppPage { configuration, conversion }

class CollectorDrawer extends Drawer {
  CollectorDrawer(context) : super(child: buildGrid(context));

  /// Returns a method creating a drawer.
  static CollectorDrawer builder(dynamic context) => CollectorDrawer(context);

  static Widget buildGrid(context) {
    final converter = MenuConverter();
    final list = MenuItem.menuItems(converter);
    final rc = Card(
        child: GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      children: list
          .map((item) => GridTile(
                child: InkResponse(
                  enableFeedback: true,
                  child: Card(
                    child: Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          SizedBox(width: 10.0, height: 40.0),
                          Icon(item.icon),
                          Text(item.title)
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    //CollectorSettings().pageData.pushCaller(null);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => item.page()));
                  },
                ),
              ))
          .toList(),
    ));
    return rc;
  }

  static Widget buildListView(context) {
    final converter = MenuConverter();
    final list = MenuItem.menuItems(converter);
    final rc = Card(
        child: ListView(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            children: list
                .map((item) => ListTile(
                      title: Text(item.title),
                      onTap: () {
                        // What happens after you tap the navigation item
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => item.page()));
                      },
                    ))
                .toList()));
    return rc;
  }
}

class MenuConverter {
  /// Returns the icon given by [name].
  IconData? iconByName(String name, BaseLogger logger) {
    IconData? rc;
    switch (name) {
      case 'build_circle_outlined':
        rc = Icons.build_circle_outlined;
        break;
      case 'wallpaper_outlined':
        rc = Icons.wallpaper_outlined;
        break;
      default:
        logger.error('MenuConverter.iconByName(): unknown icon $name');
        break;
    }
    return rc;
  }

  /// Returns the page given by [name].
  StatefulWidget? pageByName(AppPage page, ApplicationData applicationData) {
    StatefulWidget? rc;
    switch (page) {
      case AppPage.configuration:
        rc = PageConfiguration(applicationData);
        break;
      case AppPage.conversion:
        rc = PageScalator(applicationData);
        break;
      default:
        applicationData.logger
            .error('MenuConverter.pageByName(): unknown page $page');
        break;
    }
    return rc;
  }
}

class MenuItem {
  final String title;
  final dynamic page;
  final IconData icon;

  MenuItem(this.title, this.page, this.icon);

  static List<MenuItem> menuItems(MenuConverter converter) {
    final applicationData = ApplicationData();
    final logger = applicationData.logger;
    return <MenuItem>[
      MenuItem(
          'Konvertierung',
          () => converter.pageByName(AppPage.conversion, applicationData),
          converter.iconByName('wallpaper_outlined', logger)!),
      MenuItem(
          'Konfiguration',
          () => converter.pageByName(AppPage.configuration, applicationData),
          converter.iconByName('build_circle_outlined', logger)!),
    ];
  }
}
