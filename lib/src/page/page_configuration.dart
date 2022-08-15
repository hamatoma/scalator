import 'package:flutter/material.dart';
import '../helper/validators.dart' as validators;
import 'application_data.dart';

class PageConfiguration extends StatefulWidget {
  final ApplicationData applicationData;

  PageConfiguration(this.applicationData, {Key? key}) : super(key: key);

  @override
  PageConfigurationState createState() {
    final rc = PageConfigurationState(applicationData);
    return rc;
  }
}

class PageConfigurationState extends State<PageConfiguration> {
  final ApplicationData applicationData;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'configuration');

  PageConfigurationState(this.applicationData);

  @override
  Widget build(BuildContext context) {
    final padding = 16.0;
    final applicationData = ApplicationData();
    final colWidth = 250.0;
    final rc = Scaffold(
        appBar: applicationData.appBarBuilder('Konfiguration'),
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
                      TextFormField(
                        initialValue: applicationData.maxListLines.toString(),
                        validator: validators.checkNat,
                        decoration: InputDecoration(
                            labelText: 'Maximale Zeilenzahl in "Meldungen"'),
                        onSaved: (input) => applicationData.maxListLines =
                            int.parse(input ?? '100'),
                      ),
                      SizedBox(height: padding),
                      Container(
                          width: colWidth,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                              }
                            },
                            child: Text('Speichern'),
                          )),
                    ],
                  ))),
        ));
    return rc;
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    super.dispose();
  }

  void redraw() {
    setState(() => 1);
  }
}
