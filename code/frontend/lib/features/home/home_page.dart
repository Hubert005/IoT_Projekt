import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../game/photo_capture_page.dart';
import '../recipes/recipes_page.dart';
import 'components/bottom_nav_item.dart';
import 'components/home_status_row.dart';
import 'components/next_action_card.dart';
import 'components/start_game_button.dart';
import 'components/top_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [Expanded(child: _buildBody()), _buildBottomNav()])),
    );
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 1:
        return const RecipesPage();
      default:
        return _buildHome();
    }
  }

  // ── Home Tab ────────────────────────────────────────────────────────────

  Widget _buildHome() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: const TopHeader(title: 'MixMaster Pro'),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: const HomeStatusRow()),
        const SizedBox(height: 16),
        const Expanded(child: NextActionCard()),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: StartGameButton(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PhotoCapturePage()),
                ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Nav ──────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BottomNavItem(
            icon: Icons.grid_view_rounded,
            label: 'HOME',
            isActive: _navIndex == 0,
            onTap: () => setState(() => _navIndex = 0),
          ),
          BottomNavItem(
            icon: Icons.menu_book_rounded,
            label: 'RECIPE',
            isActive: _navIndex == 1,
            onTap: () => setState(() => _navIndex = 1),
          ),
        ],
      ),
    );
  }
}
