import 'dart:async';
import 'dart:ui' as ui;

import 'package:chewie/src/ads_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_iconic_flutter/open_iconic_flutter.dart';
import 'package:video_player/video_player.dart';

import '../chewie.dart';
import 'loadingMessageIndicator.dart';

class AdsControls extends StatefulWidget {
  const AdsControls({
    @required this.backgroundColor,
    @required this.iconColor,
    this.skipDuration,
    this.loadingMessage,
    this.loadingMessageDot,
  });

  final Color backgroundColor;
  final Color iconColor;
  final Duration skipDuration;
  final String loadingMessage;
  final String loadingMessageDot;

  @override
  State<StatefulWidget> createState() {
    return _AdsControlsState();
  }
}

class _AdsControlsState extends State<AdsControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  final marginSize = 5.0;
  Timer _expandCollapseTimer;
  Timer _initTimer;

  VideoPlayerController controller;
  ChewieController chewieController;

  @override
  Widget build(BuildContext context) {
    chewieController = ChewieController.of(context);

    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
              context,
              chewieController.videoPlayerController.value.errorDescription,
            )
          : Center(
              child: Icon(
                OpenIconicIcons.ban,
                color: Colors.white,
                size: 42,
              ),
            );
    }

    final backgroundColor = widget.backgroundColor;
    final iconColor = widget.iconColor;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait ? 30.0 : 47.0;
    final buttonPadding = orientation == Orientation.portrait ? 16.0 : 24.0;

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () {
          _cancelAndRestartTimer();
        },
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: <Widget>[
              _buildTopBar(
                  backgroundColor, iconColor, barHeight, buttonPadding),
              _buildHitArea(backgroundColor, iconColor),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Expanded _buildHitArea(Color backgroundColor, Color iconColor) {
    return Expanded(
      child: GestureDetector(
        onTap: _latestValue != null && _latestValue.isPlaying
            ? _cancelAndRestartTimer
            : () {
                _hideTimer?.cancel();

                if (mounted) {
                  setState(() {
                    _hideStuff = false;
                  });
                }
              },
        child: Center(child: _buildLoading(backgroundColor, iconColor)),
      ),
    );
  }

  Widget _buildLoading(Color backgroundColor, Color iconColor) {
    return _latestValue.isBuffering || _latestValue.duration == null
        ? AnimatedOpacity(
            opacity: _latestValue.isBuffering || _latestValue.duration == null
                ? 1.0
                : 0.0,
            duration: Duration(milliseconds: 300),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0),
                child: Container(
                  color: backgroundColor,
                  width: 120,
                  height: 120,
                  child: LoadingMessageIndicator(
                    color: iconColor,
                    message: widget.loadingMessage,
                    messageDot: widget.loadingMessageDot,
                  ),
                ),
              ),
            ),
          )
        : Container();
  }

  GestureDetector _buildExpandButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: buttonPadding,
                right: buttonPadding,
              ),
              color: backgroundColor,
              child: Center(
                child: Icon(
                  chewieController.isFullScreen
                      ? OpenIconicIcons.fullscreenExit
                      : OpenIconicIcons.fullscreenEnter,
                  color: iconColor,
                  size: 12.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              color: backgroundColor,
              child: Container(
                height: barHeight,
                padding: EdgeInsets.only(
                  left: buttonPadding,
                  right: buttonPadding,
                ),
                child: Icon(
                  (_latestValue != null && _latestValue.volume > 0)
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: iconColor,
                  size: 16.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return Container(
      height: barHeight + 10,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _buildProgressBar(),
          Container(
            margin: EdgeInsets.only(
              top: marginSize,
              right: marginSize,
              left: marginSize,
            ),
            child: Row(
              children: <Widget>[
                chewieController.allowFullScreen
                    ? _buildExpandButton(
                        backgroundColor, iconColor, barHeight, buttonPadding)
                    : Container(),
                Expanded(child: Container()),
                chewieController.allowMuting
                    ? _buildMuteButton(controller, backgroundColor, iconColor,
                        barHeight, buttonPadding)
                    : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();

    if (mounted) {
      setState(() {
        _hideStuff = false;

        _startHideTimer();
      });
    }
  }

  Future<Null> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        if (mounted)
          setState(() {
            _hideStuff = false;
          });
      });
    }
  }

  void _onExpandCollapse() {
    if (mounted)
      setState(() {
        _hideStuff = true;

        chewieController.toggleFullScreen();
        _expandCollapseTimer = Timer(Duration(milliseconds: 300), () {
          if (mounted)
            setState(() {
              _cancelAndRestartTimer();
            });
        });
      });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: AdsVideoProgressBar(
        controller,
        colors: chewieController.cupertinoProgressColors ??
            ChewieProgressColors(
              playedColor: Color.fromARGB(
                120,
                255,
                255,
                255,
              ),
              handleColor: Color.fromARGB(
                255,
                255,
                255,
                255,
              ),
              bufferedColor: Color.fromARGB(
                60,
                255,
                255,
                255,
              ),
              backgroundColor: Color.fromARGB(
                20,
                255,
                255,
                255,
              ),
            ),
      ),
    );
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted)
        setState(() {
          _hideStuff = true;
        });
    });
  }

  void _updateState() {
    if (mounted)
      setState(() {
        _latestValue = controller.value;
      });
  }
}
