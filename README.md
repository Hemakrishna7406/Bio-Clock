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
- Every Lambda response flows through a centralized `create_response()` utility, injecting full CORS headers.
- API Gateway is configured with `AddDefaultAuthorizerToCorsPreflight: false`, allowing `OPTIONS` requests to bypass authentication.
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
📂 Project Structure
Plaintext

Bio-Clock/
├── lib/                    # Flutter source code
│   ├── features/           # Feature modules (auth, scan, inventory, analytics)
│   ├── shared/             # Core services, themes, API client
│   └── main.dart           # App entry point
├── backend/                # AWS Lambda backend
│   ├── lambda_handler.py   # Main handler (Nova Pro + Zero-CORS)
│   ├── process_donation.py # Donation endpoint logic
│   ├── template.yaml       # SAM Infrastructure-as-Code
│   └── requirements.txt    # Python dependencies
├── web/                    # Flutter Web entry point
├── assets/                 # Brand assets & fresh icons
├── pubspec.yaml            # Flutter dependencies
└── README.md               # You are here
🚀 Getting Started
Prerequisites
Flutter SDK ≥ 3.0.0

AWS CLI (configured with us-east-1)

AWS SAM CLI

Run Locally (Frontend)
Bash

flutter pub get
flutter run -d chrome --web-renderer canvaskit
Test the Lambda Handshake
Verify the Nova Pro integration via CLI:

Bash

aws lambda invoke --function-name BioClockHandler \
  --payload file://docs/golden_test_payload.json \
  output.json && cat output.json
🧠 AI Pipeline & Fallback Logic
Vision: Rekognition extracts granular labels from the food image.

Analysis: Nova Pro (via Converse API) performs a multimodal analysis of the labels + context for shelf-life estimation.

Decay Modeling: Precises RUL (Remaining Useful Life) is calculated using the Q10 Thermodynamic Formula.

Resilience: If Bedrock throttles, a local Heuristics Database (50+ items) provides instant, fail-safe freshness verdicts.
---

### 📋 Final Sync Prompt for the New Repo

Now, run this in your terminal to move everything to the new repo perfectly:

```bash
# 1. Switch to the new repository link
git remote remove origin
git remote add origin https://github.com/Hemakrishna7406/Bio-Clock.git

# 2. Cleanup local build junk to keep the repo small
flutter clean
rm -rf .dart_tool/

# 3. Add your new README.md (save the code above into README.md first!)
git add .

# 4. Final Commit & Push
git commit -m "Final: Production-ready sync with creative README and Zero-CORS docs"
git push -u origin staging
