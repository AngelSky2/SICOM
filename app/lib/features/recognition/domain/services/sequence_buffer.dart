import 'dart:collection';

/// Ventana deslizante de tamaño fijo con los últimos N vectores de features.
class SequenceBuffer {
  SequenceBuffer(this.capacity);

  final int capacity;
  final Queue<List<double>> _frames = Queue();

  bool get isFull => _frames.length >= capacity;
  double get fill => _frames.length / capacity;

  void add(List<double> features) {
    _frames.addLast(features);
    while (_frames.length > capacity) {
      _frames.removeFirst();
    }
  }

  List<List<double>> snapshot() => List.unmodifiable(_frames);

  void clear() => _frames.clear();
}
