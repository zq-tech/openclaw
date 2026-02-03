#!/bin/bash
set -e

# ========================================
# OpenClaw Cloud Run Deployment Script
# ========================================

# Configuration
PROJECT_ID="affable-context-486313-h8"
REGION="europe-west1"
SERVICE_NAME="openclaw"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Environment Variables
OPENCLAW_GATEWAY_TOKEN="clawcloud"
OPENCLAW_GATEWAY_PASSWORD="clawcloud123"

# Resource Configuration
MEMORY="1Gi"
CPU="1"
MIN_INSTANCES="0"
MAX_INSTANCES="10"
TIMEOUT="300"

echo "========================================="
echo "Deploying OpenClaw to Cloud Run"
echo "========================================="
echo "Project ID: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Service Name: ${SERVICE_NAME}"
echo "========================================="

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed!"
    echo ""
    echo "Please install gcloud CLI first:"
    echo "  macOS: brew install google-cloud-sdk"
    echo "  Or visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Step 1: Set the project
echo ""
echo "📦 Step 1: Setting GCP project..."
gcloud config set project ${PROJECT_ID}

# Step 2: Enable required APIs
echo ""
echo "🔧 Step 2: Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Step 3: Build and push the Docker image
echo ""
echo "🏗️  Step 3: Building Docker image..."
gcloud builds submit \
  --tag ${IMAGE_NAME} \
  --dockerfile Dockerfile.cloudrun \
  --timeout=20m

# Step 4: Deploy to Cloud Run
echo ""
echo "🚀 Step 4: Deploying to Cloud Run..."
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --port 8080 \
  --set-env-vars "OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN},OPENCLAW_GATEWAY_PASSWORD=${OPENCLAW_GATEWAY_PASSWORD}" \
  --memory ${MEMORY} \
  --cpu ${CPU} \
  --min-instances ${MIN_INSTANCES} \
  --max-instances ${MAX_INSTANCES} \
  --timeout ${TIMEOUT}

# Step 5: Get the service URL
echo ""
echo "✅ Deployment complete!"
echo ""
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --format 'value(status.url)')

echo "========================================="
echo "🎉 OpenClaw is now running!"
echo "========================================="
echo "Service URL: ${SERVICE_URL}"
echo ""
echo "Test the service:"
echo "  curl ${SERVICE_URL}"
echo ""
echo "View logs:"
echo "  gcloud run services logs tail ${SERVICE_NAME} --region ${REGION}"
echo ""
echo "Update environment variables:"
echo "  gcloud run services update ${SERVICE_NAME} --region ${REGION} --set-env-vars KEY=VALUE"
echo "========================================="
