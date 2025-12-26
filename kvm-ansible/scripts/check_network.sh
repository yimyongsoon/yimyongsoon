#!/bin/bash
# KVM 네트워크 확인 스크립트

echo "=== Libvirt 네트워크 목록 ==="
virsh net-list --all

echo ""
echo "=== 기존 VM의 네트워크 설정 확인 ==="
if virsh list --all | grep -q "ubuntu_apache"; then
    echo "ubuntu_apache VM 네트워크:"
    virsh dumpxml ubuntu_apache | grep -A 3 "interface type"
else
    echo "ubuntu_apache VM을 찾을 수 없습니다."
fi

echo ""
echo "=== br0 네트워크 상세 정보 ==="
if virsh net-list --all | grep -q "br0"; then
    virsh net-dumpxml br0
else
    echo "br0 네트워크를 찾을 수 없습니다."
    echo ""
    echo "사용 가능한 네트워크:"
    virsh net-list --all
fi

echo ""
echo "=== 브릿지 인터페이스 확인 ==="
ip link show type bridge
brctl show 2>/dev/null || echo "brctl 명령어 없음 (bridge-utils 설치 필요)"
