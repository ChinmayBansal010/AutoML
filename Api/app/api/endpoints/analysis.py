from fastapi import APIRouter, Depends, HTTPException
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


@router.get("/eda/{file_id}", response_model=AnalysisResponse)
def generate_eda(
    file_id: str,
    service: AnalysisService = Depends()
):
    try:
        return service.generate_eda_report(file_id)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))