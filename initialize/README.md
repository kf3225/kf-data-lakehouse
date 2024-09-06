# 初期構築手順メモ

## Github Actions用の認証ロール作成

### 概要

- Github ActionsからAWSアカウントの操作を行うためにIAM Roleを用意する
- OIDCによって認証を行い、操作権限を取得する

### 前提

- IAMを弄る権限のあるAccess Keyを取得できること
- OIDCプロバイダのthumbprintを取得していること(2024/09/06現在: [こちら](https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/)が最新)

    ```sh
    6938fd4d98bab03faadb97b34396831e3780aea1
    1c58a3a8518e8759bf075b76b750d4f2df264fcd
    ```

### 手順

1. AWSからAccess Keyを取得し環境変数へセットする

    ```sh
    export AWS_ACCESS_KEY_ID="文字列"
    export AWS_SECRET_ACCESS_KEY="文字列"
    export AWS_SESSION_TOKEN="文字列"
    export AWS_REGION="ap-northeast-1"
    ```

2. github actions用のIAM Roleを作成用Shellを実行する

    ```sh
    $ ./initialize/create-aws-oidc-role.sh
    GITHUB_ORG: kf3225
    GITHUB_REPO: kf-data-lakehouse
    AWS Account IDを取得中...
    AWS Account ID: 111122223333
    OIDCプロバイダーを作成中...
    {
        "OpenIDConnectProviderArn": "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
    }
    信頼ポリシーを作成中...
    IAMロールを作成中...
    {
        "Role": {
            "Path": "/",
            "RoleName": "GitHubActionsDeployRole",
            "RoleId": "AROA4MI2JKM6IFOF272YC",
            "Arn": "arn:aws:iam::111122223333:role/GitHubActionsDeployRole",
            "CreateDate": "2024-09-06T12:58:54+00:00",
            "AssumeRolePolicyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {
                            "Federated": "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
                        },
                        "Action": "sts:AssumeRoleWithWebIdentity",
                        "Condition": {
                            "StringEquals": {
                                "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                            },
                            "StringLike": {
                                "token.actions.githubusercontent.com:sub": "repo:kf3225/kf-data-lakehouse:*"
                            }
                        }
                    }
                ]
            }
        }
    }
    権限ポリシーをアタッチ中...
    クリーンアップを実行中...
    trust-policy.jsonを削除します。
    セットアップが完了しました。
    ```
