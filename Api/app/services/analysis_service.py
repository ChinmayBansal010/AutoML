import pandas as pd
import numpy as np
import math
from fastapi import Depends
from app.services.file_service import FileService
from app.schemas.analysis import AnalysisResponse, ColumnStats
from app.core.security import get_current_user


def safe_float(value):
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
        try:
            df = self.file_service.get_dataframe(file_id)
            if df is None:
                raise FileNotFoundError(f"No data found for file_id: {file_id}")

            preview_df = df.head(num_rows)
            preview_df = preview_df.replace([np.inf, -np.inf, "", " ", "NaN", "nan"], np.nan)
            
            columns = preview_df.columns.tolist()
            column_types = {col: str(preview_df[col].dtype) for col in columns}

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
                "total_rows": df.shape[0],
                "column_types": column_types,
                "columns": columns,
                "data": json_safe_data
            }
        except Exception as e:
            raise RuntimeError(f"An error occurred during data preview generation: {e}")

    def get_visualization_data(self, file_id: str, col1: str, col2: str = None) -> dict:
        try:
            df = self.file_service.get_dataframe(file_id)
            if df is None:
                raise FileNotFoundError(f"No data found for file_id: {file_id}")
            
            if col1 not in df.columns or (col2 and col2 not in df.columns):
                raise ValueError("Invalid column name(s) provided.")

            response = {"column_1": {}, "scatter_data": None}

            col1_type = 'numeric' if pd.api.types.is_numeric_dtype(df[col1]) else 'categorical'
            response["column_1"]["type"] = col1_type
            
            if col1_type == 'numeric':
                clean_col = df[col1].dropna()
                stats = clean_col.describe()
                response["column_1"]["stats"] = {
                    "min": safe_float(stats.get("min")), "max": safe_float(stats.get("max")),
                    "mean": safe_float(stats.get("mean")), "median": safe_float(stats.get("50%")),
                }
                bins = min(50, clean_col.nunique())
                hist, edges = np.histogram(clean_col, bins=bins if bins > 0 else 1)
                response["column_1"]["chart_data"] = {
                    "labels": [f"{edges[i]:.1f}-{edges[i+1]:.1f}" for i in range(len(edges)-1)],
                    "values": [int(v) for v in hist]
                }
            else:
                value_counts = df[col1].value_counts().nlargest(15)
                response["column_1"]["chart_data"] = {
                    "labels": [str(k) for k in value_counts.index.tolist()],
                    "values": [int(v) for v in value_counts.values.tolist()]
                }
            
            if col2 and pd.api.types.is_numeric_dtype(df[col1]) and pd.api.types.is_numeric_dtype(df[col2]):
                clean_scatter_df = df[[col1, col2]].dropna()
                sample_size = min(len(clean_scatter_df), 1000)
                
                if sample_size > 0:
                    sample_df = clean_scatter_df.sample(n=sample_size, random_state=42)
                    response["scatter_data"] = {
                        "x": [safe_float(v) for v in sample_df[col1].tolist()],
                        "y": [safe_float(v) for v in sample_df[col2].tolist()],
                    }

            return clean_for_json(response)

        except Exception as e:
            raise RuntimeError(f"An unexpected error occurred during visualization data generation: {e}")

    def generate_eda_report(self, file_id: str, target_column: str = None) -> dict:
        try:
            df = self.file_service.get_dataframe(file_id)
            if df is None:
                raise FileNotFoundError(f"No data found for file_id: {file_id}")

            df = df.replace([np.inf, -np.inf, "", " ", "NaN", "nan"], np.nan)

            row_count, col_count = df.shape
            duplicate_rows = int(df.duplicated().sum())
            missing_values_total = int(df.isnull().sum().sum())

            column_details = {}
            for col in df.columns:
                col_data = df[col]
                missing_count = int(col_data.isnull().sum())
                unique_count = int(col_data.nunique())
                stats = {
                    "missing_percentage": round((missing_count / row_count) * 100, 2) if row_count > 0 else 0,
                    "unique_values": unique_count
                }

                if pd.api.types.is_numeric_dtype(col_data):
                    stats["type"] = "numeric"
                    desc = col_data.describe()
                    stats["mean"] = safe_float(desc.get('mean'))
                    stats["std"] = safe_float(desc.get('std'))
                    stats["min"] = safe_float(desc.get('min'))
                    stats["max"] = safe_float(desc.get('max'))
                    stats["median"] = safe_float(desc.get('50%'))
                else:
                    stats["type"] = "categorical"
                    top_freq = col_data.value_counts().nlargest(5)
                    stats["top_values"] = {str(k): int(v) for k, v in top_freq.items()}
                
                column_details[col] = ColumnStats(**stats).dict()

            target_column_analysis = None
            if target_column and target_column in df.columns:
                target_data = df[target_column].dropna()
                
                if pd.api.types.is_numeric_dtype(target_data):
                    target_column_analysis = {
                        "inferred_task": "Regression",
                        "stats": {
                            "mean": safe_float(target_data.mean()),
                            "std": safe_float(target_data.std()),
                            "min": safe_float(target_data.min()),
                            "max": safe_float(target_data.max()),
                        }
                    }
                else:
                    value_counts = target_data.value_counts()
                    target_column_analysis = {
                        "inferred_task": "Classification",
                        "class_distribution": {str(k): int(v) for k, v in value_counts.items()}
                    }

            visualizations = {}
            
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

            return clean_for_json(result.dict())

        except Exception as e:
            raise RuntimeError(f"An unexpected error occurred during analysis: {e}")