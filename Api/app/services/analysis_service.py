import pandas as pd
import numpy as np
import math
from fastapi import Depends
from app.services.file_service import FileService
from app.schemas.analysis import AnalysisResponse, ColumnStats


def safe_float(value):
    """Convert any non-finite or empty value to None for JSON serialization."""
    try:
        if value in [None, "", " ", "NaN", "nan"]:
            return None
        value = float(value)
        if math.isnan(value) or math.isinf(value):
            return None
        return value
    except Exception:
        return None


def clean_for_json(obj):
    """Recursively clean dicts/lists of NaN, inf, or invalid values."""
    if isinstance(obj, dict):
        return {k: clean_for_json(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [clean_for_json(v) for v in obj]
    elif isinstance(obj, float) and (math.isnan(obj) or math.isinf(obj)):
        return None
    elif obj in [np.nan, np.inf, -np.inf, "", " ", "NaN", "nan"]:
        return None
    return obj


class AnalysisService:
    def __init__(self, file_service: FileService = Depends()):
        self.file_service = file_service

    def get_data_preview(self, file_id: str, num_rows: int = 500) -> dict:
        """
        Retrieves a DataFrame using the file_id and returns a clean, JSON-safe preview.
        """
        try:
            df = self.file_service.get_dataframe(file_id)
            if df is None:
                raise FileNotFoundError(f"No data found for file_id: {file_id}")

            preview_df = df.head(num_rows)

            # Replace invalid, infinite, or empty string values
            preview_df = preview_df.replace([np.inf, -np.inf, "", " ", "NaN", "nan"], np.nan)

            # Convert DataFrame to JSON-safe structure
            def sanitize_value(val):
                if pd.isna(val) or val in [np.inf, -np.inf]:
                    return None
                if isinstance(val, (np.float32, np.float64)):
                    if math.isnan(val) or math.isinf(val):
                        return None
                    return float(val)
                if isinstance(val, (np.int32, np.int64)):
                    return int(val)
                return val

            json_safe_data = [
                [sanitize_value(v) for v in row]
                for row in preview_df.values.tolist()
            ]

            return {
                "columns": preview_df.columns.tolist(),
                "data": json_safe_data
            }

        except Exception as e:
            raise RuntimeError(f"An error occurred during data preview generation: {e}")


    def generate_eda_report(self, file_id: str) -> dict:
        """
        Generates a comprehensive EDA report, cleaning data and ensuring JSON safety.
        """
        try:
            df = self.file_service.get_dataframe(file_id)
            if df is None:
                raise FileNotFoundError(f"No data found for file_id: {file_id}")

            # Replace invalid and empty string values
            df = df.replace([np.inf, -np.inf, "", " ", "NaN", "nan"], np.nan)

            row_count, col_count = df.shape
            duplicate_rows = int(df.duplicated().sum())
            missing_values_total = int(df.isnull().sum().sum())

            column_details = {}
            for col in df.columns:
                col_data = df[col]

                value_counts = col_data.value_counts(dropna=False).head(10)
                value_counts_str_keys = {str(k): int(v) for k, v in value_counts.items()}

                min_val = max_val = mean_val = std_val = None
                if pd.api.types.is_numeric_dtype(col_data) and col_data.notna().any():
                    clean_col = col_data.dropna()
                    if not clean_col.empty:
                        min_val = safe_float(clean_col.min())
                        max_val = safe_float(clean_col.max())
                        mean_val = safe_float(clean_col.mean())
                        std_val = safe_float(clean_col.std())

                column_details[col] = ColumnStats(
                    dtype=str(col_data.dtype),
                    missing_count=int(col_data.isnull().sum()),
                    unique_count=int(col_data.nunique(dropna=True)),
                    value_counts=value_counts_str_keys,
                    min_value=min_val,
                    max_value=max_val,
                    mean=mean_val,
                    std=std_val,
                )

            visualizations = {}
            target_column_analysis = None

            result = AnalysisResponse(
                file_id=file_id,
                row_count=row_count,
                column_count=col_count,
                duplicate_rows=duplicate_rows,
                missing_values_total=missing_values_total,
                summary_stats=column_details,
                visualizations=visualizations,
                target_column_analysis=target_column_analysis
            )

            # Convert to dict and clean all possible bad values
            return clean_for_json(result.dict())

        except Exception as e:
            raise RuntimeError(f"An unexpected error occurred during analysis: {e}")
