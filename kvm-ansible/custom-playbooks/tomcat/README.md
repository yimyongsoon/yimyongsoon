# Apache Tomcat 자동 설치

Ubuntu VM에 Apache Tomcat 10.1 최신 버전을 자동으로 설치 및 구성합니다.

## 사용법

### 1. inventory.yml 확인

`tomcat_servers` 그룹에 대상 VM이 정의되어 있는지 확인:

```yaml
tomcat_servers:
  hosts:
    ubuntu-app01:
      ansible_host: 172.30.1.45
    ubuntu-app02:
      ansible_host: 172.30.1.46
```

### 2. values.yml 수정

`files/values.yml`에서 Tomcat 설정 변경:
- Tomcat 버전
- 포트 (기본 8080)
- 관리자 계정/비밀번호
- JVM 메모리 설정
- Manager 앱 접근 허용 IP

### 3. 플레이북 실행

```bash
# Rocky9 KVM 호스트에서
cd /path/to/kvm-ansible

# Tomcat 설치
ansible-playbook -i inventory.yml custom-playbooks/tomcat/tomcat-install.yml

# 특정 호스트만 설치
ansible-playbook -i inventory.yml custom-playbooks/tomcat/tomcat-install.yml --limit ubuntu-app01
```

### 4. 설치 확인

```bash
# 웹 브라우저
http://172.30.1.45:8080

# Manager 앱 (관리자 로그인 필요)
http://172.30.1.45:8080/manager

# 또는 curl
curl http://172.30.1.45:8080
```

## 설치 내용

- Apache Tomcat 10.1.34 (최신 버전)
- OpenJDK 17
- systemd 서비스 등록
- Manager/Host Manager 앱 활성화
- 관리자 계정 생성
- 방화벽 규칙 (ufw)
- IP 기반 접근 제어

## 기본 설정

| 항목 | 값 |
|------|-----|
| Tomcat 버전 | 10.1.34 |
| Java 버전 | OpenJDK 17 |
| HTTP 포트 | 8080 |
| 설치 경로 | /opt/tomcat |
| 서비스 사용자 | tomcat |
| 관리자 ID | admin |
| 관리자 PW | files/values.yml 참조 |

## 파일 구조

```
tomcat/
├── tomcat-install.yml               # 메인 플레이북
├── files/
│   ├── values.yml                  # Tomcat 설정 변수
│   └── templates/
│       ├── server.xml.j2           # Tomcat 서버 설정
│       ├── tomcat-users.xml.j2     # 사용자 계정
│       ├── context.xml.j2          # Manager 앱 접근 제어
│       └── tomcat.service.j2       # systemd 서비스
└── README.md
```

## 커스터마이징

### Tomcat 버전 변경

`files/values.yml`:
```yaml
tomcat_version: "10.1.34"
tomcat_major_version: "10"
```

### JVM 메모리 튜닝

`files/values.yml`:
```yaml
tomcat_catalina_opts: "-Xms1024M -Xmx2048M -server -XX:+UseParallelGC"
```

### 포트 변경

`files/values.yml`:
```yaml
tomcat_port: 9090  # 8080 대신
```

### 관리자 비밀번호 변경

`files/values.yml`:
```yaml
tomcat_admin_password: "새비밀번호"
```

## 운영 명령

```bash
# Tomcat 상태 확인
sudo systemctl status tomcat

# Tomcat 재시작
sudo systemctl restart tomcat

# 로그 확인
sudo tail -f /opt/tomcat/logs/catalina.out

# WAR 배포
sudo cp app.war /opt/tomcat/webapps/
```

## 보안 주의사항

⚠️ **운영 환경에서는 반드시:**
1. `tomcat_admin_password` 변경
2. `tomcat_manager_allow_ips` 제한 설정
3. HTTPS 설정 (별도 리버스 프록시 또는 SSL 인증서)
4. 불필요한 샘플 앱 제거 (`/opt/tomcat/webapps/examples`, `docs` 등)
