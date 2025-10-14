import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd
import shap
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix, classification_report
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import LabelEncoder
import xgboost as xgb
import lightgbm as lgb
import catboost as cb
import os
import numpy as np
import re
import seaborn as sns

from app.pipelines.data_pipeline import create_preprocessing_pipeline
from app.schemas.model import PreprocessingConfig

MODELS = {
    "random_forest": lambda: RandomForestClassifier(random_state=42), 
    "xgboost": lambda: xgb.XGBClassifier(random_state=42),
    "lightgbm": lambda: lgb.LGBMClassifier(random_state=42, verbose=-1), 
    "catboost": lambda: cb.CatBoostClassifier(random_state=42, verbose=0), 
    "logistic_regression": lambda: LogisticRegression(max_iter=1000, random_state=42), 
}

PARAM_GRIDS = {
    "random_forest": {
        'n_estimators': [100, 200],
        'max_depth': [10, 20, None],
    },
    "logistic_regression": {
        'C': [0.1, 1.0, 10.0],
        'solver': ['liblinear']
    },
    "xgboost": {
        'n_estimators': [100, 200],
        'max_depth': [3, 5],
        'learning_rate': [0.05, 0.1]
    },
    "lightgbm": {
        'n_estimators': [100, 200],
        'num_leaves': [20, 31, 40],
        'min_child_samples': [10, 20, 50], 
        'min_split_gain': [0.0, 0.1]
    },
    "catboost": {
        'iterations': [100, 200],
        'depth': [4, 6]
    }
}

def _sanitize_feature_names(df: pd.DataFrame) -> pd.DataFrame:
    new_columns = {}
    for col in df.columns:
        sanitized_col = re.sub('[^A-Za-z0-9_]+', '_', col)
        if re.match(r'^\d', sanitized_col):
            sanitized_col = f'col_{sanitized_col}'
        new_columns[col] = sanitized_col
    return df.rename(columns=new_columns)

def _get_confusion_matrix_data(y_test_encoded, y_pred_encoded, class_labels):
    cm = confusion_matrix(y_test_encoded, y_pred_encoded)
    return {
        "labels": class_labels,
        "matrix": cm.tolist()
    }

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
            mean_abs_shap = np.mean(np.abs(np.stack(shap_values, axis=-1)), axis=(0, 2)).tolist()
        else:
            mean_abs_shap = np.mean(np.abs(shap_values), axis=0).tolist()
        
        return {
            "feature_names": feature_names,
            "mean_abs_shap_values": mean_abs_shap
        }
    except Exception as e:
        print(f"SHAP calculation failed: {e}")
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
    
    if model_name not in MODELS:
        raise ValueError(f"Unsupported model: {model_name}")

    cols_to_drop = ['track_id', 'artists', 'album_name', 'track_name']
    df = df.drop(columns=[col for col in cols_to_drop if col in df.columns])

    X = df.drop(columns=[target_column])
    y = df[target_column]
    
    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y)
    class_labels = label_encoder.classes_.tolist()
    
    try:
        X_train, X_test, y_train_encoded, y_test_encoded = train_test_split(
            X, y_encoded, test_size=test_size, random_state=42, stratify=y_encoded
        )
    except ValueError:
        print("Stratified split failed. Falling back to a standard split.")
        X_train, X_test, y_train_encoded, y_test_encoded = train_test_split(
            X, y_encoded, test_size=test_size, random_state=42
        )

    numeric_cols = X_train.select_dtypes(include=['number']).columns.tolist()
    categorical_cols = X_train.select_dtypes(include=['object', 'category']).columns.tolist()
    
    preprocessor = create_preprocessing_pipeline(numeric_cols, categorical_cols, preprocessing_config)
    
    try:
        preprocessor.set_output(transform="pandas")
    except AttributeError:
        pass
    
    X_train_processed = preprocessor.fit_transform(X_train)
    X_test_processed = preprocessor.transform(X_test)
    
    X_train_processed = _sanitize_feature_names(X_train_processed)
    X_test_processed = _sanitize_feature_names(X_test_processed)
    
    X_train_processed = X_train_processed.astype(np.float64)
    X_test_processed = X_test_processed.astype(np.float64)

    model_class = MODELS[model_name]
    base_model = model_class()

    final_params = None

    if hyperparameter_tuning and model_name in PARAM_GRIDS:
        print(f"Starting hyperparameter tuning for {model_name}...")
        grid_search = GridSearchCV(base_model, PARAM_GRIDS[model_name], cv=3, scoring='accuracy', n_jobs=-1, error_score='raise')
        grid_search.fit(X_train_processed, y_train_encoded)
        model = grid_search.best_estimator_
        final_params = model.get_params()
        print(f"Best parameters found for {model_name}: {grid_search.best_params_}")
    else:
        print(f"Starting standard training for {model_name}...")
        model = base_model
        model.fit(X_train_processed, y_train_encoded)
        final_params = model.get_params()

    y_pred_encoded = model.predict(X_test_processed)
    
    report = classification_report(y_test_encoded, y_pred_encoded, target_names=class_labels, output_dict=True, zero_division=0)
    
    metrics = {
        "overall_metrics": {
            "accuracy": report['accuracy'],
            "weighted_precision": report['weighted avg']['precision'],
            "weighted_recall": report['weighted avg']['recall'],
            "weighted_f1_score": report['weighted avg']['f1-score'],
            "macro_precision": report['macro avg']['precision'],
            "macro_recall": report['macro avg']['recall'],
            "macro_f1_score": report['macro avg']['f1-score'],
        },
        "per_class_metrics": { 
            cls: {
                "precision": report[cls]['precision'],
                "recall": report[cls]['recall'],
                "f1_score": report[cls]['f1-score'],
                "support": report[cls]['support']
            }
            for cls in class_labels
        },
        "target_classes": class_labels, 
        "confusion_matrix": confusion_matrix(y_test_encoded, y_pred_encoded).tolist()
    }
    
    plots = {}
    plots["confusion_matrix"] = _get_confusion_matrix_data(y_test_encoded, y_pred_encoded, class_labels)
    plots["shap_summary"] = _get_shap_summary_data(model, X_test_processed, model_name)

    details = {
        "model_parameters": final_params,
        "preprocessing_config": preprocessing_config.dict(),
        "n_features_used": X_train_processed.shape[1],
        "n_train_samples": len(y_train_encoded),
        "n_test_samples": len(y_test_encoded),
        "target_column": target_column,
        "original_class_distribution": y.value_counts().to_dict()
    }

    return {
        "model": model,
        "metrics": metrics,
        "plots": plots,
        "details": details
    }