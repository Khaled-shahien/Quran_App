import 'package:flutter/material.dart';

class HadeathCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const HadeathCard({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.menu_book,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
