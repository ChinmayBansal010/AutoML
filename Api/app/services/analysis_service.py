import pandas as pd
from fastapi import Depends

from app.services.file_service import FileService
from app.schemas.analysis import AnalysisResult, ColumnStats

class AnalysisService:
    def __init__(self, file_service: FileService = Depends(FileService)):
        self.file_service = file_service

    def generate_eda_report(self, file_id: str) -> AnalysisResult:
        """
        Generates a comprehensive EDA report for a given file ID.
        """
        try:
            df = self.file_service.get_dataframe(file_id)
            if df is None:
                raise FileNotFoundError(f"No data found for file_id: {file_id}")

            # Basic information
            row_count, col_count = df.shape
            duplicate_rows = int(df.duplicated().sum())

            # Missing values
            missing_values = df.isnull().sum()
            missing_values_dict = missing_values[missing_values > 0].to_dict()

            # Descriptive statistics for numeric columns
            numeric_descriptive_stats = df.describe().to_dict()
            
            # Detailed stats for each column
            column_details = {}
            for col in df.columns:
                col_data = df[col]
                value_counts = col_data.value_counts().head(10).to_dict()
                # Convert numeric keys from value_counts to strings for Pydantic validation
                value_counts_str_keys = {str(k): v for k, v in value_counts.items()}
                
                column_details[col] = ColumnStats(
                    dtype=str(col_data.dtype),
                    missing_count=int(col_data.isnull().sum()),
                    unique_count=col_data.nunique(),
                    value_counts=value_counts_str_keys
                )

            return AnalysisResult(
                file_id=file_id,
                row_count=row_count,
                column_count=col_count,
                duplicate_rows=duplicate_rows,
                missing_values=missing_values_dict,
                summary_stats={
                    "descriptive": numeric_descriptive_stats,
                    "column_details": column_details
                },
                plot_urls={}  # Placeholder for plot generation logic
            )
        except Exception as e:
            # It's good practice to wrap the core logic in a try-except block
            # to catch unexpected errors and provide a clear message.
            raise RuntimeError(f"An unexpected error occurred during analysis: {e}")

