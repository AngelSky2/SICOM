"""Extracción y normalización de keypoints con MediaPipe Hands.

La normalización está espejada 1:1 en Dart
(lib/features/recognition/data/processing/keypoint_normalizer.dart).
Ver docs/FEATURE_SPEC.md.
"""
import numpy as np
import mediapipe as mp

from config import LANDMARKS_PER_HAND, COORDS_PER_LANDMARK, NUM_FEATURES

mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils

HAND_SIZE = LANDMARKS_PER_HAND * COORDS_PER_LANDMARK  # 63


def create_hands_detector():
    return mp_hands.Hands(
        static_image_mode=False,
        max_num_hands=2,
        model_complexity=1,
        min_detection_confidence=0.6,
        min_tracking_confidence=0.5,
    )


def normalize_hand(landmarks: np.ndarray) -> np.ndarray:
    """landmarks: (21, 3) -> vector (63,) invariante a posición y escala.

    1. Se resta la muñeca (landmark 0) -> invariante a traslación.
    2. Se divide por el máximo valor absoluto de x/y -> invariante a escala.
    """
    rel = landmarks - landmarks[0]
    scale = np.max(np.abs(rel[:, :2]))
    if scale > 1e-6:
        rel = rel / scale
    return rel.flatten().astype(np.float32)


def extract_keypoints(results) -> np.ndarray:
    """Convierte la salida de MediaPipe en un vector de NUM_FEATURES.

    Orden: [mano izquierda (63) | mano derecha (63)]. Mano ausente -> ceros.
    """
    left = np.zeros(HAND_SIZE, dtype=np.float32)
    right = np.zeros(HAND_SIZE, dtype=np.float32)

    if results.multi_hand_landmarks and results.multi_handedness:
        for hand_lms, handedness in zip(results.multi_hand_landmarks, results.multi_handedness):
            label = handedness.classification[0].label  # "Left" | "Right"
            pts = np.array([[lm.x, lm.y, lm.z] for lm in hand_lms.landmark], dtype=np.float32)
            vec = normalize_hand(pts)
            if label == "Left":
                left = vec
            else:
                right = vec

    out = np.concatenate([left, right])
    assert out.shape[0] == NUM_FEATURES
    return out


def draw_landmarks(image, results):
    if results.multi_hand_landmarks:
        for hand_lms in results.multi_hand_landmarks:
            mp_drawing.draw_landmarks(image, hand_lms, mp_hands.HAND_CONNECTIONS)
