import 'package:flutter/material.dart';

class BuildMenu extends StatelessWidget {
  const BuildMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 25.0, horizontal: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar( // TODO : IMPLEMENT PICTURE UPLOAD
                  backgroundColor: Theme.of(context).colorScheme.background,
                  radius: 22.0,
                  child: const Icon(Icons.my_library_books_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    "Hello, Dear Diary!",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          listTile(
              context, "home", Icons.sunny, "sept jours",
              Theme.of(context).textTheme.labelSmall
          ),
          listTile(
              context, "overview", Icons.panorama, "landscape",
              Theme.of(context).textTheme.labelSmall
          ),
          listTile(
              context, "about", Icons.star, "environ",
              Theme.of(context).textTheme.labelSmall
          ),
        ],
      ),
    );
  }

  Widget listTile(BuildContext context, String route, IconData icon, String text, TextStyle? style) {
    return ListTile(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      leading: Icon(icon, size: 25.0, color: Colors.white),
      title: Text(text, style: style),
      textColor: Colors.white,
      dense: true,
    );
  }
}
