# Texas Weather ETL Pipeline

A serverless ETL pipeline on AWS that extracts real-time weather data for Texas from the [Open-Meteo](https://open-meteo.com/) public API, stores it automatically every 24 hours, and exposes it through a public REST endpoint for consumption by BI tools like Power BI. The entire infrastructure is defined as code (IaC) using Terraform.

## Architecture

```
 EventBridge (cron, every 24h)
        │
        ▼
   AWS Lambda (Writer)  ──────►  Open-Meteo API
 (Extract_Texas_Climate)          (current weather)
        │
        ▼
   DynamoDB (TexasWeather)
        │
        ▼
   AWS Lambda (Reader)
   (Read_Texas_Climate)
        │
        ▼
   API Gateway (HTTP API)
        │
        ▼
   Public JSON endpoint ──────►  Power BI / any HTTP client
```

**Write path (automated, every 24h):**
1. **Amazon EventBridge** triggers a scheduled event every 24 hours.
2. **AWS Lambda** (`Extract_Texas_Climate`) runs, queries the Open-Meteo API for Dallas, TX coordinates, and converts the temperature from Celsius to Fahrenheit.
3. The result is saved as a new item in **Amazon DynamoDB** (`TexasWeather` table), using the timestamp as the key.

**Read path (on-demand, via HTTP):**
4. **AWS Lambda** (`Read_Texas_Climate`) scans the DynamoDB table and returns all records as JSON.
5. **Amazon API Gateway** (HTTP API) exposes this Lambda through a public `GET /weather` endpoint, ready to be consumed by external tools.

## Tech Stack

| Component | Service / Tool |
|---|---|
| Infrastructure as Code | Terraform |
| Compute | AWS Lambda (Python 3.9) — one function for writes, one for reads |
| Database | Amazon DynamoDB |
| Orchestration / Scheduling | Amazon EventBridge |
| Public API | Amazon API Gateway (HTTP API) |
| Permissions | IAM Role + Policies (`AWSLambdaBasicExecutionRole`, `AmazonDynamoDBFullAccess`) |
| Data Source | [Open-Meteo API](https://open-meteo.com/) (free, no API key required) |

## Repository Structure

```
.
├── main.tf                      # Full AWS infrastructure definition
├── lambda_code/
│   └── lambda_function.py       # Writer Lambda: fetches weather and saves to DynamoDB
├── lambda_code_reader/
│   └── lambda_reader.py         # Reader Lambda: scans DynamoDB and returns JSON
├── .gitignore
└── README.md
```

## Deployment

**Prerequisites:**
- AWS account with configured credentials (`aws configure`)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed
- Python 3.9 (only needed to test the functions locally)

**Steps:**

```bash
# 1. Clone the repository
git clone https://github.com/csanchezc5/texas-weather-etl-pipeline.git
cd texas-weather-etl-pipeline

# 2. Initialize Terraform
terraform init

# 3. Review the execution plan
terraform plan

# 4. Apply the infrastructure
terraform apply
```

This automatically creates:
- The IAM role and its policies
- The writer Lambda (packaged from `lambda_code/`) and the EventBridge schedule that triggers it
- The DynamoDB table
- The reader Lambda (packaged from `lambda_code_reader/`)
- The API Gateway HTTP API, route, and integration exposing the reader Lambda

After `apply`, Terraform prints the public endpoint:

```
api_endpoint = "https://xxxxx.execute-api.us-east-1.amazonaws.com/weather"
```

## Sample Output

**DynamoDB record** (written every 24 hours):

| fecha (timestamp) | temperatura_c | temperatura_f |
|---|---|---|
| 2026-09-11 17:45:34 | 35.0 | 95.0 |

**API response** (`GET /weather`):

```json
[{"temperatura_f": "95.0", "fecha": "2026-09-11 17:45:34", "temperatura_c": "35.0"}]
```

## Security Note

The API endpoint is currently public with no authentication, to keep the demo simple for BI tool consumption. In a production setting, this would be locked down with an API key or IAM-based authorization.

## Future Improvements

- Pandas-based analysis notebook to visualize temperature trends over time
- Power BI dashboard connected to the public endpoint
- CloudWatch alarms to notify on Lambda execution failures
- Retry logic to handle external API failures
- API key or authorizer to restrict access to the public endpoint

## Author

**Cristhian Sanchez** — Engineering student focused on Data & Cloud Engineering
[GitHub](https://github.com/csanchezc5)