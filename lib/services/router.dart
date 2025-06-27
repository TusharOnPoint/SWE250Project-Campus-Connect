import 'package:campus_connect/screens/add_conversation.dart';
import 'package:campus_connect/screens/checking.dart';
import 'package:campus_connect/screens/login.dart';
import 'package:campus_connect/screens/post_detail_screen.dart';
import 'package:campus_connect/screens/signup.dart';
import 'package:campus_connect/screens/user_info_form.dart';
import 'package:campus_connect/screens/user_profile_page.dart';
import 'package:campus_connect/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

import '../screens/home.dart';
import '../screens/messages.dart';
import '../screens/profile.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('Navigating to: ${settings.name}');
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => WelcomeScreen());

      case '/check':
        return MaterialPageRoute(builder: (_) => RootScreen());

      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());

      case '/signup':
        return MaterialPageRoute(builder: (_) => SignUpScreen());

      case '/home':
        return MaterialPageRoute(builder: (_) => HomeScreen());

      case '/profile':
        return MaterialPageRoute(
          builder: (context) => ProfileScreen(),
        );

      case '/messages':
        return MaterialPageRoute(builder: (_) => MessagesScreen());

      case '/addConversation':
        return MaterialPageRoute(builder: (_) => AddConversationScreen());

      case '/userInfoForm':
        return MaterialPageRoute(builder: (_) => UserInfoForm());

      // case '/messageDetail':
      //   final args = settings.arguments as Map<String, dynamic>;
      //   return MaterialPageRoute(
      //     builder: (_) => MessageDetailScreen(messageId: args['messageId']),
      //   );

      // case '/posts':
      //   return MaterialPageRoute(builder: (_) => PostsScreen());
      //
      case '/postDetail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (_) => PostDetailScreen(
                postDoc: args['postDoc'],
                currentUserId: args['currentUserId'],
              ),
        );
      //
      // case '/people':
      //   return MaterialPageRoute(builder: (_) => PeopleScreen());
      //
      // case '/personDetail':
      //   final args = settings.arguments as Map<String, dynamic>;
      //   return MaterialPageRoute(
      //     builder: (_) => PersonDetailScreen(personId: args['personId']),
      //   );
      //
      // case '/pages':
      //   return MaterialPageRoute(builder: (_) => PagesScreen());
      //
      // case '/pageDetail':
      //   final args = settings.arguments as Map<String, dynamic>;
      //   return MaterialPageRoute(
      //     builder: (_) => PageDetailScreen(pageId: args['pageId']),
      //   );

      default:
        return MaterialPageRoute(builder: (_) => HomeScreen());
    }
  }
}
