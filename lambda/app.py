import os
import logging
import boto3
import pymysql

logger = logging.getLogger()
logger.setLevel(logging.INFO)

region = os.environ["APP_REGION"]
proxy_endpoint = os.environ["DB_PROXY_ENDPOINT"]
db_name = os.environ["DB_NAME"]
db_user = os.environ["DB_USER"]

rds = boto3.client("rds", region_name=region)


def get_iam_token():
    return rds.generate_db_auth_token(
        DBHostname=proxy_endpoint,
        Port=3306,
        DBUsername=db_user,
        Region=region,
    )


def handler(event, context):
    logger.info(f"Connecting to proxy: {proxy_endpoint}")

    token = get_iam_token()
    logger.info("IAM token generated.")

    # MUST USE THIS FORMAT
    ssl_ca = "/var/task/global-bundle.pem"
    ssl_args = {"ca": ssl_ca}

    try:
        conn = pymysql.connect(
            host=proxy_endpoint,
            user=db_user,
            password=token,
            port=3306,
            db=db_name,
            ssl=ssl_args,
            connect_timeout=5,
        )
    except Exception as e:
        logger.exception("MySQL connect failed")
        return {"statusCode": 500, "body": f"CONNECT_ERROR: {repr(e)}"}

    try:
        with conn.cursor() as cur:
            cur.execute("SELECT CURRENT_USER(), NOW();")
            row = cur.fetchone()
        conn.close()
    except Exception as e:
        logger.exception("MySQL query failed")
        return {"statusCode": 500, "body": f"QUERY_ERROR: {repr(e)}"}

    return {"statusCode": 200, "body": str(row)}
