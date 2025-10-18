import matplotlib
matplotlib.use('Agg')
import pandas as pd
import shap
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import LabelEncoder
import xgboost as xgb
import lightgbm as lgb
import catboost as cb
import os
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
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    return obj

MODELS = {
    "random_forest": lambda: RandomForestClassifier(random_state=42),
    "xgboost": lambda: xgb.XGBClassifier(random_state=42, use_label_encoder=False, eval_metric='mlogloss'),
    "lightgbm": lambda: lgb.LGBMClassifier(random_state=42, verbose=-1),
    "catboost": lambda: cb.CatBoostClassifier(random_state=42, verbose=0),
    "logistic_regression": lambda: LogisticRegression(max_iter=1000, random_state=42),
}

PARAM_GRIDS = {
    "random_forest": {'n_estimators': [100, 200], 'max_depth': [10, 20, None]},
    "logistic_regression": {'C': [0.1, 1.0, 10.0], 'solver': ['liblinear']},
    "xgboost": {'n_estimators': [100, 200], 'max_depth': [3, 5], 'learning_rate': [0.05, 0.1]},
    "lightgbm": {'n_estimators': [100, 200], 'num_leaves': [20, 31, 40]},
    "catboost": {'iterations': [100, 200], 'depth': [4, 6]}
}

def _sanitize_feature_names(df: pd.DataFrame) -> pd.DataFrame:
    new_columns = {}
    for col in df.columns:
        sanitized_col = re.sub(r'[^A-Za-z0-9_]+', '_', str(col))
        if re.match(r'^\d', sanitized_col):
            sanitized_col = f'col_{sanitized_col}'
        new_columns[col] = sanitized_col
    return df.rename(columns=new_columns)

def _get_confusion_matrix_data(y_test_encoded, y_pred_encoded, class_labels, present_labels):
    cm = confusion_matrix(y_test_encoded, y_pred_encoded, labels=present_labels)
    return {"labels": class_labels, "matrix": cm.tolist()}

def _get_shap_summary_data(model, X_test_processed, model_name):
    try:
        if model_name in ["random_forest", "xgboost", "lightgbm", "catboost"]:
            explainer = shap.TreeExplainer(model)
        elif model_name == "logistic_regression":
            explainer = shap.LinearExplainer(model, X_test_processed)
        else:
            return None
        shap_values = explainer.shap_values(X_test_processed)
        feature_names = X_test_processed.columns.tolist()
        if isinstance(shap_values, list):
            mean_abs_shap = np.mean(np.abs(np.stack(shap_values, axis=-1)), axis=(0, 2))
        else:
            mean_abs_shap = np.mean(np.abs(shap_values), axis=0)
        return {"feature_names": feature_names, "mean_abs_shap_values": mean_abs_shap.tolist()}
    except Exception as e:
        print(f"SHAP calculation failed for {model_name}: {e}")
        return None

def run_training_pipeline(
    df: pd.DataFrame,
    target_column: str,
    model_name: str,
    preprocessing_config: PreprocessingConfig,
    test_size: float,
    plots_dir: str,
    hyperparameter_tuning: bool = False
) -> dict:

    high_cardinality_cols = []
    for col in df.select_dtypes(include=['object', 'category']).columns:
        if col != target_column and df[col].nunique() / len(df) > 0.95:
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
    num_classes = len(label_encoder.classes_)
    
    try:
        X_train, X_test, y_train_encoded, y_test_encoded = train_test_split(
            X, y_encoded, test_size=test_size, random_state=42, stratify=y_encoded)
    except ValueError:
        print("Stratified split failed. Falling back to a standard split.")
        X_train, X_test, y_train_encoded, y_test_encoded = train_test_split(
            X, y_encoded, test_size=test_size, random_state=42
        )

    numeric_cols = X_train.select_dtypes(include=np.number).columns.tolist()
    categorical_cols = X_train.select_dtypes(exclude=np.number).columns.tolist()
    
    preprocessor = create_preprocessing_pipeline(numeric_cols, categorical_cols, preprocessing_config)
    preprocessor.set_output(transform="pandas")
    
    X_train_processed = preprocessor.fit_transform(X_train)
    X_test_processed = preprocessor.transform(X_test)
    
    X_train_processed = _sanitize_feature_names(X_train_processed).astype(np.float64)
    X_test_processed = _sanitize_feature_names(X_test_processed).astype(np.float64)

    # --- THIS IS THE ROBUST XGBOOST FIX ---
    base_model = MODELS[model_name]()
    if model_name == "xgboost":
        # Explicitly set the number of classes for XGBoost
        base_model.set_params(num_class=num_classes)
    
    model = base_model
    if hyperparameter_tuning and model_name in PARAM_GRIDS:
        grid_search = GridSearchCV(base_model, PARAM_GRIDS[model_name], cv=3, scoring='accuracy', n_jobs=-1, error_score='raise')
        grid_search.fit(X_train_processed, y_train_encoded)
        model = grid_search.best_estimator_
    else:
        model.fit(X_train_processed, y_train_encoded)
    
    y_pred_encoded = model.predict(X_test_processed)
    
    present_labels = np.union1d(y_test_encoded, y_pred_encoded)
    target_names_present = label_encoder.inverse_transform(present_labels)

    report = classification_report(
        y_test_encoded, y_pred_encoded, 
        labels=present_labels, target_names=target_names_present, 
        output_dict=True, zero_division=0
    )
    
    # --- THIS FIX ensures 'accuracy' is always present ---
    overall_metrics = report.get('weighted avg', {})
    if 'accuracy' in report:
        overall_metrics['accuracy'] = report['accuracy']

    metrics = {
        "overall_metrics": overall_metrics,
        "per_class_metrics": {cls: report.get(cls, {}) for cls in target_names_present},
        "confusion_matrix": confusion_matrix(y_test_encoded, y_pred_encoded, labels=present_labels).tolist()
    }
    
    plots = {
        "confusion_matrix": _get_confusion_matrix_data(y_test_encoded, y_pred_encoded, target_names_present.tolist(), present_labels),
        "shap_summary": _get_shap_summary_data(model, X_test_processed, model_name)
    }

    details = {
        "model_parameters": {k: str(v) for k, v in model.get_params().items()},
        "preprocessing_config": preprocessing_config.dict(),
        "n_features_used": X_train_processed.shape[1],
        "target_column": target_column,
        "target_classes": label_encoder.classes_.tolist()
    }
    return _clean_for_json({
        "model": model, "metrics": metrics,
        "plots": plots, "details": details
    })