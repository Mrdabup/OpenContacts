import 'package:cached_network_image/cached_network_image.dart';
import 'package:OpenContacts/auxiliary.dart';
import 'package:OpenContacts/clients/session_client.dart';
import 'package:OpenContacts/models/session.dart';
import 'package:OpenContacts/widgets/default_error_widget.dart';
import 'package:OpenContacts/widgets/formatted_text.dart';
import 'package:OpenContacts/widgets/sessions/session_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class SessionList extends StatefulWidget {
  const SessionList({super.key});

  @override
  State<SessionList> createState() => _SessionListState();
}
class onKeyIntent extends Intent{
  const onKeyIntent();
}

const onKey = SingleActivator(LogicalKeyboardKey.f5);

class _SessionListState extends State<SessionList> with AutomaticKeepAliveClientMixin {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sClient = Provider.of<SessionClient>(context, listen: false);
    if (sClient.sessionsFuture == null) {
      sClient.initSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider.value(
      value: Provider.of<SessionClient>(context),
      child: Consumer<SessionClient>(
        builder: (BuildContext context, SessionClient sClient, Widget? child) {
          return FutureBuilder<List<Session>>(
            future: sClient.sessionsFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      sClient.reloadSessions();
                      try {
                        await sClient.sessionsFuture;
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    child: data.isEmpty && snapshot.connectionState == ConnectionState.done
                        ? const DefaultErrorWidget(
                            title: "No Sessions Found",
                            message: "Try to adjust your filters",
                            iconOverride: Icons.question_mark,
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GridView.builder(
                              padding: const EdgeInsets.only(top: 10),
                              itemCount: data.length,
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 256,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 1,
                                childAspectRatio: .8,
                              ),
                              itemBuilder: (context, index) {
                                final session = data[index];
                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(builder: (context) => SessionView(session: session)));
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Hero(
                                              tag: session.id,
                                              child: CachedNetworkImage(
                                                imageUrl: Aux.resdbToHttp(session.thumbnailUrl),
                                                fit: BoxFit.cover,
                                                errorWidget: (context, url, error) => const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 64,
                                                  ),
                                                ),
                                                placeholder: (context, uri) =>
                                                    const Center(child: CircularProgressIndicator()),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: FormattedText(
                                                        session.formattedName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "Host: ${session.hostUsername}",
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                            color: Color.fromARGB(234, 151, 107, 61)
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "${(session.sessionUsers.length - (!session.headlessHost ?0 :1)).toString().padLeft(2, "0")}/${session.maxUsers.toString().padLeft(2, "0")} Online",
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(.5),
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting) const LinearProgressIndicator()
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
