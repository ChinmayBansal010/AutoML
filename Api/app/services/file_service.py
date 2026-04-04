import pandas as pd
import io
from fastapi import UploadFile
from app.schemas.upload import UploadResponse
from vercel_blob import put

class FileService:
    async def save_and_summarize_file(self, file: UploadFile) -> UploadResponse:
        
        try:
            content = await file.read()
        except Exception as e:
            raise IOError(f"Could not read file: {e}")

        try:
            blob_result = put(
                file.filename, 
                content, 
                options={'access': 'public', 'add_random_suffix': True}
            )
            
            file_url = blob_result['url']
            
        except Exception as e:
            raise IOError(f"Could not upload file to Vercel Blob: {e}")

        try:
            file_stream = io.BytesIO(content)
            if file.filename.endswith('.csv'):
                df = pd.read_csv(file_stream)
            else:
                df = pd.read_excel(file_stream)
        except Exception as e:
            raise ValueError(f"Could not read or parse the file: {e}")

        dtypes = {col: str(dtype) for col, dtype in df.dtypes.items()}

        summary = UploadResponse(
            file_id=file_url,
            filename=file.filename,
            row_count=len(df),
            columns=df.columns.tolist(),
            column_dtypes=dtypes,
            sample_data=df.head().to_dict(orient='records')
        )

        return summary

    def get_dataframe(self, file_id: str) -> pd.DataFrame:
        
        file_url = file_id

        if not file_url:
            raise FileNotFoundError(f"File URL (file_id) is missing.")

        try:
            if file_url.endswith('.csv'):
                return pd.read_csv(file_url)
            else:
                return pd.read_excel(file_url)
        except Exception as e:
            raise ValueError(f"Could not read or parse the file from URL {file_url}: {e}")