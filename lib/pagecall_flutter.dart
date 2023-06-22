import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pagecall_flutter/platform_interface.dart';
import 'package:pagecall_flutter/src/android_pagecallview.dart';
import 'package:pagecall_flutter/src/cupertino_pagecallview.dart';

class PagecallView extends StatelessWidget {
  static const String viewType = 'com.pagecall/pagecall_flutter';

  late PagecallViewController _controller;

  final String? mode;

  final String? roomId;

  final String? accessToken;

  final void Function(PagecallViewController controller)? onViewCreated;

  final void Function(String message)? onMessageReceived;

  PagecallView({
    Key? key,
    this.mode,
    this.roomId,
    this.accessToken,
    this.onViewCreated,
    this.onMessageReceived,
  }) : super(key: key);

  static PlatformPagecallView? _platform;

  static set platform(PlatformPagecallView? platform) {
    _platform = platform;
  }

  static PlatformPagecallView? get platform {
    if (_platform == null) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          _platform = AndroidPagecallView();
          break;
        case TargetPlatform.iOS:
          _platform = CupertinoPagecallView();
          break;
        default:
          throw UnsupportedError(
            "UnsupportedError for platform=$defaultTargetPlatform",
          );
      }
    }
    return _platform;
  }

  @override
  Widget build(BuildContext context) {
    return platform!.build(
      context: context,
      creationParams: CreationParams(
        mode: mode,
        roomId: roomId,
        accessToken: accessToken,
      ),
      viewType: viewType,
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  @override
  void _onPlatformViewCreated(int id) {
    _controller = PagecallViewController(id, this);

    if (onViewCreated != null) {
      onViewCreated!(_controller);
    }
  }
}

class CreationParams {
  final String? mode; // TODO: String -> enum

  final String? roomId;

  final String? accessToken;

  CreationParams({
    this.mode,
    this.roomId,
    this.accessToken,
  });

  Map<String, dynamic> toMap() {
    return {
      "mode": mode,
      "roomId": roomId,
      "accessToken": accessToken,
    };
  }
}

class PagecallViewController {
  PagecallView? _pagecallView;
  late MethodChannel _channel;
  dynamic _id;

  PagecallViewController(dynamic id, PagecallView pagecallView) {
    _id = id;
    String channelName = "com.pagecall/pagecall_flutter\$$id";
    print("Flutter channelName=$channelName");
    _channel = MethodChannel(channelName);
    _channel.setMethodCallHandler(handleMethod);
    _pagecallView = pagecallView;
  }

  Future<dynamic> handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onMessageReceived':
        if (_pagecallView != null) {
          String message = call.arguments.toString();
          if (_pagecallView?.onMessageReceived != null) {
            _pagecallView?.onMessageReceived!(message);
          }
        }
        break;
      default:
        throw UnimplementedError('Unimplemented method=${call.method}');
    }

    return null;
  }

  Future<void> sendMessage(String message) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('message', () => message);
    await _channel.invokeMethod('sendMessage', args);
  }
}