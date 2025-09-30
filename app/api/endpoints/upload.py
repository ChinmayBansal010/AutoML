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

    - **Saves** the file to a unique server-side location.
    - **Validates** the file type.
    - **Reads** the file to provide an initial summary (columns, row count, data sample).
    - **Returns** a unique `file_id` for referencing the dataset in subsequent API calls.
    """
    # Validate that the uploaded file has an accepted extension
    if not file.filename.endswith(('.xlsx', '.xls', '.csv')):
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Please upload an Excel (.xlsx, .xls) or CSV (.csv) file."
        )

    try:
        # Delegate the core logic of saving and summarizing to the FileService
        summary = await file_service.save_and_summarize_file(file)
        return summary
    except Exception as e:
        # Provide a generic but informative error response if file processing fails
        raise HTTPException(status_code=500, detail=f"Failed to process file: {str(e)}")
