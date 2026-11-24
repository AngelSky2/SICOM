"""Prueba el modelo entrenado en tiempo real con la webcam (en el PC).

Uso:
    python src/realtime_test.py
"""
from collections import deque

import cv2
import numpy as np
import tensorflow as tf

from config import ACTIONS, KERAS_MODEL_PATH, SEQUENCE_LENGTH
from keypoints import create_hands_detector, extract_keypoints, draw_landmarks

THRESHOLD = 0.8


def main():
    model = tf.keras.models.load_model(KERAS_MODEL_PATH)
    window = deque(maxlen=SEQUENCE_LENGTH)
    sentence = []
    cap = cv2.VideoCapture(0)

    with create_hands_detector() as hands:
        while cap.isOpened():
            ok, frame = cap.read()
            if not ok:
                break
            frame = cv2.flip(frame, 1)
            results = hands.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            draw_landmarks(frame, results)
            window.append(extract_keypoints(results))

            if len(window) == SEQUENCE_LENGTH:
                probs = model.predict(np.expand_dims(np.array(window), 0), verbose=0)[0]
                idx = int(np.argmax(probs))
                if probs[idx] > THRESHOLD and (not sentence or sentence[-1] != ACTIONS[idx]):
                    sentence.append(ACTIONS[idx])
                    sentence = sentence[-5:]
                cv2.putText(frame, f"{ACTIONS[idx]} {probs[idx]:.2f}", (10, 70),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

            cv2.rectangle(frame, (0, 0), (frame.shape[1], 40), (40, 40, 40), -1)
            cv2.putText(frame, " ".join(sentence), (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
            cv2.imshow("Prueba en tiempo real", frame)
            if cv2.waitKey(1) & 0xFF == ord("q"):
                break

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
