import pytest
import pandas as pd
import numpy as np
# Import ColumnTransformer to check the instance type correctly
from sklearn.compose import ColumnTransformer

from app.pipelines.data_pipeline import create_preprocessing_pipeline
from app.pipelines.training_pipeline import run_training_pipeline
from app.schemas.model import PreprocessingConfig

@pytest.fixture
def sample_dataframe():
    """Creates a sample pandas DataFrame for testing."""
    data = {
        'numeric_feature_1': [1, 2, np.nan, 4, 5],
        'numeric_feature_2': [10.5, 20.1, 30.2, 40.3, 50.4],
        'categorical_feature': ['A', 'B', 'A', 'C', 'B'],
        'target': [0, 1, 0, 1, 0]
    }
    return pd.DataFrame(data)

def test_create_preprocessing_pipeline(sample_dataframe):
    """
    Test the creation and functionality of the data preprocessing pipeline.
    """
    df = sample_dataframe.copy()
    X = df.drop('target', axis=1)
    
    config = PreprocessingConfig(
        numeric_imputation="mean",
        categorical_imputation="most_frequent",
        scaling_strategy="standard_scaler",
        encoding_strategy="one-hot"
    )

    numeric_cols = X.select_dtypes(include=np.number).columns.tolist()
    categorical_cols = X.select_dtypes(include=['object', 'category']).columns.tolist()
    
    pipeline = create_preprocessing_pipeline(numeric_cols, categorical_cols, config)
    
    # Assert that the created object is an instance of ColumnTransformer
    assert isinstance(pipeline, ColumnTransformer)
    
    X_transformed = pipeline.fit_transform(X)
    
    # After one-hot encoding 'A', 'B', 'C', we get 3 columns. Total = 2 numeric + 3 categorical = 5
    assert X_transformed.shape[1] == 5
    assert not np.isnan(X_transformed).any()

def test_run_training_pipeline(sample_dataframe):
    """
    Test the end-to-end training pipeline with a simple model.
    """
    import os
    plot_dir = 'tests/temp_plots'
    os.makedirs(plot_dir, exist_ok=True)
    
    config = PreprocessingConfig(
        numeric_imputation="median",
        categorical_imputation="most_frequent",
        scaling_strategy="standard_scaler",
        encoding_strategy="one-hot"
    )

    results = run_training_pipeline(
        df=sample_dataframe,
        target_column='target',
        model_name='logistic_regression',
        preprocessing_config=config,
        test_size=0.25,
        plots_dir=plot_dir
    )

    assert isinstance(results, dict)
    assert 'model' in results
    assert 'metrics' in results
    assert 'plots' in results
    
    metrics = results['metrics']
    assert 'accuracy' in metrics
    assert 0.0 <= metrics['accuracy'] <= 1.0
    
    plots = results['plots']
    assert 'confusion_matrix' in plots
    assert os.path.exists(plots['confusion_matrix'])

