import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavigationItems {

  static BottomNavigationBarItem home() {

    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        'assets/bottom_bar_icons/home_unactive.svg',
        height: 24,
        width: 24,
        fit: BoxFit.fill,
      ),
      activeIcon: SvgPicture.asset(
        'assets/bottom_bar_icons/home_active.svg',
        height: 24,
        width: 24,
        fit: BoxFit.fill,
        colorFilter: const ColorFilter.mode(Color(0xFF4AA461), BlendMode.srcIn),
      ),
      label: 'Персонажи',
    );
  }

  static BottomNavigationBarItem favorites() {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        'assets/bottom_bar_icons/favs_unactive.svg',
        height: 24,
        width: 24,
        fit: BoxFit.fill,
      ),
      activeIcon: SvgPicture.asset(
        'assets/bottom_bar_icons/favs_unactive.svg',
        height: 24,
        width: 24,
        fit: BoxFit.fill,
        colorFilter: const ColorFilter.mode(Color(0xFF4AA461), BlendMode.srcIn),
      ),
      label: 'Избранное',
    );
  }


}
