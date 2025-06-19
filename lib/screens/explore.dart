
import 'package:campus_connect/widgets/custom_textfield.dart';
import 'package:campus_connect/widgets/widgetBuilder.dart';
import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  final TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Explore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CustomTextField(controller: controller, hintText: 'Search posts', icon: Icons.search),
            const SizedBox(height: 10),

          ],
        ),
      ),
      bottomNavigationBar: CustomWidgetBuilder.buildBottomNavBar(context, 1),
    );
  }
}

