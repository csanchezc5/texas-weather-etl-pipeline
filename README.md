# Texas Weather ETL Pipeline

Pipeline ETL serverless en AWS que extrae datos de clima en tiempo real para Texas desde la API pública de [Open-Meteo](https://open-meteo.com/), los procesa y los almacena de forma automática cada 24 horas. Toda la infraestructura está definida como código (IaC) con Terraform.

## Arquitectura

```
 EventBridge (cron, cada 24h)
        │
        ▼
   AWS Lambda  ──────►  Open-Meteo API
 (Extract_Texas_Climate)   (clima actual)
        │
        ▼
   DynamoDB (TexasWeather)
```

1. **Amazon EventBridge** dispara un evento programado cada 24 horas.
2. **AWS Lambda** (`Extract_Texas_Climate`) se ejecuta, consulta la API de Open-Meteo para las coordenadas de Dallas, TX, y convierte la temperatura de Celsius a Fahrenheit.
3. El resultado se guarda como un nuevo ítem en **Amazon DynamoDB** (tabla `TexasWeather`), con la fecha/hora como clave.

## Stack técnico

| Componente | Servicio / Herramienta |
|---|---|
| Infraestructura como código | Terraform |
| Cómputo | AWS Lambda (Python 3.9) |
| Base de datos | Amazon DynamoDB |
| Orquestación / scheduling | Amazon EventBridge |
| Permisos | IAM Role + Policies (`AWSLambdaBasicExecutionRole`, `AmazonDynamoDBFullAccess`) |
| Fuente de datos | [Open-Meteo API](https://open-meteo.com/) (gratuita, sin API key) |

## Estructura del repositorio

```
.
├── main.tf              # Definición de toda la infraestructura AWS
├── lambda_code/
│   └── lambda_function.py   # Código de la función Lambda (extracción + transformación)
├── .gitignore
└── README.md
```

## Cómo desplegarlo

**Requisitos previos:**
- Cuenta de AWS con credenciales configuradas (`aws configure`)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) instalado
- Python 3.9 (solo si quieres probar la función localmente)

**Pasos:**

```bash
# 1. Clonar el repositorio
git clone https://github.com/csanchezc5/texas-weather-etl-pipeline.git
cd texas-weather-etl-pipeline

# 2. Inicializar Terraform
terraform init

# 3. Revisar el plan de ejecución
terraform plan

# 4. Aplicar la infraestructura
terraform apply
```

Esto crea automáticamente:
- El rol IAM y sus políticas
- La función Lambda (empaquetada desde `lambda_code/`)
- La tabla DynamoDB
- La regla de EventBridge y su permiso de invocación

## Resultado

Cada 24 horas se agrega un nuevo registro a la tabla `TexasWeather` con este formato:

| fecha | temperatura_c | temperatura_f |
|---|---|---|
| 2026-09-11 09:53:27 | 26.7 | 80.06 |

## Mejoras futuras

- Notebook de análisis con pandas para visualizar tendencias de temperatura a lo largo del tiempo
- Alarmas de CloudWatch para notificar fallos en la ejecución de la Lambda
- Manejo de reintentos ante fallos de la API externa

## Autor

**Christian Sanchez** — Estudiante de Ingeniería, enfocado en Data & Cloud Engineering
[GitHub](https://github.com/csanchezc5)