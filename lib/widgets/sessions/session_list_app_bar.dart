import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:OpenContacts/clients/session_client.dart';
import 'package:OpenContacts/widgets/sessions/session_filter_dialog.dart';

class SessionListAppBar extends StatefulWidget {
  const SessionListAppBar({super.key});

  @override
  State<SessionListAppBar> createState() => _SessionListAppBarState();
}

class _SessionListAppBarState extends State<SessionListAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Sessions"),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: IconButton(
            onPressed: () async {
              final sessionClient = Provider.of<SessionClient>(context, listen: false);
              await showDialog(
                context: context,
                builder: (context) => ChangeNotifierProvider.value(
                  value: sessionClient,
                  child: SessionFilterDialog(
                    lastFilter: sessionClient.filterSettings,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        )
      ],
    );
  }
}
