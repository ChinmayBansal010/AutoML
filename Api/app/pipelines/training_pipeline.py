import matplotlib
matplotlib.use("Agg")
import pandas as pd
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.preprocessing import LabelEncoder
import numpy as np
import re
import json

from app.pipelines.data_pipeline import create_preprocessing_pipeline
from app.schemas.model import PreprocessingConfig


def _clean_for_json(obj):
    if isinstance(obj, dict):
        return {str(k): _clean_for_json(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [_clean_for_json(v) for v in obj]
    elif isinstance(obj, np.integer):
        return int(obj)
    elif isinstance(obj, np.floating):
        if np.isnan(obj) or np.isinf(obj):
            return None
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    elif isinstance(obj, pd.Timestamp):
        return obj.isoformat()
    return obj


MODELS = {
    "random_forest": lambda: RandomForestClassifier(random_state=42),
    "logistic_regression": lambda: LogisticRegression(max_iter=1000, random_state=42),
    "decision_tree": lambda: DecisionTreeClassifier(random_state=42),
}

PARAM_GRIDS = {
    "random_forest": {"n_estimators": [100, 200], "max_depth": [10, 20, None]},
    "logistic_regression": {"C": [0.1, 1.0, 10.0], "solver": ["liblinear"]},
    "decision_tree": {"max_depth": [5, 10, 20, None], "min_samples_leaf": [1, 2, 4]},
}


def _sanitize_feature_names(df: pd.DataFrame) -> pd.DataFrame:
    new_columns = {}
    for col in df.columns:
        sanitized_col = re.sub(r"[^A-Za-z0-9_]+", "_", str(col))
        if re.match(r"^\d", sanitized_col):
            sanitized_col = f"col_{sanitized_col}"
        new_columns[col] = sanitized_col
    return df.rename(columns=new_columns)


def _get_confusion_matrix_data(
    y_test_encoded, y_pred_encoded, class_labels, present_labels
):
    cm = confusion_matrix(y_test_encoded, y_pred_encoded, labels=present_labels)
    return {"labels": class_labels, "matrix": cm.tolist()}


def run_training_pipeline(
    df: pd.DataFrame,
    target_column: str,
    model_name: str,
    preprocessing_config: PreprocessingConfig,
    test_size: float,
    hyperparameter_tuning: bool = False,
) -> dict:

    high_cardinality_cols = []
    for col in df.select_dtypes(include=["object", "category"]).columns:
        if col != target_column and df[col].nunique() / len(df) > 0.95:
             if col in df.columns:
                high_cardinality_cols.append(col)

    if high_cardinality_cols:
        df = df.drop(columns=high_cardinality_cols)

    if df[target_column].isnull().any():
        df.dropna(subset=[target_column], inplace=True)
        df.reset_index(drop=True, inplace=True)

    X = df.drop(columns=[target_column])
    y = df[target_column]

    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y)

    try:
        X_train, X_test, y_train_encoded, y_test_encoded = train_test_split(
            X, y_encoded, test_size=test_size, random_state=42, stratify=y_encoded
        )
    except ValueError:
        print("Stratified split failed. Falling back to a standard split.")
        X_train, X_test, y_train_encoded, y_test_encoded = train_test_split(
            X, y_encoded, test_size=test_size, random_state=42
        )

    numeric_cols = X_train.select_dtypes(include=np.number).columns.tolist()
    categorical_cols = X_train.select_dtypes(exclude=np.number).columns.tolist()

    preprocessor = create_preprocessing_pipeline(
        numeric_cols, categorical_cols, preprocessing_config
    )
    
    try:
        preprocessor.set_output(transform="pandas")
    except AttributeError:
        pass


    X_train_processed = preprocessor.fit_transform(X_train)
    X_test_processed = preprocessor.transform(X_test)

    X_train_processed = _sanitize_feature_names(X_train_processed).astype(np.float64)
    X_test_processed = _sanitize_feature_names(X_test_processed).astype(np.float64)

    base_model = MODELS[model_name]()
    
    model = base_model
    if hyperparameter_tuning and model_name in PARAM_GRIDS:
        grid_search = GridSearchCV(
            base_model,
            PARAM_GRIDS[model_name],
            cv=3,
            scoring="accuracy",
            n_jobs=-1,
            error_score="raise",
        )
        grid_search.fit(X_train_processed, y_train_encoded)
        model = grid_search.best_estimator_
    else:
        model.fit(X_train_processed, y_train_encoded)

    y_pred_encoded = model.predict(X_test_processed)

    present_labels = np.union1d(y_test_encoded, y_pred_encoded)
    valid_present_labels = [label for label in present_labels if label < len(label_encoder.classes_)]
    target_names_present = label_encoder.inverse_transform(valid_present_labels)


    report = classification_report(
        y_test_encoded,
        y_pred_encoded,
        labels=valid_present_labels,
        target_names=target_names_present,
        output_dict=True,
        zero_division=0,
    )

    overall_metrics = report.get("weighted avg", {})
    if "accuracy" in report:
        overall_metrics["accuracy"] = report["accuracy"]

    metrics = {
        "overall_metrics": overall_metrics,
        "per_class_metrics": {cls: report.get(cls, {}) for cls in target_names_present},
        "confusion_matrix": confusion_matrix(
            y_test_encoded, y_pred_encoded, labels=valid_present_labels
        ).tolist(),
    }

    plots = {
        "confusion_matrix": _get_confusion_matrix_data(
            y_test_encoded,
            y_pred_encoded,
            target_names_present.tolist(),
            valid_present_labels,
        ),
        "shap_summary": None,
    }

    details = {
        "model_parameters": {k: str(v) for k, v in model.get_params().items()},
        "preprocessing_config": preprocessing_config.dict(),
        "n_features_used": X_train_processed.shape[1],
        "target_column": target_column,
        "target_classes": label_encoder.classes_.tolist(),
    }
    return _clean_for_json({
        "model": model,
        "preprocessor": preprocessor,
        "metrics": metrics,
        "plots": plots,
        "details": details
    })