import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'analytics_screen.dart';
import 'body_screen.dart';
import 'custom_screen.dart';
import 'ladder_screen.dart';
import 'profile_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _tabs = CupertinoTabController();

  @override
  void initState() {
    super.initState();
    _tabs.addListener(HapticFeedback.selectionClick);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pal = app.palette;
    final zeus = app.side == GodSide.zeus;

    return CupertinoTabScaffold(
      controller: _tabs,
      tabBar: CupertinoTabBar(
        backgroundColor: Olymp.bar,
        activeColor: pal.primary,
        inactiveColor: const Color(0xFF9B97A3),
        border: const Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 0.5)),
        items: [
          BottomNavigationBarItem(
              icon: Icon(zeus ? CupertinoIcons.bolt_fill : CupertinoIcons.flame_fill), label: 'Today'),
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_pencil), label: 'Mine'),
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_stack_3d_up_fill), label: 'Ladder'),
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.chart_bar_fill), label: 'Stats'),
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_crop_circle_fill), label: 'Profile'),
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.camera_viewfinder), label: 'Body'),
        ],
      ),
      tabBuilder: (context, i) => CupertinoTabView(
        builder: (_) => switch (i) {
          0 => TodayScreen(onOpenLadder: () => _tabs.index = 2),
          1 => const CustomScreen(),
          2 => const LadderScreen(),
          3 => const AnalyticsScreen(),
          4 => const ProfileScreen(),
          _ => const BodyScreen(),
        },
      ),
    );
  }
}
