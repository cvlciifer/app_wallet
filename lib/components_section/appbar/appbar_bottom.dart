import 'package:app_wallet/library_section/main_library.dart';

class WalletBottomAppBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const WalletBottomAppBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color.fromARGB(255, 253, 250, 250),
      shadowColor: Colors.black.withOpacity(0.5),
      elevation: 8.0,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 70.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomAppBarItem(
              icon: Icons.home,
              label: 'Home',
              index: 0,
            ),
            _buildBottomAppBarItem(
              icon: Icons.bar_chart,
              label: 'Estadísticas',
              index: 1,
            ),
            const SizedBox(width: 48),
            _buildBottomAppBarItem(
              icon: Icons.assessment,
              label: 'Informes',
              index: 2,
            ),
            _buildBottomAppBarItem(
              icon: Icons.wallet,
              label: 'MiWallet',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAppBarItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AwColors.appBarColor : AwColors.modalGrey,
              size: AwSize.s22,
            ),
            const SizedBox(height: 2.0),
            AwText.bold(
              label,
              size: AwSize.s10,
              color: isSelected ? AwColors.appBarColor : AwColors.modalGrey,
            ),
          ],
        ),
      ),
    );
  }
}
