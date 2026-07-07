import 'package:flutter/material.dart';

import 'community_chat_screen.dart';
import 'community_topics_screen.dart';
import 'create_community_topic_screen.dart';

class CommunityTabNavigator extends StatelessWidget {
	const CommunityTabNavigator({super.key});

	@override
	Widget build(BuildContext context) {
		return Navigator(
			onGenerateRoute: (settings) {
				switch (settings.name) {
					case CreateCommunityTopicScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => const CreateCommunityTopicScreen(),
						);
					case CommunityChatScreen.routeName:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => CommunityChatScreen(
								topicId: settings.arguments! as String,
							),
						);
					default:
						return MaterialPageRoute(
							settings: settings,
							builder: (context) => const CommunityTopicsScreen(),
						);
				}
			},
		);
	}
}
