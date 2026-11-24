"""Recolección de dataset con la webcam.

Uso:
    python src/collect_data.py                 # todas las señas de config.ACTIONS
    python src/collect_data.py --action hola   # solo una seña

Guarda: data/<accion>/<n_secuencia>.npy  con shape (SEQUENCE_LENGTH, NUM_FEATURES)
Teclas: q = salir
"""
import argparse
import cv2
import numpy as np

from config import ACTIONS, DATA_DIR, SEQUENCE_LENGTH, SEQUENCES_PER_ACTION
from keypoints import create_hands_detector, extract_keypoints, draw_landmarks


def next_index(action_dir):
    existing = [int(p.stem) for p in action_dir.glob("*.npy") if p.stem.isdigit()]
    return max(existing) + 1 if existing else 0


def put(img, text, pos, color=(0, 255, 0), scale=0.8):
    cv2.putText(img, text, pos, cv2.FONT_HERSHEY_SIMPLEX, scale, color, 2, cv2.LINE_AA)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", choices=ACTIONS, help="Grabar solo esta seña")
    parser.add_argument("--sequences", type=int, default=SEQUENCES_PER_ACTION)
    parser.add_argument("--camera", type=int, default=0)
    args = parser.parse_args()

    actions = [args.action] if args.action else ACTIONS
    cap = cv2.VideoCapture(args.camera)
    if not cap.isOpened():
        raise SystemExit("No se pudo abrir la cámara")

    with create_hands_detector() as hands:
        for action in actions:
            action_dir = DATA_DIR / action
            action_dir.mkdir(parents=True, exist_ok=True)
            start = next_index(action_dir)

            for seq in range(start, start + args.sequences):
                frames = []
                # Pausa de preparación antes de cada secuencia
                for wait in range(45):
                    ok, frame = cap.read()
                    if not ok:
                        continue
                    frame = cv2.flip(frame, 1)
                    put(frame, f"Preparate: {action}  ({seq - start + 1}/{args.sequences})", (15, 35), (0, 200, 255))
                    cv2.imshow("Recoleccion", frame)
                    if cv2.waitKey(1) & 0xFF == ord("q"):
                        return _close(cap)

                while len(frames) < SEQUENCE_LENGTH:
                    ok, frame = cap.read()
                    if not ok:
                        continue
                    frame = cv2.flip(frame, 1)
                    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    results = hands.process(rgb)
                    frames.append(extract_keypoints(results))

                    draw_landmarks(frame, results)
                    put(frame, f"GRABANDO {action}  frame {len(frames)}/{SEQUENCE_LENGTH}", (15, 35), (0, 0, 255))
                    cv2.imshow("Recoleccion", frame)
                    if cv2.waitKey(1) & 0xFF == ord("q"):
                        return _close(cap)

                np.save(action_dir / f"{seq}.npy", np.stack(frames))

    _close(cap)


def _close(cap):
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
