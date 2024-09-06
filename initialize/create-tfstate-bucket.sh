#!/bin/bash

# AWS Account IDの取得
echo "AWS Account IDを取得中..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ "$?" -ne 0 ]; then
    log_error "AWS Account IDの取得に失敗しました。"
    exit 1
fi

echo "AWS Account ID: $AWS_ACCOUNT_ID"

BUCKET_NAME="kf-data-lakehouse-tfstate-$AWS_ACCOUNT_ID"

# バケット作成
if ! aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration "LocationConstraint=$AWS_REGION"; then
    echo "Failed to create bucket for tfstate"
    exit 1
fi

# バケットのサーバーサイド暗号化をオンにする
if ! aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'; then
    echo "Failed to encrypt bucket for tfstate"
    exit 1
fi

echo "Succeeded to create $BUCKET_NAME"
