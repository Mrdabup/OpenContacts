import 'package:flutter/material.dart';
import 'package:OpenContacts/auxiliary.dart';
import 'package:OpenContacts/models/session.dart';
import 'package:OpenContacts/widgets/formatted_text.dart';
import 'package:OpenContacts/widgets/generic_avatar.dart';
import 'package:OpenContacts/widgets/sessions/session_view.dart';

class SessionTile extends StatelessWidget {
  const SessionTile({required this.session, super.key});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => SessionView(session: session)));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GenericAvatar(imageUri: Aux.resdbToHttp(session.thumbnailUrl), placeholderIcon: Icons.no_photography),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormattedText(session.formattedName),
                Text(
                  "${session.sessionUsers.length.toString().padLeft(2, "0")}/${session.maxUsers.toString().padLeft(2, "0")} active users",
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(.6)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
