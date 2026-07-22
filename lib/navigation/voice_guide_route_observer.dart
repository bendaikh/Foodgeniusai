import 'package:flutter/material.dart';

/// Navigator observer used by [MainShellPage] to resume Voice Guide after pop.
final RouteObserver<ModalRoute<void>> voiceGuideRouteObserver =
    RouteObserver<ModalRoute<void>>();
