import 'package:app_wallet/Library/main_library.dart';

class AwLoader extends StatelessWidget {
  const AwLoader ({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AwColors.blue,
      ),
    );
  }
}
