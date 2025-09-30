import numpy as np
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from app.schemas.model import PreprocessingConfig # Import the Pydantic model for type hinting

def create_preprocessing_pipeline(
    numeric_features: list,
    categorical_features: list,
    config: PreprocessingConfig # Use the specific Pydantic model
) -> ColumnTransformer:
    """
    Creates a scikit-learn preprocessing pipeline based on dynamic configuration.

    Args:
        numeric_features: List of names of numeric columns.
        categorical_features: List of names of categorical columns.
        config: A Pydantic object containing preprocessing settings.

    Returns:
        A scikit-learn ColumnTransformer object ready to be fitted.
    """
    # --- Define individual transformation steps ---

    # Pipeline for numeric features:
    numeric_transformer = Pipeline(steps=[
        ('imputer', SimpleImputer(strategy=config.numeric_imputation)),
        ('scaler', StandardScaler() if config.scaling_strategy == 'standard_scaler' else None)
    ])

    # Pipeline for categorical features:
    categorical_transformer = Pipeline(steps=[
        ('imputer', SimpleImputer(strategy=config.categorical_imputation)),
        ('onehot', OneHotEncoder(handle_unknown='ignore'))
    ])

    # --- Combine transformers into a single preprocessor object ---
    preprocessor = ColumnTransformer(
        transformers=[
            ('num', numeric_transformer, numeric_features),
            ('cat', categorical_transformer, categorical_features)
        ],
        remainder='passthrough' # Keep other columns if any
    )

    return preprocessor

