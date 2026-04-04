from fastapi import APIRouter, Depends, HTTPException, Query
from app.schemas.analysis import AnalysisRequest, AnalysisResponse
from app.services.analysis_service import AnalysisService
from app.core.security import get_current_user
from urllib.parse import unquote

router = APIRouter()

@router.get("/preview/{file_id:path}", dependencies=[Depends(get_current_user)])
def get_data_preview(
    file_id: str,
    service: AnalysisService = Depends(),
):
    try:
        # URL decode the file_id (in case it contains special characters like :// )
        decoded_file_id = unquote(file_id)
        return service.get_data_preview(decoded_file_id)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/visualize/{file_id:path}")
def get_visualization_data(
    file_id: str,
    col1: str = Query(..., description="The primary column to analyze."),
    col2: str = Query(None, description="The secondary column for comparison (e.g., scatter plot)."),
    service: AnalysisService = Depends(),
    user: dict = Depends(get_current_user)
):
    """
    Generates data for visualization based on selected columns.
    - For a single column, it provides stats and chart data (histogram/bar or pie).
    - If two numeric columns are provided, it also returns data for a scatter plot.
    """
    try:
        # URL decode the file_id
        decoded_file_id = unquote(file_id)
        return service.get_visualization_data(decoded_file_id, col1, col2)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/eda/{file_id:path}", response_model=AnalysisResponse, dependencies=[Depends(get_current_user)])
def generate_eda(
    file_id: str,
    target_column: str = Query(None, description="The column to be used as the prediction target."),
    service: AnalysisService = Depends(),
):
    try:
        # URL decode the file_id
        decoded_file_id = unquote(file_id)
        return service.generate_eda_report(decoded_file_id, target_column)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))