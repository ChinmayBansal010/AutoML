from fastapi import APIRouter, HTTPException, Depends, Path
from app.services.analysis_service import AnalysisService
from app.schemas.analysis import AnalysisResult

router = APIRouter()

@router.get("/{file_id}", response_model=AnalysisResult)
async def get_analysis(
    file_id: str = Path(..., description="The unique ID of the uploaded file."),
    analysis_service: AnalysisService = Depends()
):
    """
    Performs a detailed Exploratory Data Analysis (EDA) on the specified file.
    
    - **Checks for**: Missing values, duplicate rows, and data types of each column.
    - **Calculates**: Descriptive statistics (mean, std, min, max, etc.) for numerical columns.
    - **Calculates**: Value counts for categorical columns.
    - **Generates**: Correlation matrices and other plots.
    - **Returns**: A JSON object with the full analysis and links to generated plots.
    """
    try:
        # Delegate the logic of performing the analysis to the AnalysisService
        result = analysis_service.generate_eda_report(file_id)
        if not result:
            raise HTTPException(status_code=404, detail="Analysis could not be generated. File ID may be invalid.")
        return result
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail=f"Analysis failed: File with ID '{file_id}' not found.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred during analysis: {str(e)}")
