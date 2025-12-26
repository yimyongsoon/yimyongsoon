# Apache 웹서버 자동 설치

Ubuntu VM에 Apache 최신 버전을 자동으로 설치 및 구성합니다.

## 사용법

### 1. inventory.yml에 apache_servers 그룹 추가

```yaml
all:
  children:
    kvm_hosts:
      hosts:
        kvm-host:
          ansible_host: <KVM_HOST_IP>
          ansible_user: root

    apache_servers:
      hosts:
        ubuntu-web01:
          ansible_host: 172.30.1.42
          ansible_user: gtckorea
          ansible_password: ******* # group_vars/all.yml 참조
        ubuntu-web02:
          ansible_host: 172.30.1.43
          ansible_user: gtckorea
          ansible_password: *******
```

### 2. values.yml 수정

`files/values.yml`에서 Apache 설정 변경:
- HTTP/HTTPS 포트
- 활성화할 모듈
- Document root
- VirtualHost 설정

### 3. 플레이북 실행

```bash
# venv 활성화
source venv/bin/activate

# Apache 설치
ansible-playbook -i inventory.yml custom-playbooks/apache/apache-install.yml

# 특정 호스트만 설치
ansible-playbook -i inventory.yml custom-playbooks/apache/apache-install.yml --limit ubuntu-web01
```

### 4. 설치 확인

```bash
# 웹 브라우저
http://172.30.1.42

# 또는 curl
curl http://172.30.1.42
```

## 설치 내용

- Apache2 최신 버전 (Ubuntu 24.04 저장소 기준)
- PHP 모듈
- ModSecurity2
- 활성화 모듈: rewrite, ssl, headers, proxy, proxy_http
- Custom VirtualHost 설정
- 방화벽 규칙 (ufw)
- 보안 헤더 설정

## 파일 구조

```
apache/
├── apache-install.yml           # 메인 플레이북
├── files/
│   ├── values.yml              # Apache 설정 변수
│   └── templates/
│       ├── ports.conf.j2       # 포트 설정
│       ├── vhost.conf.j2       # VirtualHost 설정
│       └── index.html.j2       # 기본 index 페이지
└── README.md
```

## 커스터마이징

### 추가 모듈 설치

`files/values.yml`:
```yaml
apache_modules:
  - libapache2-mod-php
  - libapache2-mod-security2
  - libapache2-mod-wsgi-py3  # 추가

apache_enable_mods:
  - rewrite
  - ssl
  - wsgi  # 추가
```

### VirtualHost 추가

`files/templates/vhost.conf.j2`를 복사하여 새 VirtualHost 생성

### SSL/TLS 설정

별도 플레이북으로 Let's Encrypt 또는 자체 서명 인증서 구성 가능
