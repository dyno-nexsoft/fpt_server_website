import 'package:flutter/material.dart';

/// Below this width the shell collapses its persistent nav/queue sidebars
/// into drawers — chosen to clear a phone in portrait, not just a tablet.
const kMobileBreakpoint = 700.0;

bool isMobileWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kMobileBreakpoint;
