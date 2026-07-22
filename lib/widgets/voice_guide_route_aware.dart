import 'package:flutter/material.dart';

import '../navigation/voice_guide_route_observer.dart';
import '../services/voice_guide_service.dart';

/// Mixin for pushed screens that participate in the Voice Guide.
///
/// Call [initVoiceGuide] from `didChangeDependencies` and
/// [disposeVoiceGuide] from `dispose`.
mixin VoiceGuideRouteAware<T extends StatefulWidget> on State<T>
    implements RouteAware {
  VoiceGuideScreen get voiceGuideScreen;
  bool get voiceGuideAutoPlay => true;

  bool _voiceGuideSubscribed = false;
  bool _voiceGuideEntered = false;

  void initVoiceGuide() {
    final route = ModalRoute.of(context);
    if (!_voiceGuideSubscribed && route is PageRoute) {
      voiceGuideRouteObserver.subscribe(this, route);
      _voiceGuideSubscribed = true;
    }
    if (!_voiceGuideEntered) {
      _voiceGuideEntered = true;
      VoiceGuideService.instance.enterScreen(
        voiceGuideScreen,
        autoPlay: voiceGuideAutoPlay,
        owner: this,
      );
    }
  }

  void disposeVoiceGuide() {
    if (_voiceGuideSubscribed) {
      voiceGuideRouteObserver.unsubscribe(this);
      _voiceGuideSubscribed = false;
    }
    VoiceGuideService.instance.leaveScreen(
      voiceGuideScreen,
      owner: this,
    );
  }

  @override
  void didPopNext() {
    VoiceGuideService.instance.enterScreen(
      voiceGuideScreen,
      autoPlay: voiceGuideAutoPlay,
      owner: this,
    );
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}
}
