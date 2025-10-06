""" 
This Lambda function returns a html page reading a parameter from the parameter store

Author: rriquelme
"""

import html
import os
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

_ssm = boto3.client("ssm", config=Config(retries={"max_attempts": 3}))
PARAM_NAME = os.getenv("PARAM_NAME", "/dynamic_string")

def handler(event, context):
    # Manage New String on query string
    try:
        new_dynamic_string = event.get("queryStringParameters", {}).get("newstring", "")
    except Exception:
        new_dynamic_string = None


    # Try to save it
    if new_dynamic_string is not None: # Maximum is 4096 characters
        # Edge case if string is empty (i.e. ?newstring=)
        if len(new_dynamic_string) == 0:
            new_dynamic_string = " "
        try:
            _ssm.put_parameter(Name=PARAM_NAME, Value=new_dynamic_string, Type="String", Overwrite=True)
            new_dynamic_string +=" (saved)"
        except ClientError as e:
            new_dynamic_string = f"(error saving parameter {PARAM_NAME}: {e.response.get('Error', {}).get('Message', 'unknown error')})"
            pass # Not handled
    
    # Get current value from parameter store
    try:
        resp = _ssm.get_parameter(Name=PARAM_NAME, WithDecryption=False)
        # Escape in case the source is user-editable (prevents XSS)
        message = html.escape(resp["Parameter"]["Value"])
    except ClientError as e:
        message = f"(error reading parameter {PARAM_NAME}: {e.response.get('Error', {}).get('Message', 'unknown error')})"

    html_body = f"<h1>The saved string is {message}</h1>"
    html_body += f"<p>{new_dynamic_string=}</p>"

    # Also be sure to not store cache in browser
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store, no-cache, must-revalidate"},
        "body": html_body,
    }
