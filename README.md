# kanata-windows-config

내 Motospeed 키보드 + kanata + OSD 네비게이션 설정 모음

## 구성

- `keyboard_general.kbd` - 일반적인 키보드 설정
- `keyboard_esc2grv.kbd` - ESC키에 (`~키)를 FN으로 선택하는 ~60% 배열 키보드에서 ESC키 맵핑 설정
- `alias_common.kbd, layer_common.kbd` - 위 keyboard_*.kbd에서 사용하는 공통 설정.
- `osd_nav.ahk` - OSD 네비게이션 AutoHotkey 스크립트.
- `capslock_status.ps1` - Capslock 3탭으로 토글하기 위한 방법. layer를 만들지 않고 이 스크립트만 호출하고, 이 스크립트 내에서 capslock 상태를 파악한 후에, osd 앱 실행하는 방법.
- `sync_capslock_status_with_polybar.sh` - linux mint, i3wm+polybar 시스템에서 Capslock 처리. 방식은 윈도우와 같다.
- `start_kanata.readme` - 윈도우에서 kanata를 자동실행되게 하는 터미널 명령.

## 설치 방법

### 1. kanata 실행파일 받기

이 리포지토리에는 kanata 실행파일이 포함되어 있지 않습니다.
아래 공식 Release에서 윈도우 버전을 받아서 이 폴더에 넣어주세요.

**https://github.com/jtroo/kanata/releases**

- 일반 사용자: `kanata_windows_winIOv2_x64_gui.zip` 권장 (드라이버 설치 필요 없음)
- 키보드 2개 구분 / 정밀한 HWID 필터링 필요: `kanata_windows_wintercept_x64_gui.zip`

> `wintercept` 버전을 쓸 경우 `interception.dll`을 exe와 같은 폴더에 넣어주세요.

### 2. osd_nav.ahk 컴파일

`scripts/osd_nav.ahk`는 OSD 표시용 스크립트입니다. exe로 컴파일해서 사용합니다.

1. AutoHotkey v2 설치: https://www.autohotkey.com/
2. `osd_nav.ahk` 우클릭 > Compile Script
   또는
   ```powershell
   "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in osd_nav.ahk /out osd_nav.exe
   ```
3. 생성된 `osd_nav.exe`를 kanata 폴더에 두면 `kanata.kbd`에서 `cmd`로 호출됩니다.



### 3. 실행

#### 수동 실행 (테스트용)

```powershell
# 관리자 권한 PowerShell
.\kanata_windows_gui_winIOv2_x64_cmd_allowed.exe --cfg keyboard_general.kbd --debug
```

#### 자동 실행 등록 (작업 스케줄러)

```powershell
# 관리자 권한 PowerShell
.\scripts\install-task.ps1
```

> `taskschd.msc`에서 작업이 등록되었는지 확인하세요.
> `가장 높은 수준의 권한으로 실행` 체크 필수

### 4. Interception 드라이버 (wintercept 버전만)

winIOv2는 필요 없습니다. wintercept 버전을 쓸 때만:

```powershell
# 관리자 권한 cmd
cd C:\interception\command line installer
install-interception.exe /install
```

설치 후 재부팅 필요. 자세한 내용은 `scripts/` 폴더의 가이드를 참고하세요.

## 트러블슈팅

- `[ERROR] channel disconnected` -> Interception 드라이버가 `STOPPED` 상태. 재설치 후 재부팅
- `sc query interception` 결과 없음 -> `C:\interception` 처럼 공백 없는 경로에서 다시 `/install`
- Motospeed 구형 키보드 `장치 설명자 요청 실패` -> 윈도우11 24H2 Preview 버그. USB 2.0 유전원 허브 경유 또는 winIOv2 버전 사용
- 윈도우11에서 interception 드라이버를 설치한 후에, Ajazz 한손키보드와 Motospeed 기게식 키보드가 인식이 안되는 문제로, winIOv2 버전 사용.
  다만 interception 사용시, 인식하는 키보드(firewolk, 68키 키보드)에서는 kbd 설정을 잘 인식한다.

## License

- kanata: https://github.com/jtroo/kanata - LGPL-3.0
- 본 설정 파일들: MIT
