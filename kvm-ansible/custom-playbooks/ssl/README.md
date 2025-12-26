# SSL 인증서 생성 및 적용

Ubuntu Apache 서버에 사설 SSL 인증서를 생성하고 적용합니다.

## 인증서 정보

- **도메인**: apache.gtck.kr
- **국가**: KR (대한민국)
- **지역**: Seoul
- **회사명**: gtckorea
- **유효기간**: 365일
- **포트**: 443

## 사용 방법 (root 계정)

### 1. 설정 확인
```bash
cd /home/gtckorea/workspaces/kvm-ansible
vi custom-playbooks/ssl/files/values.yml
```

### 2. SSL 인증서 생성 및 적용
```bash
# ubuntu-web01에 SSL 인증서 생성 및 Apache 적용
ansible-playbook -i inventory.yml custom-playbooks/ssl/ssl-cert-install.yml
```

### 3. 접속 확인
```bash
# HTTPS로 접속
curl -k https://apache.gtck.kr
# 또는 브라우저에서
# https://172.30.1.42
# https://apache.gtck.kr
```

## 생성되는 파일

- `/etc/ssl/apache.gtck.kr/apache.gtck.kr.key` - 개인키
- `/etc/ssl/apache.gtck.kr/apache.gtck.kr.crt` - 인증서
- `/etc/ssl/apache.gtck.kr/apache.gtck.kr.csr` - CSR (인증서 서명 요청)
- `/etc/apache2/sites-available/apache-gtck-kr-ssl.conf` - SSL VirtualHost 설정

## 인증서 교체

### 새 인증서 발급 (기존 삭제 후 재생성)
```bash
# VM에 SSH 접속
ssh gtckorea@172.30.1.42

# 기존 인증서 삭제
sudo rm -rf /etc/ssl/apache.gtck.kr

# playbook 재실행
ansible-playbook -i inventory.yml custom-playbooks/ssl/ssl-cert-install.yml
```

### 외부 인증서 사용 (Let's Encrypt 등)
외부에서 발급받은 인증서가 있다면:
```bash
# 인증서 파일을 VM에 복사
scp your-cert.crt gtckorea@172.30.1.42:/tmp/
scp your-key.key gtckorea@172.30.1.42:/tmp/

# VM에서 설치
sudo mkdir -p /etc/ssl/apache.gtck.kr
sudo mv /tmp/your-cert.crt /etc/ssl/apache.gtck.kr/apache.gtck.kr.crt
sudo mv /tmp/your-key.key /etc/ssl/apache.gtck.kr/apache.gtck.kr.key
sudo chmod 600 /etc/ssl/apache.gtck.kr/apache.gtck.kr.key
sudo chmod 644 /etc/ssl/apache.gtck.kr/apache.gtck.kr.crt
sudo systemctl restart apache2
```

## 인증서 정보 확인

```bash
# 인증서 내용 확인
openssl x509 -in /etc/ssl/apache.gtck.kr/apache.gtck.kr.crt -text -noout

# 인증서 만료일 확인
openssl x509 -in /etc/ssl/apache.gtck.kr/apache.gtck.kr.crt -noout -enddate

# 개인키와 인증서 일치 여부 확인
openssl x509 -noout -modulus -in /etc/ssl/apache.gtck.kr/apache.gtck.kr.crt | openssl md5
openssl rsa -noout -modulus -in /etc/ssl/apache.gtck.kr/apache.gtck.kr.key | openssl md5
```

## 주의사항

- 사설 인증서는 브라우저에서 경고가 표시됩니다
- 프로덕션 환경에서는 공인 인증서(Let's Encrypt 등) 사용 권장
- 인증서 유효기간은 `ssl_validity_days`로 조정 가능
- 여러 대에 동시 적용하려면 `files/values.yml`의 `ssl_target_hosts`에 호스트 추가
