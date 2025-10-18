from fastapi import APIRouter, Depends, HTTPException, Query
from app.schemas.analysis import AnalysisRequest, AnalysisResponse
from app.services.analysis_service import AnalysisService

router = APIRouter()

@router.get("/preview/{file_id}")
def get_data_preview(
    file_id: str,
    service: AnalysisService = Depends()
):
    try:
        return service.get_data_preview(file_id)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/visualize/{file_id}")
def get_visualization_data(
    file_id: str,
    col1: str = Query(..., description="The primary column to analyze."),
    col2: str = Query(None, description="The secondary column for comparison (e.g., scatter plot)."),
    service: AnalysisService = Depends()
):
    """
    Generates data for visualization based on selected columns.
    - For a single column, it provides stats and chart data (histogram/bar or pie).
    - If two numeric columns are provided, it also returns data for a scatter plot.
    """
    try:
        return service.get_visualization_data(file_id, col1, col2)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/eda/{file_id}", response_model=AnalysisResponse)
def generate_eda(
    file_id: str,
    target_column: str = Query(None, description="The column to be used as the prediction target."),
    service: AnalysisService = Depends()
):
    try:
        # Pass the target_column to the service
        return service.generate_eda_report(file_id, target_column)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))