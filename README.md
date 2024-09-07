# kf-data-lakehouse

## CICD

### 概要

- IaCはterraformで管理するものとする
- `data-lakehouse`アカウントと`data-source`アカウントのデプロイを行う
- infra配下のソースコードでデプロイを行う
- `.github/workflows/deploy-infra.yml`によりCICDワークフローは管理される
- PR作成/変更時点で`terraform plan`までの実行が走る
- mainへのマージにより`terraform apply`が実行され、環境へのデプロイが行われる

### 前提

- secretsに`data-lakehouse`と`data-source`のAWSアカウントIDが登録されていること
  - `DATA_SOURCE_AWS_ACCOUNT_ID`: データソース用のアカウント
  - `DATA_LAKEHOUSE_AWS_ACCOUNT_ID`: レイクハウス用のアカウント
