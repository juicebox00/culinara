import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/models/recipe.dart';
import 'package:culinara/widgets/recipe_card.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/services/recently_viewed_service.dart';
import 'package:culinara/services/ui_sound_service.dart';

class RecentlyViewedPage extends StatefulWidget {
  const RecentlyViewedPage({
    super.key,
    required this.recipes,
    required this.onRecipeTap,
  });

  final List<Recipe> recipes;
  final ValueChanged<Recipe> onRecipeTap;

  @override
  State<RecentlyViewedPage> createState() => _RecentlyViewedPageState();
}

class _RecentlyViewedPageState extends State<RecentlyViewedPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _recentlyViewedWithDates = [];
  bool _isLoading = true;

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecentlyViewedRecipes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload when returning to this page
      _loadRecentlyViewedRecipes();
    }
  }

  Future<void> _loadRecentlyViewedRecipes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final recentlyViewedWithDates = await RecentlyViewedService.getRecentlyViewedRecipesWithDates(widget.recipes);
      setState(() {
        _recentlyViewedWithDates = recentlyViewedWithDates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading recently viewed recipes: $e');
    }
  }

  Future<void> _clearRecentlyViewed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF8EFE3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Clear History',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: Text(
          'Are you sure you want to clear your recently viewed recipes history?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const StrokedButtonLabel('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const StrokedButtonLabel(
              'Clear',
              fillColor: Color(0xFF9C2D2D),
              strokeColor: Color(0xFFF5E6D3),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RecentlyViewedService.clearRecentlyViewed();
      await _loadRecentlyViewedRecipes();
      UiSoundService.instance.playButtonBeep();
    }
  }

  void _onRecipeCardTap(Recipe recipe) {
    RecentlyViewedService.addToRecentlyViewed(recipe.id);
    widget.onRecipeTap(recipe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5D4A3A),
              ),
            )
          : _recentlyViewedWithDates.isEmpty
              ? _buildEmptyState()
              : _buildRecipeList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: const Color(0xFF8B6F47),
          ),
          const SizedBox(height: 16),
          Text(
            'No recently viewed recipes',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring recipes to see them here',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: const Color(0xFF8B6F47),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    return RefreshIndicator(
      onRefresh: _loadRecentlyViewedRecipes,
      color: const Color(0xFF5D4A3A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentlyViewedWithDates.length,
        itemBuilder: (context, index) {
          final entry = _recentlyViewedWithDates[index];
          final Recipe recipe = entry['recipe'];
          final String? viewedAt = entry['viewedAt'];
          DateTime? viewedDate;
          if (viewedAt != null) {
            try {
              viewedDate = DateTime.parse(viewedAt);
            } catch (_) {}
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: recipe.imagePath.isNotEmpty
                  ? Image.asset(recipe.imagePath, width: 56, height: 56, fit: BoxFit.cover)
                  : Icon(Icons.restaurant_menu, size: 40, color: Color(0xFF8B6F47)),
              title: Text(recipe.title, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              subtitle: viewedDate != null
                  ? Text('Viewed: ' + _formatDate(viewedDate), style: GoogleFonts.fredoka(fontSize: 13))
                  : null,
              onTap: () => _onRecipeCardTap(recipe),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white.withOpacity(0.85),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Example: Mar 17, 2026 5:16 PM
    return '${_monthShort(date.month)} ${date.day}, ${date.year} ${_formatTime(date)}';
  }

  String _monthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }
}
