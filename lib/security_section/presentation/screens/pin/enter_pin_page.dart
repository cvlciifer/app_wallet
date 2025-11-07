import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'enter_pin_content.dart';

class EnterPinPage extends ConsumerStatefulWidget {
  final bool verifyOnly;
  final String? accountId;

  const EnterPinPage({Key? key, this.verifyOnly = false, this.accountId})
      : super(key: key);

  @override
  ConsumerState<EnterPinPage> createState() => _EnterPinPageState();
}

class _EnterPinPageState extends ConsumerState<EnterPinPage> {
  @override
  Widget build(BuildContext context) {
    final uid = widget.accountId ?? AuthService().getCurrentUser()?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(child: AwText.normal('Usuario no identificado')),
      );
    }
    return EnterPinContent(accountId: uid);
  }
}
