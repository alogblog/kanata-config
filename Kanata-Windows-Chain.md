# Kanata 체이닝 정리 (Linux vs Windows)

## 1. Linux - kanata1 -> kanata2 체이닝 가능

* **가능한 이유:** Linux의 input device 체계 덕분
  * kanata1이 물리 키보드를 읽어서 `/dev/uinput` 가상장치로 `F13~F19` 출력
  * kanata2가 그 가상장치(`/dev/input/eventXX`)를 `linux-dev`로 다시 input으로 읽음
  * systemd로 2개 서비스 순서대로 띄우면 안정적

```
물리 한손키보드 -> kanata1 -> /dev/uinput (F13) -> kanata2 -> 최종 동작
```

## 2. Windows - 여러 문제

Windows는 가상장치가 없고 `SendInput`으로 OS에 직접 쏘는 구조라 체인이 깔끔하지 않음.

### 2-1. 가장 확실한 방법: 펌웨어에서 F13 맵핑 + kanata-winIOv2 1개

* 한손키보드 QMK/VIA 웹드라이버에서 목적 키들을 펌웨어적으로 `F13~F19`로 맵핑
* Windows에서는 `kanata-winIOv2.exe` 1개만 실행해서 `F13=최종동작` 처리
* **장점:** 드라이버 1개라 충돌 0, 가장 안정적
* **단점:** 한손키보드만 단독으로 쓸 때는 웹드라이버로 다시 원래 문자(`1,2,3...`)로 재맵핑해야 하는 불편함

### 2-2. 2개 인스턴스를 써야 하는 경우 - 유일한 조합

* 목적: 한손키보드 `1`과 일반키보드 `1`의 역할을 나누기, 한손 Modifier + 일반키 문자 조합 등
* 같은 `defsrc`를 공유하므로 인스턴스 1개로는 구분 불가 -> 2개 필요

**구조:**
* `kanata-interception` (include 한손 HWID) -> 한손키보드를 잡아서 `SendInput`으로 쏨
* `kanata-winIOv2` (LLHOOK + SendInput) -> `SendInput`을 볼 수 있어서 F13 체인이 가능

```
한손키보드(물리) -> kanata-interception(include 한손) -> SendInput F13 -> kanata-winIOv2가 LLHOOK으로 F13을 봄 -> 최종 동작
```

* `wintercept`는 `SendInput`을 다시 안 잡음 (무한루프 방지)
* `winiov2`는 포트 기반이라 `SendInput`을 못 보는게 아니라, LLHOOK이라 볼 수 있음. 그래서 `wintercept -> winiov2` 방향만 체인 가능
* 공식 문서상 서로 다른 드라이버 2개 동시 사용은 비권장이지만, Windows에서 크로스 키보드 레이어를 하려면 이 조합이 유일

**Modifier 크로스 사용:**
* `한손 Ctrl + 일반 P`는 F13 경유하면 안 됨
* kanata1에서 한손의 Ctrl/Alt/Shift는 진짜 `lctl/lalt/lsft`로 쏘기
* 그러면 OS 레벨에서 이미 Ctrl이 눌린 상태가 되므로, kanata2가 P만 쏴도 OS가 `Ctrl+P`로 합쳐줌. OS 레벨 키조합은 문제없음.
* F13 경유는 레이어 전환용으로만 사용

### 2-3. 실행 순서 문제

* 기존: 작업 스케줄러에 작업 2개 등록
* 문제: `interception`이 한손키보드를 먼저 잡아야 하는데 순서 보장 안 됨
* 해결: 작업 1개 + bat 1개로 통합

```bat
@echo off
start "" "C:\kanata\kanata_wintercept.exe" -c "C:\kanata\kanata1.kbd"
timeout /t 3
start "" "C:\kanata\kanata_winiov2.exe" -c "C:\kanata\kanata2.kbd"
```

* `wintercept` 먼저 3초 대기 후 `winiov2` 실행으로 순서 보장
* 종료도 `taskkill`로 해야 드라이버가 필터링 모드로 남지 않음. 강제 종료시 키보드 먹통 -> `Disable/Enable-PnpDevice`로 리셋 필요
