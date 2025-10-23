import pandas as pd
import io
from fastapi import UploadFile
from app.schemas.upload import UploadResponse
from vercel_blob import put

# Note: The 'settings' import is no longer needed here, 
# as the vercel_blob library automatically reads the
# BLOB_READ_WRITE_TOKEN from the environment variables.

class FileService:
    async def save_and_summarize_file(self, file: UploadFile) -> UploadResponse:
        """
        Uploads a file to Vercel Blob and returns a summary.
        The file's public URL is used as the file_id.
        """
        
        try:
            # Read the file content into memory
            content = await file.read()
        except Exception as e:
            raise IOError(f"Could not read file: {e}")

        try:
            # Upload the file to Vercel Blob
            # 'access': 'public' makes it readable via the returned URL
            # add_random_suffix=True prevents filename collisions
            blob_result = put(
                file.filename, 
                content, 
                options={'access': 'public', 'add_random_suffix': True}
            )
            
            # Use the public URL as the new "file_id"
            file_url = blob_result['url']
            
        except Exception as e:
            # This will catch errors if the token is missing or invalid
            raise IOError(f"Could not upload file to Vercel Blob: {e}")

        try:
            # Create a DataFrame from the in-memory content for summarization
            file_stream = io.BytesIO(content)
            if file.filename.endswith('.csv'):
                df = pd.read_csv(file_stream)
            else:
                df = pd.read_excel(file_stream)
        except Exception as e:
            raise ValueError(f"Could not read or parse the file: {e}")

        dtypes = {col: str(dtype) for col, dtype in df.dtypes.items()}

        summary = UploadResponse(
            file_id=file_url,  # <-- We now use the URL as the ID
            filename=file.filename,
            row_count=len(df),
            columns=df.columns.tolist(),
            column_dtypes=dtypes,
            sample_data=df.head().to_dict(orient='records')
        )

        return summary

    def get_dataframe(self, file_id: str) -> pd.DataFrame:
        """
        Loads a pandas DataFrame from the provided URL (which is the file_id).
        """
        
        # The file_id is now the public URL of the file in Vercel Blob
        file_url = file_id

        if not file_url:
            raise FileNotFoundError(f"File URL (file_id) is missing.")

        try:
            # Pandas can read directly from a URL
            if file_url.endswith('.csv'):
                return pd.read_csv(file_url)
            else:
                # You might need to install 'openpyxl' for this to work
                return pd.read_excel(file_url)
        except Exception as e:
            raise ValueError(f"Could not read or parse the file from URL {file_url}: {e}")