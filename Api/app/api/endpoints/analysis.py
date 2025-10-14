from fastapi import APIRouter, Depends, HTTPException
from app.schemas.analysis import AnalysisRequest, AnalysisResponse
from app.services.analysis_service import AnalysisService

router = APIRouter()

@router.post("", response_model=AnalysisResponse)
async def perform_analysis(
    request: AnalysisRequest,
    analysis_service: AnalysisService = Depends()
):
    """
    Performs preliminary data analysis (e.g., column distribution, correlations) 
    on an uploaded file.
    """
    try:
        analysis_result = analysis_service.run_analysis(request.file_id)
        return analysis_result
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
