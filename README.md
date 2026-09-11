# Texas Weather ETL Pipeline

A serverless ETL pipeline on AWS that extracts real-time weather data for Texas from the [Open-Meteo](https://open-meteo.com/) public API, processes it, and stores it automatically every 24 hours. The entire infrastructure is defined as code (IaC) using Terraform.

## Architecture

```
 EventBridge (cron, every 24h)
        │
        ▼
   AWS Lambda  ──────►  Open-Meteo API
 (Extract_Texas_Climate)  (current weather)
        │
        ▼
   DynamoDB (TexasWeather)
```

1. **Amazon EventBridge** triggers a scheduled event every 24 hours.
2. **AWS Lambda** (`Extract_Texas_Climate`) runs, queries the Open-Meteo API for Dallas, TX coordinates, and converts the temperature from Celsius to Fahrenheit.
3. The result is saved as a new item in **Amazon DynamoDB** (`TexasWeather` table), using the timestamp as the key.

## Tech Stack

| Component | Service / Tool |
|---|---|
| Infrastructure as Code | Terraform |
| Compute | AWS Lambda (Python 3.9) |
| Database | Amazon DynamoDB |
| Orchestration / Scheduling | Amazon EventBridge |
| Permissions | IAM Role + Policies (`AWSLambdaBasicExecutionRole`, `AmazonDynamoDBFullAccess`) |
| Data Source | [Open-Meteo API](https://open-meteo.com/) (free, no API key required) |

## Repository Structure

```
.
├── main.tf              # Full AWS infrastructure definition
├── lambda_code/
│   └── lambda_function.py   # Lambda function code (extraction + transformation)
├── .gitignore
└── README.md
```

## Deployment

**Prerequisites:**
- AWS account with configured credentials (`aws configure`)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed
- Python 3.9 (only needed to test the function locally)

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
- The Lambda function (packaged from `lambda_code/`)
- The DynamoDB table
- The EventBridge rule and its invocation permission

## Sample Output

Every 24 hours, a new record is added to the `TexasWeather` table with this format:

| fecha (timestamp) | temperatura_c | temperatura_f |
|---|---|---|
| 2026-09-11 09:53:27 | 26.7 | 80.06 |

## Future Improvements

- Pandas-based analysis notebook to visualize temperature trends over time
- CloudWatch alarms to notify on Lambda execution failures
- Retry logic to handle external API failures

## Author

**Cristhian Sanchez** — Engineering student focused on Data & Cloud Engineering
[GitHub](https://github.com/csanchezc5)