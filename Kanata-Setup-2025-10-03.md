# Kanata 3단 체인 + 자동 복구 설정 정리 (2025-10-03)

## 1. 구조 요약

```
물리 한손키보드 (/dev/input/eventX)
  -> kanata1.service가 grab
  -> kanata1 가상장치 /run/user/1000/kanata1 (/dev/input/event266)

물리 일반키보드 + kanata1 가상장치
  -> kanata2.service가 grab
  -> kanata2 가상장치 /run/user/1000/kanata2 (/dev/input/event267)

kanata2 가상장치
  -> mouseless.service가 grab
  -> 마우스 에뮬레이션
```

* `kanata` 본판은 출력 장치 이름이 `kanata`로 고정 (`linux-output-name` 옵션 없음)
* 이름으로 구분 불가 → **경로 심링크**로 구분

## 2. 기존 문제

1.  `kanata2`가 `kanata`라는 이름으로 장치 잡을 때, `kanata1` 출력까지 같이 잡아서 `Resource busy (EBUSY)` 발생
2.  `Restart=on-failure`는 프로세스가 죽어야만 재시작 → USB 절전/재연결로 장치가 사라져도 프로세스는 살아있어서 먹통 상태 유지
3.  `linux-continue-if-no-devs-found true`(기본값)는 부팅시 유리하지만, 런타임 장애시 죽지 않음

## 3. 해결 전략

### A. 경로 기반 분리
* kanata1 출력: `/run/user/1000/kanata1` 심링크 생성
* kanata2 출력: `/run/user/1000/kanata2` 심링크 생성
* mouseless는 `devices: ["/run/user/1000/kanata2"]` 로 **경로만** 잡게 변경 (이름 `kanata` 사용 금지)

### B. 실행 순서 보장 (systemd 체인)
* kanata1 -> kanata2 -> mouseless 순으로 BindsTo/Requires/PartOf 연결
* kanata2는 kanata1 심링크가 생길 때까지 ExecStartPre에서 대기
* mouseless는 kanata2에 BindsTo

### C. 장애시 자동 재시작
1.  `defcfg`에서 `linux-continue-if-no-devs-found nil` → 장치 끊기면 kanata가 즉시 exit
2.  모든 서비스 `Restart=always`, `RestartSec=1`, `StartLimitIntervalSec / Burst` 설정 → exit시 1초 뒤 자동 재시작
3.  부팅시 장치 늦게 뜨는 문제 해결을 위해 kanata1에만 ExecStartPre에서 물리 장치 대기 루프 추가 (최대 60초)
4.  프로세스는 살아있는데 장치만 꼬인 경우를 대비한 워치독 타이머 추가

## 4. 최종 설정 파일

### kanata1.kbd (defcfg 일부)
```lisp
(defcfg
  linux-continue-if-no-devs-found nil
)
```

### kanata1.service
```ini
[Unit]
Description=kanata1 - hand keyboard
StartLimitIntervalSec=60
StartLimitBurst=60

[Service]
Type=simple
ExecStartPre=/bin/sh -c 'rm -f %t/kanata1 %t/kanata1.ev %t/kanata1.log'
ExecStartPre=/bin/sh -c '\
  for i in $(seq 1 60); do \
    grep -q "REPLACE" /proc/bus/input/devices && exit 0; \
    sleep 1; \
  done; \
  exit 0'
ExecStart=%h/.local/bin/kanata --cfg %h/.config/kanata/kanata1.kbd
ExecStartPost=/bin/sh -c 'sleep 0.8; EV=$(grep -A4 "\"kanata\"" /proc/bus/input/devices | grep -o "event[0-9]*" | tail -n1); [ -n "$EV" ] && ln -sf /dev/input/$EV %t/kanata1 && echo $EV > %t/kanata1.ev'
ExecStopPost=/bin/sh -c 'rm -f %t/kanata1 %t/kanata1.ev; sleep 0.3'
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```
* `REPLACE`는 한손키보드 `/proc/bus/input/devices`의 Name 문자열로 교체 필요

### kanata2.service
```ini
[Unit]
Description=kanata2 - main brain
After=kanata1.service
Requires=kanata1.service
BindsTo=kanata1.service
PartOf=kanata1.service
StartLimitIntervalSec=30
StartLimitBurst=10

[Service]
Type=simple
ExecStartPre=/bin/sh -c 'for i in $(seq 1 50); do [ -L %t/kanata1 ] && [ -e %t/kanata1 ] && exit 0; sleep 0.2; done; exit 1'
ExecStart=%h/.local/bin/kanata --cfg %h/.config/kanata/kanata2.kbd
ExecStartPost=/bin/sh -c '\
  sleep 1.2; \
  EV1=$(cat %t/kanata1.ev 2>/dev/null); \
  EV2=$(grep -A4 "\"kanata\"" /proc/bus/input/devices | grep -o "event[0-9]*" | while read ev; do if [ "$ev" != "$EV1" ]; then echo $ev; fi; done | tail -n1); \
  if [ -n "$EV2" ]; then ln -sf /dev/input/$EV2 %t/kanata2; echo $EV2 > %t/kanata2.ev; fi'
ExecStopPost=/bin/sh -c 'rm -f %t/kanata2 %t/kanata2.ev; sleep 0.3'
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```

### mouseless config.yaml
```yaml
devices:
  - /run/user/1000/kanata2
```

### mouseless.service
```ini
[Unit]
Description=mouseless - mouse emulation on kanata2
After=kanata2.service
Requires=kanata2.service
BindsTo=kanata2.service
PartOf=kanata2.service
StartLimitIntervalSec=30
StartLimitBurst=10

[Service]
Type=simple
ExecStart=%h/.local/bin/mouseless --config %h/.config/mouseless/config.yaml
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```

## 5. 워치독 (먹통 감지)

### ~/.local/bin/kanata-check.sh
```bash
#!/bin/sh
if ! grep -q '"kanata"' /proc/bus/input/devices; then
  systemctl --user restart kanata1.service
  exit 0
fi
[ -L /run/user/1000/kanata1 ] && [ -e /run/user/1000/kanata1 ] || systemctl --user restart kanata1.service
[ -L /run/user/1000/kanata2 ] && [ -e /run/user/1000/kanata2 ] || systemctl --user restart kanata2.service
```

### kanata-watch.service
```ini
[Unit]
Description=kanata watchdog

[Service]
Type=oneshot
ExecStart=%h/.local/bin/kanata-check.sh
```

### kanata-watch.timer
```ini
[Unit]
Description=Check kanata every 10s

[Timer]
Unit=kanata-watch.service
OnBootSec=30
OnUnitActiveSec=10

[Install]
WantedBy=timers.target
```

활성화:
```bash
chmod +x ~/.local/bin/kanata-check.sh
systemctl --user daemon-reload
systemctl --user enable --now kanata1.service
systemctl --user enable --now kanata-watch.timer
systemctl --user list-timers | grep kanata
```

## 6. 동작 시나리오

1.  부팅: kanata1 Pre에서 물리 키보드 대기 → kanata1 출력 생성 → kanata2 대기 해제 → kanata2 출력 생성 → mouseless 시작
2.  사용 중 한손키보드 USB 끊김: kanata1이 nil 설정으로 exit → systemd가 1초 뒤 재시작 → 체인으로 kanata2, mouseless도 재시작
3.  프로세스는 살아있는데 장치 꼬임: 10초마다 kanata-watch.timer가 감지 → kanata1 강제 재시작 → 체인 재시작
