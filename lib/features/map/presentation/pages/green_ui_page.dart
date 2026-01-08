import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

class GreenUIPage extends ConsumerStatefulWidget {
  const GreenUIPage({super.key});

  @override
  ConsumerState<GreenUIPage> createState() => _GreenUIPageState();
}

class _GreenUIPageState extends ConsumerState<GreenUIPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentScreen = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark purple background
      body: SafeArea(
        child: PageView(
          onPageChanged: (index) {
            setState(() {
              _currentScreen = index;
            });
          },
          children: [
            _buildHomeScreen(),
            _buildTrashcanDetailsScreen(),
            _buildSelectionScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHomeScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 30),
            _buildExploreSection(),
            const SizedBox(height: 20),
            _buildTrashcanGrid(),
            const Spacer(),
            _buildAllDestinationsButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.menu,
            color: Colors.white,
            size: 24,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.location_on,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: AppTheme.primaryGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Discover trashcan locations',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.star,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Explore',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '5',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrashcanGrid() {
    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildTrashcanCard('Downtown Area', Icons.location_on, true),
          _buildTrashcanCard('Park District', Icons.location_on, false),
          _buildTrashcanCard('Shopping Mall', Icons.location_on, false),
          _buildTrashcanCard('University', Icons.location_on, false),
        ],
      ),
    );
  }

  Widget _buildTrashcanCard(String title, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : AppTheme.primaryGreen,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllDestinationsButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'All trashcan locations',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.arrow_forward,
          color: Colors.white,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildTrashcanDetailsScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildToggleButtons(),
            const SizedBox(height: 30),
            _buildTrashcanDetailsCard(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      children: [
        _buildToggleButton('Status', true, AppTheme.primaryGreen),
        const SizedBox(width: 12),
        _buildToggleButton('Status + Tasks', false, Colors.white),
        const SizedBox(width: 12),
        _buildToggleButton('S', false, Colors.white),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTrashcanDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'SMART TRASHCAN STATUS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatusRow('Downtown', 'University', '25 SEPTEMBER 2024'),
          const SizedBox(height: 16),
          _buildStatusRow('Downtown', 'University', '25 SEPTEMBER 2024'),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String from, String to, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            from,
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 2,
                  color: Colors.grey[300],
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.delete_outline,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 2,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            to,
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            date,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '85%',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            const Text(
              'Select Trashcan Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the appropriate status for your trashcan monitoring',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            _buildProgressIndicator(),
            const SizedBox(height: 30),
            _buildSelectionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        const Icon(
          Icons.delete_outline,
          color: AppTheme.primaryGreen,
          size: 24,
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.check,
            color: AppTheme.primaryGreen,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildStatusGrid(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildSummaryCard(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildCheckoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusGrid() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: List.generate(20, (index) {
        bool isSelected = index >= 16 && index <= 19; // Last row selected
        return Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.circle,
              color: Colors.white,
              size: 12,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DOWNT\nUNIV',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '25 SEP',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 2,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 8),
          const Icon(
            Icons.delete_outline,
            color: AppTheme.primaryGreen,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'CONFIRM STATUS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.arrow_forward,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.delete_outline, 'Status', 1),
          _buildNavItem(Icons.settings, 'Settings', 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentScreen == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentScreen = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryGreen : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryGreen : Colors.grey[400],
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

