# KVM Ubuntu VM 자동 배포 (Ansible)

Rocky Linux 9 + KVM/libvirt 환경에서 Ubuntu 24.04 VM을 cloud-init 기반으로 자동 생성

## 사전 설정 (Rocky9 KVM 호스트 root 계정)

### 1. 저장소 클론 (root로 실행)
```bash
# root로 전환
su -

# 저장소 클론
cd /home/gtckorea
git clone https://github.com/yimyongsoon/yimyongsoon.git
mv yimyongsoon workspaces

# 소유권 변경 (root로 통일)
chown -R root:root /home/gtckorea/workspaces

# git safe directory 설정
git config --global --add safe.directory /home/gtckorea/workspaces

cd workspaces/kvm-ansible
```

### 2. 시스템 패키지 설치 (libvirt가 없는 경우만)
```bash
# Ansible 설치 (없는 경우만)
dnf install -y epel-release
dnf install -y ansible-core

# KVM/libvirt가 없는 경우만 설치
dnf install -y python3-libvirt python3-lxml
dnf install -y libvirt libvirt-client qemu-kvm virt-install qemu-img
dnf install -y libguestfs-tools genisoimage
systemctl enable --now libvirtd
```

### 3. Ansible 컬렉션 설치
```bash
ansible-galaxy collection install -r requirements.yml
```

### 4. 네트워크 확인
```bash
# 기존 VM의 네트워크 확인
virsh domiflist <기존VM명>

# br0 브릿지 사용 확인 (Type: bridge, Source: br0)
# 다르면 group_vars/all.yml의 network_name 수정
```

### 5. 설정 파일 수정

#### inventory.yml
Rocky9에서 localhost로 실행하므로 수정 불필요 (기본값 사용)
```yaml
localhost:
  ansible_connection: local
```

#### vms.yml
- VM 이름, IP, CPU, 메모리, 디스크 크기 설정
- 필요한 만큼 VM 추가/제거

#### group_vars/all.yml
- `network_name: br0` → 실제 libvirt 네트워크 이름 확인
- SSH 키 사용 시 `vm_ssh_authorized_keys` 추가

### 3. 비밀번호 해시 생성 (선택사항)

기본 비밀번호는 `group_vars/all.yml`에 설정되어 있습니다.
변경하려면:

```bash
# KVM 호스트에서
python3 -c 'import crypt; print(crypt.crypt("새비밀번호", crypt.mksalt(crypt.METHOD_SHA512)))'
```

출력된 해시를 `templates/user-data.j2`의 `passwd:` 필드에 복사

## 빠른 시작 (root 계정)

### 1. VM 생성 (172.30.1.42)
```bash
# root로 전환
su -

cd /home/gtckorea/workspaces/kvm-ansible

# VM 스펙 확인/수정
vi custom-playbooks/VMs/ubuntu/files/values.yml

# VM 생성 실행
ansible-playbook -i inventory.yml custom-playbooks/VMs/ubuntu/ubuntu-install.yml
```

### 2. VM 확인
```bash
virsh list --all
ssh gtckorea@172.30.1.42
# 비밀번호: appviewx1
```

### 3. Apache 설치 (선택사항)
```bash
ansible-playbook -i inventory.yml custom-playbooks/apache/apache-install.yml
# http://172.30.1.42 접속 확인
```

### 4. Tomcat 설치 (선택사항)
```bash
ansible-playbook -i inventory.yml custom-playbooks/tomcat/tomcat-install.yml
# http://172.30.1.45:8080 접속 확인
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
├── ansible.cfg                           # Ansible 설정
├── inventory.yml                         # KVM 호스트 정보
├── requirements.yml                      # Ansible 컬렉션
├── vms.yml                              # VM 스펙 정의 (레거시)
├── group_vars/
│   └── all.yml                          # 공통 변수
├── templates/
│   ├── user-data.j2                     # cloud-init 사용자 설정
│   └── meta-data.j2                     # cloud-init 메타데이터
├── scripts/
│   ├── generate_password_hash.sh        # 비밀번호 해시 생성
│   └── check_network.sh                 # 네트워크 확인
├── create_vms.yml                       # VM 생성 플레이북 (레거시)
├── delete_vms.yml                       # VM 삭제 플레이북
├── custom-playbooks/                    # 애플리케이션별 플레이북
│   ├── VMs/
│   │   └── ubuntu/
│   │       ├── ubuntu-install.yml       # Ubuntu VM 생성
│   │       ├── files/
│   │       │   ├── values.yml          # VM 스펙 정의
│   │       │   └── templates/
│   │       │       └── user-data-custom.j2
│   │       └── README.md
│   ├── apache/
│   │   ├── apache-install.yml           # Apache 설치
│   │   ├── files/
│   │   │   ├── values.yml              # Apache 설정
│   │   │   └── templates/
│   │   │       ├── ports.conf.j2
│   │   │       ├── vhost.conf.j2
│   │   │       └── index.html.j2
│   │   └── README.md
│   └── tomcat/
│       ├── tomcat-install.yml           # Tomcat 설치
│       ├── files/
│       │   ├── values.yml              # Tomcat 설정
│       │   └── templates/
│       │       ├── server.xml.j2
│       │       ├── tomcat-users.xml.j2
│       │       ├── context.xml.j2
│       │       └── tomcat.service.j2
│       └── README.md
└── README.md
```

## 상세 플레이북 사용법 (root 계정)

### VM 생성
```bash
cd /home/gtckorea/workspaces/kvm-ansible
ansible-playbook -i inventory.yml custom-playbooks/VMs/ubuntu/ubuntu-install.yml
```

### Apache 설치
```bash
ansible-playbook -i inventory.yml custom-playbooks/apache/apache-install.yml
```

### Tomcat 설치
```bash
ansible-playbook -i inventory.yml custom-playbooks/tomcat/tomcat-install.yml
```

### VM 삭제
```bash
ansible-playbook -i inventory.yml delete_vms.yml
```

상세한 사용법은 각 디렉토리의 README.md 참조

## 환경
- 호스트: Rocky Linux 9
- 하이퍼바이저: KVM/libvirt
- VM OS: Ubuntu Server 24.04
- 네트워크: 172.30.1.0/24 (br0)
- 사용자: gtckorea / ******* (group_vars/all.yml 참조)
