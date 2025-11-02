
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:test_project/widgets/bottom_navigation_items.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


class MainScreen extends HookConsumerWidget {
  
  final StatefulNavigationShell navigationShell;

  const MainScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final selectedIndex = useState(navigationShell.currentIndex);
    useEffect(() {
      selectedIndex.value = navigationShell.currentIndex;
      return null;
    }, [navigationShell]);

    return Builder(
      builder: (context) {

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: selectedIndex.value,
            onTap: (int index) async {
              if (selectedIndex.value == index) {
                navigationShell.goBranch(index, initialLocation: true);
              } else {
                navigationShell.goBranch(index);
                selectedIndex.value = index;
              }
            },
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            items: [
              BottomNavigationItems.home(),
              BottomNavigationItems.favorites(),
            ],
          ),
        );


      }
    );

  }

}