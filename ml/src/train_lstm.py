"""Entrena la LSTM que clasifica secuencias de keypoints en señas.

Uso:
    python src/train_lstm.py
"""
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix

from config import (
    ACTIONS, DATA_DIR, SEQUENCE_LENGTH, NUM_FEATURES, EPOCHS, BATCH_SIZE,
    TEST_SIZE, SEED, KERAS_MODEL_PATH, LABELS_PATH, MODELS_DIR,
)


def load_dataset():
    X, y = [], []
    for idx, action in enumerate(ACTIONS):
        files = sorted((DATA_DIR / action).glob("*.npy"))
        if not files:
            print(f"[AVISO] No hay datos para '{action}'")
        for f in files:
            seq = np.load(f)
            if seq.shape == (SEQUENCE_LENGTH, NUM_FEATURES):
                X.append(seq)
                y.append(idx)
    if not X:
        raise SystemExit("Dataset vacío. Ejecuta primero src/collect_data.py")
    return np.array(X, dtype=np.float32), np.array(y)


def augment(X, y, copies=2, noise=0.02):
    """Data augmentation simple: ruido gaussiano + escalado aleatorio."""
    out_x, out_y = [X], [y]
    rng = np.random.default_rng(SEED)
    for _ in range(copies):
        scale = rng.uniform(0.9, 1.1, size=(len(X), 1, 1)).astype(np.float32)
        jitter = rng.normal(0, noise, size=X.shape).astype(np.float32)
        aug = X * scale + jitter
        aug[X == 0] = 0  # mantener manos ausentes en cero
        out_x.append(aug)
        out_y.append(y)
    return np.concatenate(out_x), np.concatenate(out_y)


def build_model(num_classes):
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(SEQUENCE_LENGTH, NUM_FEATURES)),
        tf.keras.layers.LSTM(64, return_sequences=True),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.LSTM(128, return_sequences=False),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(64, activation="relu"),
        tf.keras.layers.Dense(num_classes, activation="softmax"),
    ])
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


def main():
    tf.random.set_seed(SEED)
    X, y = load_dataset()
    print(f"Dataset: X={X.shape}  y={y.shape}  clases={len(ACTIONS)}")

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=TEST_SIZE, stratify=y, random_state=SEED
    )
    X_train, y_train = augment(X_train, y_train)

    model = build_model(len(ACTIONS))
    model.summary()

    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    callbacks = [
        tf.keras.callbacks.EarlyStopping(monitor="val_accuracy", patience=25, restore_best_weights=True),
        tf.keras.callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=10),
        tf.keras.callbacks.TensorBoard(log_dir=str(MODELS_DIR / "logs")),
    ]
    model.fit(
        X_train, y_train,
        validation_data=(X_test, y_test),
        epochs=EPOCHS, batch_size=BATCH_SIZE, callbacks=callbacks,
    )

    y_pred = model.predict(X_test).argmax(axis=1)
    print(classification_report(y_test, y_pred, target_names=ACTIONS, zero_division=0))
    print(confusion_matrix(y_test, y_pred))

    model.save(KERAS_MODEL_PATH)
    LABELS_PATH.write_text("\n".join(ACTIONS), encoding="utf-8")
    print(f"Modelo guardado en {KERAS_MODEL_PATH}")
    print(f"Etiquetas guardadas en {LABELS_PATH}")


if __name__ == "__main__":
    main()
