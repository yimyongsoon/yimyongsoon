# KVM Ubuntu VM 자동 배포 (Ansible)

Rocky Linux 9 + KVM/libvirt 환경에서 Ubuntu 24.04 VM을 cloud-init 기반으로 자동 생성

## 사전 준비

### 1. KVM 호스트에서 실행
```bash
# Ansible 설치 (Rocky9 호스트에서)
dnf install -y ansible-core python3-pip

# Ansible 컬렉션 설치
ansible-galaxy collection install -r requirements.yml

# 브릿지 네트워크 확인
virsh net-list --all
# br0 네트워크가 있어야 함 (172.30.1.0/24)
```

### 2. 설정 파일 수정

#### inventory.yml
```yaml
kvm-host:
  ansible_host: <KVM_호스트_실제_IP>  # 변경 필요
```

#### vms.yml
- VM 이름, IP, CPU, 메모리, 디스크 크기 설정
- 필요한 만큼 VM 추가/제거

#### group_vars/all.yml
- `network_name: br0` → 실제 libvirt 네트워크 이름 확인
- SSH 키 사용 시 `vm_ssh_authorized_keys` 추가

### 3. 비밀번호 해시 생성 (선택사항)

기본 비밀번호는 `appviewx1`로 설정되어 있습니다.
변경하려면:

```bash
# KVM 호스트에서
python3 -c 'import crypt; print(crypt.crypt("새비밀번호", crypt.mksalt(crypt.METHOD_SHA512)))'
```

출력된 해시를 `templates/user-data.j2`의 `passwd:` 필드에 복사

## 사용법

### VM 생성
```bash
ansible-playbook -i inventory.yml create_vms.yml
```

### VM 삭제
```bash
ansible-playbook -i inventory.yml delete_vms.yml
```

### 특정 VM만 생성
```bash
ansible-playbook -i inventory.yml create_vms.yml --extra-vars '{"vms": [{"name": "ubuntu-web01", "ip": "172.30.1.42", "vcpus": 2, "memory_mb": 4096, "disk_gb": 50}]}'
```

## VM 접속

```bash
# SSH 접속
ssh gtckorea@172.30.1.42

# 비밀번호: appviewx1
```

## 주의사항

### 1. 네트워크 이름 확인
```bash
virsh net-list --all
virsh net-dumpxml <네트워크명>
```

`group_vars/all.yml`의 `network_name`을 실제 브릿지 이름으로 변경

### 2. os-variant 확인
```bash
osinfo-query os | grep -i ubuntu
```

Ubuntu 24.04가 없으면 `ubuntu22.04` 또는 `ubuntu20.04` 사용

### 3. 방화벽 설정
```bash
# Rocky9 호스트에서
firewall-cmd --permanent --add-service=libvirt
firewall-cmd --reload
```

### 4. br0 네트워크가 없는 경우

기존 `ubuntu_apache` VM의 네트워크 확인:
```bash
virsh dumpxml ubuntu_apache | grep "interface type"
virsh dumpxml ubuntu_apache | grep "source"
```

출력된 네트워크 또는 브릿지 이름을 사용

## 트러블슈팅

### cloud-init 로그 확인
```bash
# VM 내부에서
sudo cat /var/log/cloud-init.log
sudo cloud-init status
```

### 네트워크 미적용 시
```bash
# VM 내부에서
sudo netplan apply
sudo systemctl restart systemd-networkd
```

### VM 목록 확인
```bash
virsh list --all
```

### VM 삭제 (수동)
```bash
virsh destroy <VM명>
virsh undefine <VM명>
rm -f /var/lib/libvirt/images/<VM명>*
```

## 디렉토리 구조

```
kvm-ansible/
├── ansible.cfg           # Ansible 설정
├── inventory.yml         # KVM 호스트 정보
├── requirements.yml      # Ansible 컬렉션
├── vms.yml              # VM 스펙 정의 (여기만 수정하면 됨)
├── group_vars/
│   └── all.yml          # 공통 변수
├── templates/
│   ├── user-data.j2     # cloud-init 사용자 설정
│   └── meta-data.j2     # cloud-init 메타데이터
├── create_vms.yml       # VM 생성 플레이북
├── delete_vms.yml       # VM 삭제 플레이북
└── README.md
```

## 환경
- 호스트: Rocky Linux 9
- 하이퍼바이저: KVM/libvirt
- VM OS: Ubuntu Server 24.04
- 네트워크: 172.30.1.0/24 (br0)
- 사용자: gtckorea / appviewx1
