        try:
            if self._validateGzipFile(_savePath):
                print(f"{_savePath} is a valid gzip file.")
            else:
                raise Exception(f"Invalid GZIP file: {_savePath}")
        except gzip.BadGzipFile:
            raise Exception(f"GZIP file is corrupted: {_savePath}")
        except Exception as e:
            raise Exception(f"Error validating GZIP file: {e}")
