from pydantic import BaseModel, Field
from typing import List, Dict, Any

class UploadResponse(BaseModel):
    """
    Defines the response structure after a successful file upload.
    """
    file_id: str = Field(..., description="Unique identifier for the uploaded file.")
    filename: str = Field(..., description="Original name of the uploaded file.")
    row_count: int = Field(..., description="Total number of rows in the dataset.")
    columns: List[str] = Field(..., description="List of column names in the dataset.")
    # Add the missing field for column data types
    column_dtypes: Dict[str, str] = Field(..., description="Data types of each column.")
    sample_data: List[Dict[str, Any]] = Field(..., description="A small sample of the data (e.g., first 5 rows).")

