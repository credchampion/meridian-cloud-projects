import json
import logging
import uuid

import azure.functions as func

app = func.FunctionApp()

CONTAINER_PREFIX = "/blobServices/default/containers/claims-uploads/blobs/"


def build_log_row(subject: str, data: dict, event_time: str) -> dict:
    blob_path = subject.replace(CONTAINER_PREFIX, "", 1)
    parts = blob_path.split("/")
    claim_number = parts[0] if len(parts) > 1 else "UNASSIGNED"
    file_name = parts[-1]
    return {
        "PartitionKey": claim_number,
        "RowKey": uuid.uuid4().hex,
        "FileName": file_name,
        "FileType": data.get("contentType", "unknown"),
        "SizeBytes": data.get("contentLength", 0),
        "UploadedAtUtc": event_time,
    }


@app.event_grid_trigger(arg_name="event")
@app.table_output(arg_name="logrow", table_name="claimlog", connection="ClaimsStorage")
def log_claim_upload(event: func.EventGridEvent, logrow: func.Out[str]) -> None:
    event_time = event.event_time.isoformat() if event.event_time else ""
    row = build_log_row(event.subject, event.get_json(), event_time)
    logrow.set(json.dumps(row))
    logging.info("Logged %s for claim %s", row["FileName"], row["PartitionKey"])
