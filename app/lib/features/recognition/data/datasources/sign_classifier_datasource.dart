import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../../core/constants/ml_constants.dart';

/// Fuente que ejecuta el modelo y devuelve las probabilidades softmax.
abstract interface class SignClassifierDataSource {
  List<String> get labels;
  Future<void> load();
  Future<List<double>> predict(List<List<double>> sequence);
  void dispose();
}

/// Implementación REAL: LSTM exportada a TFLite (`ml/src/export_tflite.py`).
/// La inferencia corre en un isolate aparte para no bloquear la UI.
class TfliteSignClassifierDataSource implements SignClassifierDataSource {
  Interpreter? _interpreter;
  IsolateInterpreter? _isolate;
  List<String> _labels = const [];

  @override
  List<String> get labels => _labels;

  @override
  Future<void> load() async {
    final raw = await rootBundle.loadString(MlConstants.labelsAsset);
    _labels = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    _interpreter = await Interpreter.fromAsset(
      MlConstants.modelAsset,
      options: InterpreterOptions()..threads = 2,
    );
    _isolate = await IsolateInterpreter.create(address: _interpreter!.address);

    final inShape = _interpreter!.getInputTensor(0).shape;
    if (inShape.length != 3 ||
        inShape[1] != MlConstants.sequenceLength ||
        inShape[2] != MlConstants.numFeatures) {
      throw StateError('Forma de entrada inesperada $inShape. '
          'Esperado [1, ${MlConstants.sequenceLength}, ${MlConstants.numFeatures}]');
    }
  }

  @override
  Future<List<double>> predict(List<List<double>> sequence) async {
    final isolate = _isolate;
    if (isolate == null) throw StateError('Modelo no cargado');

    final input = [sequence];
    final output = [List<double>.filled(_labels.length, 0)];
    await isolate.run(input, output);
    return output.first;
  }

  @override
  void dispose() {
    _isolate?.close();
    _interpreter?.close();
    _isolate = null;
    _interpreter = null;
  }
}

/// Se usa mientras no exista un modelo entrenado: no inventa resultados.
/// `load()` falla a propósito, así la UI sabe que solo hay detección de manos.
class NoModelSignClassifierDataSource implements SignClassifierDataSource {
  @override
  List<String> get labels => const [];

  @override
  Future<void> load() async =>
      throw StateError('Aún no hay modelo LSTM entrenado (ver ml/README.md)');

  @override
  Future<List<double>> predict(List<List<double>> sequence) async =>
      throw StateError('Sin modelo');

  @override
  void dispose() {}
}

/// Implementación SIMULADA (solo para ver la UI): rota entre señas cada ~2.5 s
/// sin mirar la mano. NO reconoce nada.
class MockSignClassifierDataSource implements SignClassifierDataSource {
  static const _mockLabels = [
    'hola', 'gracias', 'por_favor', 'si', 'no', 'ayuda', 'agua', 'te_quiero',
  ];
  final _random = math.Random();
  final _clock = Stopwatch()..start();

  @override
  List<String> get labels => _mockLabels;

  @override
  Future<void> load() => Future.delayed(const Duration(milliseconds: 600));

  @override
  Future<List<double>> predict(List<List<double>> sequence) async {
    final idx = (_clock.elapsedMilliseconds ~/ 2500) % _mockLabels.length;
    final top = 0.82 + _random.nextDouble() * 0.16;
    final rest = (1 - top) / (_mockLabels.length - 1);
    return [for (var i = 0; i < _mockLabels.length; i++) i == idx ? top : rest];
  }

  @override
  void dispose() {}
}
