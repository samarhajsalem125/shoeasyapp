import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final Function()? onTap;
  final Widget child;
  const Button({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 22.0),
          decoration: BoxDecoration(
            color:  const Color.fromARGB(255, 144, 148, 201),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(11),
          child: child,
        ));
  }
}