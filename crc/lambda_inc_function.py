import boto3

dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')
table = dynamodb.Table('crc-counter')

def lambda_handler(event, context):
    cf_response = event['Records'][0]['cf']['response']
    counter_id = 'cv'

    if (counter_id):
        response = table.get_item(
            Key = {'CounterID': counter_id}
        )

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
        )['Item']['NumberOfHits']

    return cf_response

