```sh
# download bastion, private ssh key from the google cloud storage
# and mode change
$  gsutil -m cp \
  "gs://prod_ludo_ssh_keys_cloud_bucket_storage/prod_bastion_ssh_key.pem" \
  "gs://prod_ludo_ssh_keys_cloud_bucket_storage/prod_private_ssh_key.pem" \
  .
$ chmod 0400 *.pem

# register the ssh keys
$ ssh-add *.pem

# connect to bastion host in ssh agent mode(ssh-key forwarding)
$ ssh -A ludo@<bastion-ip>

# =========BASTION HOST=========

# connect to application load balancer instance
$ ssh ludo@10.0.1.2
$ docker exec -it alb bash

# connect to spring application instance
$ ssh ludo@10.0.2.2
$ docker exec -it app bash
# health check for spring app
$ curl localhost:80/api/health
# inside docker

# connect to mysql database instance
$ ssh ludo@10.0.3.2
$ docker exec -it mysql mysql -uroot -p
```

# health check from alb instance to app instance

```sh
# connect to bastion host
$ ssh ludo@<bastion ip>

# connect to application load balancer
$ ssh ludo@10.0.1.2

# health check
$ curl 10.0.2.2:80/api/health
OK

# inside docker
$ docker exec -it alb bash
$ curl 10.0.2.2:80/api/health
OK
```

---

# MySQL SSH Tunneling

MySQL이 private subnet에 존재하여 외부에서 접근 불가하기 때문에

SSH Tunneling을 사용해야 합니다.

위와 중복되지만 전체 스크립트를 남겨 두겠습니다.

```sh
# 1. google-cloud-storage에서 다운로드
$ gsutil -m cp \
  "gs://prod_ludo_ssh_keys_cloud_bucket_storage/prod_bastion_ssh_key.pem" \
  "gs://prod_ludo_ssh_keys_cloud_bucket/prod_private_ssh_key.pem" \
  .

# 2. 다운로드 받은 pem key 2개 mode 제한
$ chmod 0400 *.pem

# 3. 기존 ssh agent에 등록된 key 제거(너무 많으면 오류 발생 가능)
$ ssh-add -D

# 4. ssh-key agent에 등록
$ ssh-add *.pem

# 5. ssh agent 등록 확인
$ ssh-add -l

# 6. ssh tunneling. local port 10000로 접속 시 port forwarding + detached mode
# localhost:10000에서 ludo@<bastion_ip>를 터널링하여 10.0.3.2:3306에 접속
$ ssh -L 10000:10.0.3.2:3306 -N ludo@<bastion_ip> &

# 7. 다른 shell에서 tunneling 여부 확인
$ nc -zv 127.0.0.1 10000

# 8. mysql에 터널링을 통한 접속
$ mysql -h 127.0.0.1 -P 10000 -u <username> -p <password>
```

datagrip도 동일한 원리로 터널링을 통한 ssh 접속이 가능하며 자세하게 설명된 블로그가 있어서 첨부하였습니다.
글에서는 aws dns를 사용하는데 `10.0.3.2` internal ip로 대체하면 됩니다.

https://jojoldu.tistory.com/623

---

# 배포 순서

## 1. GCP 프로젝트 생성 및 Project ID 등의 메타 데이터 참조하기

## 2. Google Compute Engine 및 IAM API 활성화

GCP는 API 사용 전에 수동 활성화가 필요합니다. 프로젝트 단위인 것 같습니다.

<img width="1001" alt="image" src="https://github.com/user-attachments/assets/20e907d7-e0b3-4c82-8a16-a046175a89c0">

## 3. gcloud 설치 및 인증 + Service Account 생성, remote state bucket 수동 생성

```sh
$ gcloud auth login
```

gcp에서 gcloud를 다운받고 로컬에서 구글 로그인을 해둡니다.

terraform도 다운 받은 뒤에 현재 Repo의 `service_account` 폴더로 들어가서 `init` 및 `apply`를 적용합니다.

```sh
$ cd ./service_account
$ terraform init
$ terraform apply -auto-approve
```

배포용 service account resource만 생성됩니다.

terraform state를 저장하기 위한 bucket은 Cloud Storage에서 미리 만들어야 합니다.

AWS와 마찬가지로 bucket 이름이 전세계에서 고유해야 할겁니다. 아마도

<img width="1274" alt="image" src="https://github.com/user-attachments/assets/031913d6-bdd3-4313-b8a9-0c5fa7d7ec12">

여기에 terraform의 리소스 변경 히스토리가 저장되기 때문에 terraform destroy를 해도 날아가면 안 되서 remote state bucket 만큼은
terraform으로 관리를 하지 않아서 따로 생성하는 것이며, 이 remote state 저장용 bucket 이름이 root dir의 `provider` 내에 `backend`에 들어갑니다.
반드시 bucket과 이름을 맞춰줘야 합니다.
또한 prod, stage 상관 없이 동일 bucket 공유하는 구조입니다. 동일 bucket 안에 prod/default.tfstate, stage/default.tfstate로 저장됩니다.

