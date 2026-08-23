# UE6

UE 6.0 서드퍼슨 템플릿 기반 학습용 프로젝트. Verse와 Scene Graph를 실제로 붙여보는 중.

## 환경

| | |
|---|---|
| 엔진 | UE **6.0.0 소스 빌드** (`D:\UnrealEngine`, 브랜치 `ue6-main`) |
| 연결 | `EngineAssociation` GUID — 런처에 등록되지 않은 커스텀 빌드 |
| 렌더링 | DX12 / SM6, Lumen, Virtual Shadow Maps, Substrate, 레이트레이싱 |
| 에디터 자동화 | `ModelContextProtocol` 플러그인 (`http://127.0.0.1:8000/mcp`) |

## 구조

```
Source/UE6/
├── UE6Character / GameMode / PlayerController   공통 베이스 (Epic 템플릿 원본)
├── Variant_Combat/          전투 - StateTree AI + EQS, 콤보/차지 공격
├── Variant_Platforming/     플랫포머 - 더블점프, 월점프, 대시
├── Variant_SideScrolling/   사이드스크롤 - NPC, 점프패드, 이동 플랫폼
└── SceneGraph/              ★ 씬 그래프 자동화용 C++ 유틸 (직접 추가)

Plugins/VerseGame/           ★ Verse 코드 루트 (VersePath /ue6.local/VerseGame)
└── Content/
    ├── HelloComponent.verse      기본형 (OnBeginSimulation / OnSimulate)
    ├── SpinComponent.verse       엔티티 회전
    └── LightPulseComponent.verse 라이트 맥동 + 색상 순환

docs/                        ★ 작업 기록
```

★ 표시가 템플릿에 없던, 이번에 추가한 부분입니다.

## 지금까지 한 것

1. git 초기화 + UE용 `.gitignore` (재생성 가능한 500MB 제외)
2. `EntityFramework`(Scene Graph, Beta) 활성화
3. `VerseGame` 플러그인 + Verse 컴포넌트 2종 작성
4. 씬 그래프를 코드로 다루기 위한 C++ 유틸리티 추가
5. 레벨에 엔티티 생성 → `spin_component` 부착 → PIE에서 회전 검증
6. `sphere_light_component` + `light_pulse_component`로 눈에 보이는 결과 확보

### 미해결

- **메시**를 엔티티에 붙이는 것. 씬 그래프는 메시 에셋마다 생성된 전용 컴포넌트
  클래스를 붙이는 구조인데, 이 환경에는 그런 클래스가 하나도 없습니다
  (문서의 벽 ⑦·⑧). 대신 **라이트**로 시각화했습니다 — 라이트는 에셋 참조가
  없어서 클래스가 이미 존재합니다.

## 문서

- **[Verse / Scene Graph 실습 기록](docs/verse-scenegraph-log.md)** — 막힌 지점 7개와 각각의 원인·해결 과정

## 빌드

```bash
"D:/UnrealEngine/Engine/Build/BatchFiles/Build.bat" UE6Editor Win64 Development -project="D:/Unreal Projects/UE6/UE6.uproject" -waitmutex
```

Verse만 문법 검사 (에디터 불필요):

```bash
"D:/UnrealEngine/Engine/Binaries/Win64/VerseCompilerCmd.exe" "D:/Unreal Projects/UE6/Intermediate/ProjectFiles/Verse/All/All.vproject"
```

> 출력이 없으면 성공입니다. **에러가 나도 종료 코드는 0**이므로 exit code로 판단하면 안 됩니다.
