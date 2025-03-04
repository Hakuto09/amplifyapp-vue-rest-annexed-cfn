import json
import boto3
from datetime import datetime, timezone, timedelta
from zoneinfo import ZoneInfo
from decimal import Decimal


# バックエンド環境名
ENV = 'test'
print('ENV ', ENV)

STORAGE_DB_DDATA = 'amplifyappvuerest-' + ENV + '_ddata'
print('STORAGE_DB_NAME ', STORAGE_DB_DDATA)

# boto3 IoT Core 初期化
client_iot = boto3.client('iot')

# boto3 DynamoDB 初期化
resource_ddb = boto3.resource("dynamodb")
ddb_table_ddata = resource_ddb.Table(STORAGE_DB_DDATA)
#client_ddb = boto3.client('dynamodb')


def lambda_handler(event, context):
    print("lambda_handler() In.")
    print("event: ", event)

#    print("event[payload]: " + event["payload"])
    payload_type = event["payload"]["type"]
    print("payload_type: ", payload_type)
#    print("event[payload][value]: " + event["payload"]["value"])
    received = event["received"]
    print("received: ", received)
    id = event["id"]
    print("id: ", id)
    source = event["source"]
    print("source: ", source)
    type = event["type"]
    print("type: ", type)
    version = event["version"]
    print("version: ", version)
#    print("event[device]: " + event["device"])
    device_iccid = event["device"]["iccid"]
    print("device_iccid: ", device_iccid)
    device_ip = event["device"]["ip"]
    print("device_ip: ", device_ip)
    device_imsi = event["device"]["imsi"]
    print("device_imsi: ", device_imsi)

    device_ip_array4 = device_ip.split('.')
    print("device_ip_array4: ", device_ip_array4)
    device_ip_padding = device_ip_array4[0].zfill(3) + device_ip_array4[1].zfill(3) + device_ip_array4[2].zfill(3) + device_ip_array4[3].zfill(3)
    print("device_ip_padding: ", device_ip_padding)
    thingName = device_iccid + '_' + device_ip_padding
    print("thingName: ", thingName)

    if source == 'UDP' or source == 'COAP' :
        temperature = event["payload"]["value"]["temperature"]
    if source == 'LWM2M' :
        temperature = event["payload"]["value"]["/3303/0/5700"]
    print("temperature: ", str(temperature))


    ### デバイス名からthingIdの取得 ###
    # デバイス情報の取得
    res_iot_thing = client_iot.describe_thing(
        thingName = thingName,
    )
    print('After client_iot.describe_thing():', ' res_iot_thing ', res_iot_thing)

    # デバイスIDの取得
    device_id = res_iot_thing.get('thingId')
    print('After response_iot_thing.get(thingId):', ' device_id ', device_id)

    ### 日時形式の変換、タイムゾーンの設定 ###
    JST = timezone(timedelta(hours=+9), 'JST')
    datetime.now(JST)
    dt = datetime.fromtimestamp(int(received) / 1000, JST)
    print('After datetime fromtimestamp:', ' dt ', dt)
    dt_iso = dt.isoformat(timespec="milliseconds")
    print('After datetime isoformat:', ' dt_iso ', dt_iso)
    
    ### Dynamo DBへのデバイスデータの書き込み ###
    item = {
        "device_id": device_id,
        "createdAt": dt_iso,
        "createdAt_c": dt_iso,
        "data0": Decimal(str(temperature)),
        "source": source,
    }
    
    res_ddb = ddb_table_ddata.put_item(
        Item = item
    )
    print('After ddb_table_ddata.put_item():', ' res_ddb ', res_ddb, ' item ', item)
    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
