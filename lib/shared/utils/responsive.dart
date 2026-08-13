import 'package:flutter/material.dart';

/// Below this width the shell collapses its persistent nav/queue sidebars
/// into drawers — chosen to clear a phone in portrait, not just a tablet.
const kMobileBreakpoint = 700.0;

bool isMobileWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kMobileBreakpoint;

/// Below this width, alongside the shell's sidebar, there isn't enough room
/// left for the builds table's fixed-width columns — Params ends up
/// squeezed to a sliver and headers wrap letter-by-letter. A tablet is wider
/// than [kMobileBreakpoint] but still narrower than this, so the per-job
/// card list (built for phones) reads better there than a squeezed table.
const kTabletBreakpoint = 1024.0;

bool isTabletWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kTabletBreakpoint;