<img width="682" alt="image" src="https://github.com/user-attachments/assets/c3f33c21-0ec7-4e62-8849-8a8a06835528">

## 4. Infra Repo에 Github Actions Variables, Secrets 등록

Github Action의 Repository -> Settings -> Actions에서 Variables 등록 필요합니다.

<img width="884" alt="image" src="https://github.com/user-attachments/assets/c355c9e1-3db1-4c2a-8379-5953a578a3e4">

마찬가지로 Secrets도 등록 필요합니다.

<img width="871" alt="image" src="https://github.com/user-attachments/assets/4b5f93f6-24f0-4923-8a4a-32ad2ed0951b">

`GCP_SA_KEY`는 terraform에 의해 provisioning 되는 Service Account 중 terraform-deployer에 들어가서 add key를 하면 json 파일이 다운로드 됩니다.(방금 `terraform`으로 만든 그 service account입니다.)

이를 Github Actions Secrets에 복붙해서 넣어주면 됩니다.

<img width="357" alt="image" src="https://github.com/user-attachments/assets/93107e80-3b66-4287-819b-f3850a6066c6">

<img width="1130" alt="image" src="https://github.com/user-attachments/assets/2e735d18-3294-4da4-80fe-ae5408f30fd5">

<img width="869" alt="image" src="https://github.com/user-attachments/assets/3ab35ecc-dc6d-46c3-81f5-9bf0b6f02ade">

## 5. 현재 repo의 root dir에서 다음 명령어를 실행합니다.

```sh
$ terraform init \
          -backend-config="bucket=ludo-terraform-state-bucket-storage" \
          -backend-config="prefix=ludo/prod/terraform.tfstate"
```

`npm init`과 비슷하게 remote bucket으로 부터 상태를 불러와서 초기화 합니다.
aws 등의 provider 다운로드 및 `.lock` 파일이 생기며, 이제 `terraform apply` 등을 사용할 수 있습니다.

초기 or 환경이 변경될 때마다 실행해줘야 합니다.

`-backend-config="prefix=ludo/ {prod} /terraform`

중괄호로 강조한 이 부분이 환경에 맞춰 변경되어야 합니다.

예를 들어 초기 실행 시에 `prod`로 설정한다면

```sh
$ terraform init \
          -backend-config="bucket=ludo-terraform-state-bucket-storage" \
          -backend-config="prefix=ludo/prod/terraform.tfstate"
```

먼저 위 명령어 실행을 하고 `apply` 등으로 배포 작업을 합니다.

그러다 `test` 환경으로 전환하고 싶으면

`prefix`를 `ludo/test/...`로 바꿔서 다시 초기화를 해야 합니다.

```sh
$ terraform init \
          -backend-config="bucket=ludo-terraform-state-bucket-storage" \
          -backend-config="prefix=ludo/test/terraform.tfstate"
```

terraform의 workspace를 사용하거나 디렉토리 구조를 환경 별로 나누고 symlink를 통해 재활용하는 대신 가장 심플하게 하나의 파일을 여러 환경에서 공유하는 방법을 선택했기 때문에, remote 상태 자체가 여러 bucket에서 관리 되어야 하여 그렇습니다.

참고로 terraform workspace는 많은 전문가들이 비추천 하고,(마치 profile처럼 나눠서 사용 가능)
현업에서는 환경/리전 별 디렉토리 구조화를 통한 방법이 권장되는 것 같습니다.

## 6. apply

```sh
$ terraform apply -var="env=prod" -auto-approve --parallelism=10
```

`-var`은 환경 변수를 주입합니다. `env`를 `prod` 던 `stage` 던 하나는 주입해야 합니다.

`-auto-approve`는 `apply` 시에 안전을 위해 생성될 리소스를 확인한 뒤 `yes`를 입력해야 하는데, 이를 생략하게 해줍니다.
자동화 해야 해서 추가했으나 local에서는 확인하는 것이 좋습니다.

`--parallelism=10`은 동시 실행할 병렬 task 수입니다. 리소스가 많아지면 속도 향상 용으로 쓰면 됩니다. default는 10입니다.

이렇게 로컬에서는 gcloud로 리소스 프로비저닝을 실행하면 되며, github action에서는 배포용 service account를 통해 배포합니다.

배포는 infra repo에서 수동으로 진행됩니다.

<img width="1397" alt="image" src="https://github.com/user-attachments/assets/a6164a8d-1c0c-4df7-9c86-be6e5a15bcfb">

spring repo가 docker image build 및 docker hub push까지 담당하며 infra에서는 provisioning 후 docker hub로부터 container image를 다운로드 받아 실행합니다.

<img width="1388" alt="image" src="https://github.com/user-attachments/assets/d99e4f12-e418-403f-8830-8bb6a1f3d435">

배포 후에는 bastion host, alb는 external ip가 존재하지만 spring, db instance는 private subnet에 존재하기 때문에 반드시 ssh key forwarding을 통해 bastion host를 통해서 접속해야 합니다.

<img width="1317" alt="image" src="https://github.com/user-attachments/assets/9a421292-7f3c-4fe6-912e-88ac05b548dd">
