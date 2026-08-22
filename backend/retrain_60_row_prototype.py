"""Retrain the prototype artifact from the 60-row labeled CSV dataset."""
from pathlib import Path

from app.ml.models.trainer import train_and_evaluate


DATASET_PATH = Path(r"C:\Users\T.S Hari Prasanth\Downloads\OcuSense_60_Labelled_Prototype_Dataset.csv")


def main() -> None:
    bundle = train_and_evaluate(dataset_path=str(DATASET_PATH))
    print("Retraining complete.")
    print(bundle["training_data_source"])
    print(bundle["cv_results"])


if __name__ == "__main__":
    main()
