from pydantic import BaseModel, Field
from typing import Dict, Any

class ColumnStats(BaseModel):
    """
    Defines the structure for detailed statistics of a single column.
    """
    dtype: str = Field(..., description="The data type of the column.")
    missing_count: int = Field(..., description="Number of missing (null) values in the column.")
    unique_count: int = Field(..., description="Number of unique values in the column.")
    value_counts: Dict[str, int] = Field(..., description="Top value counts for the column.")

class AnalysisResult(BaseModel):
    """
    Defines the response structure for the EDA (Exploratory Data Analysis) endpoint.
    """
    file_id: str = Field(..., description="Unique identifier for the analyzed file.")
    row_count: int = Field(..., description="Total number of rows in the dataset.")
    column_count: int = Field(..., description="Total number of columns in the dataset.")
    duplicate_rows: int = Field(..., description="Number of duplicate rows found.")
    missing_values: Dict[str, int] = Field(..., description="Count of missing values per column.")
    
    # Update the summary_stats to use the new ColumnStats model
    summary_stats: Dict[str, Any] = Field(..., description="Descriptive statistics and detailed column info.")
    
    plot_urls: Dict[str, str] = Field(..., description="URLs to generated analysis plots (e.g., histograms, correlation matrix).")

