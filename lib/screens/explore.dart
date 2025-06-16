
import 'package:campus_connect/widgets/widgetBuilder.dart';
import 'package:flutter/material.dart';

import 'home.dart';

class ExploreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Explore'),
      ),
      body: Center(
        child: Text('Explore content goes here.'),
      ),
      bottomNavigationBar: CustomWidgetBuilder.buildBottomNavBar(context, 1),
    );
  }
}

