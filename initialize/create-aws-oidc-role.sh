#!/bin/bash

# エラーが発生したらスクリプトを終了
set -e

# 変数設定
GITHUB_ORG="${1:-kf3225}"
GITHUB_REPO="${2:-kf-data-lakehouse}"

echo "GITHUB_ORG: $GITHUB_ORG"
echo "GITHUB_REPO: $GITHUB_REPO"

# ログ出力関数
log_error() {
    echo "エラー: $1" >&2
}

# 関数: クリーンアップ処理
cleanup() {
    echo "クリーンアップを実行中..."
    if [ -f trust-policy.json ]; then
        echo "trust-policy.jsonを削除します。"
        rm trust-policy.json
    fi
}

# エラーが発生した場合にクリーンアップを実行
trap cleanup ERR

# AWS Account IDの取得
echo "AWS Account IDを取得中..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ "$?" -ne 0 ]; then
    log_error "AWS Account IDの取得に失敗しました。"
    exit 1
fi
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# 1. OIDCプロバイダーの作成
echo "OIDCプロバイダーを作成中..."
if ! aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 1c58a3a8518e8759bf075b76b750d4f2df264fcd; then
    log_error "OIDCプロバイダーの作成に失敗しました。"
    exit 1
fi

# 2. 信頼ポリシーの作成
echo "信頼ポリシーを作成中..."
cat <<EOF >trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

# 3. IAMロールの作成
echo "IAMロールを作成中..."
if ! aws iam create-role \
    --role-name GitHubActionsDeployRole \
    --assume-role-policy-document file://trust-policy.json; then
    log_error "IAMロールの作成に失敗しました。"
    exit 1
fi

# 4. 権限ポリシーのアタッチ
echo "権限ポリシーをアタッチ中..."
if ! aws iam attach-role-policy \
    --role-name GitHubActionsDeployRole \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess; then
    log_error "権限ポリシーのアタッチに失敗しました。"
    exit 1
fi

# 成功した場合のクリーンアップ
cleanup

echo "セットアップが完了しました。"
