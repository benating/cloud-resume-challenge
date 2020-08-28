import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('crc-counter')

def lambda_handler(event, context):
    body = 'OK'
    counter_id = event.get('counter_id')

    if (event.get('path') == 'counter' and event.get('httpMethod') == 'GET' and counter_id):
        response = table.get_item(
            Key = {'CounterID': counter_id}
        )

        if (event.get('counter_action') == 'get'):
            body = response['Item'] if ('Item' in response) else 0

        elif (event.get('counter_action') == 'inc'):
            if ('Item' in response):
                table.update_item(
                    Key = {'CounterID': counter_id},
                    UpdateExpression='SET NumberOfHits = NumberOfHits + :val1',
                    ExpressionAttributeValues={
                        ':val1': 1
                    }
                )
            else:
                table.put_item(
                    Item = {
                        'CounterID': counter_id,
                        'NumberOfHits': 1
                    }
                )

            body = table.get_item(
                Key = {'CounterID': counter_id}
            )['Item']

    return {
        'statusCode': 200,
        'body': body
    }

