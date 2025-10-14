import pandas as pd
import uuid
import os
import aiofiles
from fastapi import UploadFile
from app.core.config import settings
from app.schemas.upload import UploadResponse

class FileService:
    async def save_and_summarize_file(self, file: UploadFile) -> UploadResponse:
        """
        Saves an uploaded file and returns a summary including column data types.
        """
        file_id = str(uuid.uuid4())
        file_location = os.path.join(settings.UPLOADS_DIR, file_id)
        os.makedirs(file_location, exist_ok=True)

        file_path = os.path.join(file_location, file.filename)

        try:
            async with aiofiles.open(file_path, 'wb') as out_file:
                content = await file.read()
                await out_file.write(content)
        except Exception as e:
            raise IOError(f"Could not save file: {e}")

        try:
            if file.filename.endswith('.csv'):
                df = pd.read_csv(file_path)
            else:
                df = pd.read_excel(file_path)
        except Exception as e:
            raise ValueError(f"Could not read or parse the file: {e}")

        dtypes = {col: str(dtype) for col, dtype in df.dtypes.items()}

        summary = UploadResponse(
            file_id=file_id,
            filename=file.filename,
            row_count=len(df),
            columns=df.columns.tolist(),
            column_dtypes=dtypes,
            sample_data=df.head().to_dict(orient='records')
        )

        return summary

    def get_dataframe(self, file_id: str) -> pd.DataFrame:
        """
        Loads the saved data file for a given file_id into a pandas DataFrame.
        """
        file_location = os.path.join(settings.UPLOADS_DIR, file_id)
        if not os.path.exists(file_location):
            raise FileNotFoundError(f"Directory for file_id {file_id} not found.")

        file_path = None
        for filename in os.listdir(file_location):
            if filename.endswith(('.csv', '.xlsx', '.xls')):
                file_path = os.path.join(file_location, filename)
                break

        if not file_path:
            raise FileNotFoundError(f"Data file not found in directory for file_id {file_id}.")

        try:
            if file_path.endswith('.csv'):
                return pd.read_csv(file_path)
            else:
                return pd.read_excel(file_path)
        except Exception as e:
            raise ValueError(f"Could not read or parse the file at {file_path}: {e}")

