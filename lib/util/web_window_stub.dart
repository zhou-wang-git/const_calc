// Stub for non-web platforms to satisfy conditional imports.
class _StubLocation {
  String href = '';
}

class _StubWindow {
  final _StubLocation location = _StubLocation();
}

final _StubWindow window = _StubWindow();
