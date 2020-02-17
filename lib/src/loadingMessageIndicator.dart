import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingMessageIndicator extends StatefulWidget {
  const LoadingMessageIndicator(
      {Key key, this.color, this.message, this.textStyle, this.spacing})
      : super(key: key);

  final Color color;
  final String message;
  final TextStyle textStyle;
  final double spacing;

  @override
  _LoadingMessageIndicatorState createState() =>
      _LoadingMessageIndicatorState();
}

class _LoadingMessageIndicatorState extends State<LoadingMessageIndicator>
    with SingleTickerProviderStateMixin {
  Animation<int> animation;
  AnimationController controller;

  int amountDots;

  @override
  void initState() {
    super.initState();
    amountDots = 0;
    controller =
        AnimationController(duration: const Duration(seconds: 3), vsync: this);
    animation = IntTween(begin: 0, end: 3).animate(controller)
      ..addListener(() {
        setState(() {
          amountDots = animation.value;
        });
      });
    controller.repeat();
  }

  String _renderDot({int amount = 0}) {
    String result = '';
    for (int i = 0; i < amount; i++) {
      result += '。';
    }
    return result;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Platform.isIOS
            ? CupertinoActivityIndicator()
            : CircularProgressIndicator(),
        SizedBox(
          height: widget.spacing ?? 10,
        ),
        Text(
          (widget.message ?? 'ロード中') + _renderDot(amount: amountDots),
          style: widget.textStyle ??
              textTheme.body1
                  .merge(TextStyle(color: widget.color ?? Colors.white)),
        )
      ],
    );
  }
}
