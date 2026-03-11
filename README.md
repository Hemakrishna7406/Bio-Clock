<p align="center">
  <img src="assets/images/logo.png" alt="Bio-Clock Logo" width="120" />
</p>

<h1 align="center">🧬 Bio-Clock</h1>

<p align="center">
  <strong>Predictive Food Spoilage Intelligence — Powered by Amazon Nova Pro</strong>
</p>

<p align="center">
  <a href="#-mission">Mission</a> •
  <a href="#-technical-stack">Stack</a> •
  <a href="#-zero-cors-architecture">Zero-CORS Fix</a> •
  <a href="#-project-structure">Structure</a> •
  <a href="#-getting-started">Getting Started</a>
</p>

---

## 🎯 Mission

**Bio-Clock** is an AI-powered food freshness monitoring platform that predicts **Remaining Useful Life (RUL)** of perishable items using thermodynamic Q10 decay modeling. It combines real-time image analysis via **Amazon Rekognition** with high-fidelity reasoning from **Amazon Nova Pro** on **AWS Bedrock** to deliver actionable storage recommendations — reducing food waste at scale.

---

## 🏗 Technical Stack

| Layer | Technology |
|:--- |:--- |
| **Frontend** | Flutter Web (Dart) with Material 3, Riverpod, GoRouter |
| **Backend** | AWS Lambda (Python 3.10) — Single handler, all routes |
| **AI Engine** | **Amazon Bedrock (Nova Pro v1)** — High-fidelity reasoning |
| **Vision** | **Amazon Rekognition** — Multimodal Label & Freshness Detection |
| **Auth** | Amazon Cognito (User Pool + Identity Pool) |
| **Database** | Amazon DynamoDB (Single-table PK/SK design) |
| **Storage** | Amazon S3 (Encrypted image uploads) |
| **API** | Amazon API Gateway (REST, Lambda Proxy Integration) |
| **Hosting** | **AWS Amplify** (CI/CD Pipeline) |

---

## 🛡 Zero-CORS Architecture — The "Golden" Fix

Traditional browser-to-API setups often break on **CORS preflight** (`OPTIONS`) requests — a notorious blocker in Flutter Web ↔ Lambda integrations. Bio-Clock eliminates this entirely with a **Zero-CORS Lambda Proxy** pattern:



**How it works:**
- Every Lambda response flows through a centralized `create_response()` utility, injecting full CORS headers into every exit point.
- API Gateway is configured with `AddDefaultAuthorizerToCorsPreflight: false`, allowing `OPTIONS` requests to pass through without authentication hurdles.
- **Result:** No browser-side CORS blocks. No preflight failures. **Zero friction.**

```python
def create_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,PUT,DELETE',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(body, default=str)
    }
