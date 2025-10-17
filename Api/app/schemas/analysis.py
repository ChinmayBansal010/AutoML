from pydantic import BaseModel, Field, ConfigDict
from typing import List, Dict, Any, Optional
import math

class ColumnStats(BaseModel):
    """
    Defines the structure for detailed statistics of a single column.
    """
    dtype: str = Field(..., description="The data type of the column.")
    missing_count: int = Field(..., description="Number of missing (null) values in the column.")
    unique_count: int = Field(..., description="Number of unique values in the column.")
    value_counts: Dict[str, int] = Field(..., description="Top value counts for the column.")
    
    # Numeric stats
    min_value: Optional[float] = Field(None, description="Minimum value for numeric columns.")
    max_value: Optional[float] = Field(None, description="Maximum value for numeric columns.")
    mean: Optional[float] = Field(None, description="Mean value for numeric columns.")
    std: Optional[float] = Field(None, description="Standard deviation for numeric columns.")

    def sanitize(self):
        for field in ["min_value", "max_value", "mean", "std"]:
            value = getattr(self, field)
            if isinstance(value, float) and (math.isnan(value) or math.isinf(value)):
                setattr(self, field, None)
        return self


class AnalysisRequest(BaseModel):
    """
    Schema for requesting data analysis (e.g., column statistics, visualization data).
    """
    file_id: str
    target_column: Optional[str] = None


class AnalysisResponse(BaseModel):
    """
    Defines the response structure for the EDA (Exploratory Data Analysis) endpoint.
    """
    file_id: str = Field(..., description="Unique identifier for the analyzed file.")
    row_count: int = Field(..., description="Total number of rows in the dataset.")
    column_count: int = Field(..., description="Total number of columns in the dataset.")
    duplicate_rows: int = Field(..., description="Number of duplicate rows found.")
    missing_values_total: int = Field(..., description="Total number of missing values across the dataset.")
    
    summary_stats: Dict[str, ColumnStats] = Field(..., description="Detailed per-column statistics.")
    visualizations: Dict[str, Any] = Field(..., description="Raw data for client-side plotting.")
    target_column_analysis: Optional[Dict[str, Any]] = Field(None, description="Target column analysis data.")

    model_config = ConfigDict(
        json_encoders={
            float: lambda v: None if (isinstance(v, float) and (math.isnan(v) or math.isinf(v))) else v
        }
    )
