import '../../domain/entities/sign_entry.dart';

/// Catálogo local de señas soportadas por el modelo.
/// Las descripciones son orientativas: ajústalas a la lengua de señas
/// que uses en tu dataset (LSM, LSE, LSC, etc.).
class DictionaryLocalDataSource {
  const DictionaryLocalDataSource();

  List<SignEntry> getAll() => const [
        SignEntry(
          label: 'hola',
          title: 'Hola',
          category: 'Saludos',
          description: 'Saludo básico para iniciar una conversación.',
          steps: ['Mano abierta a la altura de la frente', 'Mueve la mano hacia afuera'],
        ),
        SignEntry(
          label: 'gracias',
          title: 'Gracias',
          category: 'Cortesía',
          description: 'Expresa agradecimiento.',
          steps: ['Dedos juntos tocando el mentón', 'Lleva la mano hacia adelante'],
        ),
        SignEntry(
          label: 'por_favor',
          title: 'Por favor',
          category: 'Cortesía',
          description: 'Petición amable.',
          steps: ['Mano abierta sobre el pecho', 'Movimiento circular'],
        ),
        SignEntry(
          label: 'si',
          title: 'Sí',
          category: 'Respuestas',
          description: 'Afirmación.',
          steps: ['Puño cerrado', 'Movimiento de arriba hacia abajo'],
        ),
        SignEntry(
          label: 'no',
          title: 'No',
          category: 'Respuestas',
          description: 'Negación.',
          steps: ['Dedo índice levantado', 'Movimiento lateral'],
        ),
        SignEntry(
          label: 'ayuda',
          title: 'Ayuda',
          category: 'Emergencia',
          description: 'Solicitar ayuda.',
          steps: ['Puño con pulgar arriba sobre la palma contraria', 'Eleva ambas manos'],
        ),
        SignEntry(
          label: 'agua',
          title: 'Agua',
          category: 'Necesidades',
          description: 'Pedir agua.',
          steps: ['Letra "W" con la mano', 'Toca el mentón dos veces'],
        ),
        SignEntry(
          label: 'te_quiero',
          title: 'Te quiero',
          category: 'Emociones',
          description: 'Expresar cariño.',
          steps: ['Extiende pulgar, índice y meñique', 'Dirige la palma hacia la persona'],
        ),
      ];
}
