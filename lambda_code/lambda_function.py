import json
import urllib.request
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('TexasWeather')

def lambda_handler(event, context):
    url = "https://api.open-meteo.com/v1/forecast?latitude=32.7767&longitude=-96.7970&current_weather=true"
    
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            
        celsius = data['current_weather']['temperature']
        fahrenheit = (celsius * 9/5) + 32
        fecha_actual = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        
        table.put_item(
            Item={
                'fecha': fecha_actual,
                'temperatura_c': str(celsius),
                'temperatura_f': str(round(fahrenheit, 2))
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps('Datos guardados exitosamente')
        }
        
    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error en el pipeline ETL')
        }