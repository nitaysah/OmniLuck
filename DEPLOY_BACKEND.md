# Deploy Backend to Google Cloud Run

To connect your live frontend to a live backend, we will deploy the Python app to **Google Cloud Run**.

## 1. Setup Google Cloud Infrastructure
Since you want to avoid local terminal commands, use the **[Google Cloud Shell](https://ssh.cloud.google.com/cloudshell/editor?project=celestial-fortune-7d9b4)** (it runs in your browser).

Copy and paste these commands into the Cloud Shell:

```bash
# 1. Set Project
gcloud config set project celestial-fortune-7d9b4

# 2. Enable Required Services
gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com

# 3. Create Artifact Registry (to store your app's processing container)
gcloud artifacts repositories create omniluck-repo --repository-format=docker --location=us-central1 --description="Backend Repository"

# 4. Grant Permissions to your GitHub Service Account
# (Replace 'github-deploy' with the exact name you gave your service account if different)
SA_EMAIL=$(gcloud iam service-accounts list --filter="displayName:github-deploy" --format="value(email)")

gcloud projects add-iam-policy-binding celestial-fortune-7d9b4 --member="serviceAccount:${SA_EMAIL}" --role="roles/run.admin"
gcloud projects add-iam-policy-binding celestial-fortune-7d9b4 --member="serviceAccount:${SA_EMAIL}" --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding celestial-fortune-7d9b4 --member="serviceAccount:${SA_EMAIL}" --role="roles/artifactregistry.writer"
```

## 2. Configure Environment Secrets
Your backend needs API keys (OpenWeather, etc.).
Go to **GitHub Repo > Settings > Secrets > Actions** and add these new secrets:

| Secret Name | Value |
| :--- | :--- |
| `GCP_PROJECT_ID` | `celestial-fortune-7d9b4` |
| `OPENWEATHER_API_KEY` | *(Your OpenWeather Key)* |
| `GROQ_API_KEY` | *(Your Groq Key)* |
| `GOOGLE_GENAI_API_KEY` | *(Your Gemini Key)* |

## 3. Deploy
Once steps 1 & 2 are done:
1.  Make a small change to the backend code (or just push the new workflow file I created).
2.  Watch the **Actions** tab in GitHub.
3.  When the `Deploy Backend` job finishes, click on it to find the **Service URL** (e.g., `https://omniluck-backend-xyz.a.run.app`).

## 4. Final Step: Connect Frontend
1.  Copy that new **Service URL**.
2.  Open `OmniLuck_Frontend_WebApp/api-client.js`.
3.  Update the `PROD_URL` variable with your new URL.
4.  Commit and Push. Your frontend will redeploy and connect to the live backend!
