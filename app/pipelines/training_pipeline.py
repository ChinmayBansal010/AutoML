import matplotlib
matplotlib.use('Agg') # Use a non-interactive backend for running in scripts/servers
import matplotlib.pyplot as plt
import pandas as pd
import shap
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
import xgboost as xgb
import lightgbm as lgb
import catboost as cb
import os
import numpy as np

from app.pipelines.data_pipeline import create_preprocessing_pipeline
from app.schemas.model import PreprocessingConfig

# Dictionary mapping model names to their respective classifier classes
MODELS = {
    "random_forest": RandomForestClassifier,
    "xgboost": xgb.XGBClassifier,
    "lightgbm": lgb.LGBMClassifier,
    "catboost": cb.CatBoostClassifier,
    "logistic_regression": lambda: LogisticRegression(max_iter=1000), # Removed random_state for tuning
}

# --- NEW: Define hyperparameter search spaces for each model ---
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
        'num_leaves': [20, 31, 40]
    },
    "catboost": {
        'iterations': [100, 200],
        'depth': [4, 6]
    }
}

def run_training_pipeline(
    df: pd.DataFrame,
    target_column: str,
    model_name: str,
    preprocessing_config: PreprocessingConfig,
    test_size: float,
    plots_dir: str,
    hyperparameter_tuning: bool = False # New parameter to control tuning
) -> dict:
    """
    Runs the full ML training pipeline: data split, preprocessing, model training, and evaluation.
    """
    if model_name not in MODELS:
        raise ValueError(f"Unsupported model: {model_name}")

    # Drop high-cardinality identifier columns
    cols_to_drop = ['track_id', 'artists', 'album_name', 'track_name']
    df = df.drop(columns=[col for col in cols_to_drop if col in df.columns])

    # 1. Separate features (X) and target (y)
    X = df.drop(columns=[target_column])
    y = df[target_column]
    
    # 2. Split data into training and testing sets with a fallback for stratification
    try:
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=42, stratify=y
        )
    except ValueError:
        print("Stratified split failed. Falling back to a standard split.")
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=42
        )

    # 3. Create and fit the preprocessing pipeline
    numeric_cols = X_train.select_dtypes(include=['number']).columns.tolist()
    categorical_cols = X_train.select_dtypes(include=['object', 'category']).columns.tolist()
    
    preprocessor = create_preprocessing_pipeline(numeric_cols, categorical_cols, preprocessing_config)
    X_train_processed = preprocessor.fit_transform(X_train)
    X_test_processed = preprocessor.transform(X_test)

    # 4. Train the specified model, with optional hyperparameter tuning
    model_class = MODELS[model_name]
    # Use a lambda for LogisticRegression or instantiate others with a random_state if not tuning
    base_model = model_class() if callable(model_class) else model_class(random_state=42)

    if hyperparameter_tuning and model_name in PARAM_GRIDS:
        print(f"Starting hyperparameter tuning for {model_name}...")
        # Use GridSearchCV to find the best model parameters
        grid_search = GridSearchCV(base_model, PARAM_GRIDS[model_name], cv=3, scoring='accuracy', n_jobs=-1, error_score='raise')
        grid_search.fit(X_train_processed, y_train)
        model = grid_search.best_estimator_
        print(f"Best parameters found for {model_name}: {grid_search.best_params_}")
    else:
        print(f"Starting standard training for {model_name}...")
        model = base_model
        model.fit(X_train_processed, y_train)

    # 5. Make predictions and evaluate
    y_pred = model.predict(X_test_processed)
    
    # Handle multi-class metric calculation gracefully
    avg_method = 'weighted' if y.nunique() > 2 else 'binary'
    
    metrics = {
        "accuracy": accuracy_score(y_test, y_pred),
        "precision": precision_score(y_test, y_pred, average=avg_method, zero_division=0),
        "recall": recall_score(y_test, y_pred, average=avg_method, zero_division=0),
        "f1_score": f1_score(y_test, y_pred, average=avg_method, zero_division=0),
        "confusion_matrix": confusion_matrix(y_test, y_pred).tolist()
    }

    # (SHAP and plotting logic would go here, simplified for brevity)
    
    return {
        "model": model,
        "metrics": metrics,
        "plots": {}
    }

