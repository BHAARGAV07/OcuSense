"""Run a guarded retraining job using real, outcome-labeled OcuSense data."""
from app.database import SessionLocal
from app.ml.models.trainer import retrain_from_outcomes


def main() -> None:
    db = SessionLocal()
    try:
        bundle = retrain_from_outcomes(db)
        print("Retraining complete.")
        print(bundle["cv_results"])
    finally:
        db.close()


if __name__ == "__main__":
    main()
