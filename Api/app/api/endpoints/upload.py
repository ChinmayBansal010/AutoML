from fastapi import APIRouter, File, UploadFile, HTTPException, Depends
from app.services.file_service import FileService
from app.schemas.upload import UploadResponse

router = APIRouter()

@router.post("", response_model=UploadResponse)
async def upload_file(
    file: UploadFile = File(..., description="The dataset file to upload. Must be .xlsx, .xls, or .csv format."),
    file_service: FileService = Depends()
):
    """
    Accepts an Excel (.xlsx, .xls) or CSV (.csv) file upload.
    """
    if not file.filename.endswith(('.xlsx', '.xls', '.csv')):
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Please upload an Excel (.xlsx, .xls) or CSV (.csv) file."
        )

    try:
        summary = await file_service.save_and_summarize_file(file)
        return summary
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process file: {str(e)}")
