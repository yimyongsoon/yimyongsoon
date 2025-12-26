# Ubuntu VM 자동 생성

KVM/libvirt 환경에서 Ubuntu 24.04 VM을 cloud-init 기반으로 자동 생성합니다.

## 사용법

### 1. values.yml 수정

`files/values.yml`에서 VM 스펙 정의:

```yaml
vms:
  - name: ubuntu-web01
    ip: 172.30.1.42
    vcpus: 2
    memory_mb: 4096
    disk_gb: 50
    description: "Web Server 01"
```

### 2. 플레이북 실행

```bash
# venv 활성화
source venv/bin/activate

# VM 생성
ansible-playbook -i inventory.yml custom-playbooks/VMs/ubuntu/ubuntu-install.yml

# 특정 VM만 생성
ansible-playbook -i inventory.yml custom-playbooks/VMs/ubuntu/ubuntu-install.yml \
  --extra-vars '{"vms": [{"name": "ubuntu-test", "ip": "172.30.1.50", "vcpus": 1, "memory_mb": 2048, "disk_gb": 20}]}'
```

### 3. VM 접속

```bash
ssh gtckorea@172.30.1.42
# 비밀번호: group_vars/all.yml 참조
```

## 파일 구조

```
ubuntu/
├── ubuntu-install.yml                 # 메인 플레이북
├── files/
│   ├── values.yml                    # VM 스펙 정의
│   └── templates/
│       └── user-data-custom.j2       # cloud-init 커스텀 템플릿
└── README.md
```

## 커스터마이징

### cloud-init 템플릿 수정

`files/templates/user-data-custom.j2`에서 초기 설정 변경 가능:
- 추가 패키지 설치
- 사용자 계정 추가
- 네트워크 설정
- 초기 스크립트 실행

### 베이스 플레이북 변경

필요시 `../../../create_vms.yml`을 복사하여 수정 가능
