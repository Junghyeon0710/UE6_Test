# UE6 Verse / Scene Graph 실습 기록

> 2026-08-23 · UE 6.0.0 소스 빌드(`D:\UnrealEngine`, 브랜치 `ue6-main`) · 스톡 서드퍼슨 템플릿에서 시작

목표: **UE6에서 Verse가 뭔지 파악하고, 켜고, 실제로 레벨에서 돌려보기.**

결론부터: 됩니다. 다만 문서에 안 나오는 벽이 여섯 개 있었고, 그 대부분은
"엔진 소스를 직접 읽어야만 알 수 있는" 것들이었습니다. 이 문서는 그 과정 기록입니다.

---

![Verse가 켜진 에디터](images/01-verse-enabled-editor.png)
*메뉴에 `Verse`, 툴바에 `Compile Verse`, 우측에 `Verse Explorer` 탭이 생겼다.*

## 0. 출발점

프로젝트는 Epic의 Third Person 템플릿 원본이었습니다. C++ 42개 클래스, 749개 에셋,
Verse는 흔적도 없음. 엔진만 UE 6.0 소스 빌드.

```
Source/UE6/          6,637 LOC (Epic 원본 그대로)
Content/             749 uasset, 레벨 4개
Verse 관련 플러그인   전부 비활성
```

---

## 1. Verse 코드는 어디에 놓이는가

`UnrealBuildTool`을 읽어서 확인한 결과, Verse 코드를 스캔하는 위치는 **딱 두 곳**입니다.

| 위치 | 용도 | 요구사항 |
|---|---|---|
| `<플러그인>/Content/` | 스크립트 Verse | uplugin에 `CanContainVerse`, `VersePath` |
| `<모듈>/Verse/` | 네이티브 Verse (VNI) | Build.cs에 `SetupVerse(...)` |

근거: `ProjectFiles/VProject/VProjectFileGenerator.cs:179`가 플러그인의 `Content` 폴더를 잡고,
`Build/UEBuildModuleCPP.cs:212`가 `Build.cs` 옆의 `Verse` 폴더를 잡습니다.

### 벽 ① — uproject에는 Verse를 못 넣는다

`VersePath` / `VerseScope` / `CanContainVerse` 필드는 `PluginDescriptor.h`에만 있고
`ProjectDescriptor`에는 **없습니다.** 즉 프로젝트에 Verse를 쓰려면 플러그인을 하나 만들어야 합니다.

그래서 만든 것이 [`Plugins/VerseGame`](../Plugins/VerseGame/VerseGame.uplugin) —
C++ 모듈 없이 uplugin + `Content/*.verse`만 있는 플러그인입니다.

```json
{
	"VersePath": "/ue6.local/VerseGame",
	"VerseScope": "PublicUser",
	"CanContainVerse": true,
	"Plugins": [ { "Name": "EntityFramework", "Enabled": true } ]
}
```

### 벽 ② — `Print`가 안 딸려온다

Epic의 공식 컴포넌트 템플릿을 그대로 붙여넣어도 `Print`에서 심볼 해석이 실패합니다.
`Print`는 `VersePrint` 플러그인(`/Verse.org/Verse`)에 있는데, `EntityFramework`의
의존성 27개 체인에 **VersePrint가 없기 때문**입니다.

생성된 `.vproject`의 `dependencyPackages`를 뒤져서 알아냈습니다. uplugin에 직접 추가해야 합니다.

---

## 2. 첫 컴포넌트

[`HelloComponent.verse`](../Plugins/VerseGame/Content/HelloComponent.verse) /
[`SpinComponent.verse`](../Plugins/VerseGame/Content/SpinComponent.verse)

```verse
spin_component<public> := class<final_super>(component):

    @editable
    var DegreesPerSecond<public>:float = 90.0

    OnSimulate<override>()<suspends>:void =
        if (TransformComponent := Entity.GetComponent[transform_component]):
            var Yaw:float = 0.0
            loop:
                Sleep(UpdateInterval)
                set Yaw = Yaw + DegreesPerSecond * UpdateInterval
                ...
```

Actor + Tick 모델과 가장 다른 점이 `<suspends>`입니다. Tick 함수를 쓰지 않고
코루틴으로 돌며, 컴포넌트가 파괴되면 진행 중이던 suspension이 **자동 취소**됩니다.

---

## 3. 에디터 없이 Verse 컴파일 검증하기

에디터를 띄우지 않고 문법을 확인할 수 있습니다:

```bash
"D:/UnrealEngine/Engine/Binaries/Win64/VerseCompilerCmd.exe" "D:/Unreal Projects/UE6/Intermediate/ProjectFiles/Verse/All/All.vproject"
```

`.vproject`는 이렇게 생성/갱신합니다:

```bash
"D:/UnrealEngine/Engine/Build/BatchFiles/Build.bat" -projectfiles -project="D:/Unreal Projects/UE6/UE6.uproject" -game -engine -VProject
```

### 벽 ③ — 컴파일러가 실패해도 종료 코드는 0

일부러 깨진 파일을 넣어 확인했습니다:

```
VNI Compilation FAILED -- 1 error, 0 warnings!
__SyntaxProbe.verse(1,19, 1,19): Verse compiler error V3100: vErr:S77: Unexpected "verse" following expression
EXIT=0        ← 0 입니다
```

**출력 유무로 판단해야 합니다.** CI에 넣는다면 exit code가 아니라 stdout이 비었는지를 봐야 합니다.

---

## 4. 레벨에 붙이기 — 막힌 네 갈래

컴파일은 됐는데, 만든 컴포넌트를 레벨의 엔티티에 붙이는 데서 막혔습니다.
스크립트로 하려고 시도한 경로 전부 실패했습니다.

| 시도 | 결과 |
|---|---|
| Python `set_editor_property` | `Property 'Components' ... is protected and cannot be read` |
| MCP `ObjectTools.list_properties` (C++ 경유) | 빈 값 반환 |
| `SubobjectDataSubsystem` | 엔티티 프리팹에 대해 핸들 **0개** |
| Verse에서 엔티티 클래스에 컴포넌트 선언 | `V3600: Object archetype must initialize data member 'Entity'` |

네 번째가 특히 중요했습니다. 컴포넌트 필드를 선언하려면
`GetSelfEntityForComponentInitialization()`이 필요한데 `epic_internal`입니다.
`VerseScope`를 `InternalAPI`로 바꿔봤지만:

```
V3593: Invalid access of epic_internal function
       `(/Verse.org/SceneGraph:)GetSelfEntityForComponentInitialization`
       from control scope `/ue6.local/VerseGame/spinner_prefab_probe`
```

### 벽 ④ — epic_internal 게이팅은 스코프가 아니라 **도메인** 기준

`/ue6.local/...`은 Epic 도메인이 아니라서 `VerseScope`를 뭘로 바꿔도 열리지 않습니다.
(확인 후 원복했습니다.)

`EntityFramework` 전체에 `BlueprintCallable`이 **하나도 없습니다.** 엔진 주석도
"Primarily prefabs are authored through the editor"라고 못박고 있습니다.
GUI가 유일한 정식 경로 → 자동화하려면 C++ 밖에 없다는 결론.

---

## 5. C++ 유틸리티

[`Source/UE6/SceneGraph/SceneGraphTestUtils.h`](../Source/UE6/SceneGraph/SceneGraphTestUtils.h)

`UBlueprintFunctionLibrary` 하나로 필요한 것만 노출했습니다. `BlueprintCallable`이면
Python 바인딩이 자동으로 생기므로, 이후 모든 작업이 스크립트로 가능해집니다.

```cpp
SpawnEntityWithComponents(World, {ComponentClasses}, Transform, Name)
AddComponentToEntity(Entity, ComponentClass)
AddStaticMeshToEntity(Entity, Mesh)      // 에디터 전용
GetEntityTransform(Entity)
GetAllEntities(World) / GetEntityComponents(Entity)
```

Build.cs에 `Entity`, `EntityLevel` 모듈을 추가하면 됩니다. 메시용 헬퍼는
에디터 모듈에만 있어서 `if (Target.bBuildEditor)`로 감쌌습니다.

### 벽 ⑦ — 씬 그래프에는 "메시 프로퍼티"가 없다

엔티티를 화면에 보이게 하려고 큐브를 붙이려다 막혔습니다. `mesh_component`에
`Mesh` 필드가 있긴 한데 `epic_internal`이고, 에디터가 쓰는 경로는 완전히 다릅니다:

```cpp
// 에디터의 "기본 도형 배치" 코드 (EntityPlacementFactory.cpp)
TSubclassOf<verse::component> MeshComponentClass =
    FAssetComponentHelpers::FindAssetComponentChildClassForAssetData(FAssetData(StaticMesh));
UE::SceneGraphAPI::GetOrCreateComponentByType(Entity, MeshComponentClass);
```

**메시 에셋마다 전용 컴포넌트 클래스가 따로 생성되어 있고**, 그 클래스를 붙이는 구조입니다.
그런데 이 클래스는 uplugin에 `bEnableVerseAssetReflection`이 켜진 플러그인의 에셋에
대해서만 생성됩니다. 확인해 보니 이 프로젝트에는 그런 클래스가 0개라
`/Engine/BasicShapes/Cube`로는 `nullptr`가 돌아옵니다.

`AddStaticMeshToEntity`는 구현해 뒀지만, 쓰려면 먼저 메시를 `VerseGame` 플러그인
콘텐츠로 옮기고 에셋 리플렉션을 켜야 합니다. 그래서 이번 검증은 화면이 아니라
**트랜스폼 수치**로 했습니다.

---

## 6. 두 번째 벽: 붙였는데 저장이 안 된다

첫 구현은 `entity->GetOrCreateComponentByType()`을 썼습니다. 결과:

- 편집 중인 월드에서는 컴포넌트 3개가 **잘 보임**
- 레벨 저장 후 리로드하면 `transform_component`만 남고 **Verse 컴포넌트는 사라짐**
- PIE로 들어가도 마찬가지

`Modify()`를 불러도 소용없었습니다. 로그에 경고 한 줄 없이 조용히 빠집니다.

### 벽 ⑤ — 이름이 같은 함수가 두 개 있다

에디터가 실제로 쓰는 코드를 grep해서 찾았습니다:

```cpp
// entity 의 멤버 함수 — 붙이기만 한다
Entity->GetOrCreateComponentByType(Type);

// UE::SceneGraphAPI 네임스페이스 — "handles all the changed events
// needed for the engine to recognize this change"
UE::SceneGraphAPI::GetOrCreateComponentByType(Entity, Type);
```

두 번째로 바꾸니 바로 해결됐습니다. `transform_component`가 살아남았던 이유도
`CreateEntity` 내부가 이미 `SceneGraphAPI` 쪽을 쓰고 있어서였습니다.

---

## 7. 자동화: 에디터를 MCP로 조작하기

UE6 에디터는 `ModelContextProtocol` 플러그인으로 `http://127.0.0.1:8000/mcp`에
MCP 서버를 띄웁니다(툴셋 72개). Claude Code 설정을 건드리지 않고 curl로 직접 붙였습니다.

```bash
# 1) initialize → 응답 헤더의 Mcp-Session-Id 확보
# 2) 이후 모든 요청에 Mcp-Session-Id 헤더
# 3) 실제 툴은 call_tool 로 감싸서 호출
```

함정 셋:
- 노출된 툴은 `list_toolsets` / `describe_toolset` / `call_tool` **3개뿐**. 실제 툴을 이름으로 직접 부르면 `Unknown tool`
- `describe_toolset`의 파라미터명은 `toolset`이 아니라 **`toolset_name`**
- `execute_python`의 `script`는 문자열이 아니라 **`{"content": ..., "language": "Python"}`** CodeBlock 객체

### 벽 ⑥ — 에디터가 백그라운드면 MCP가 응답하지 않는다

TCP 연결은 받아들이는데 응답이 없어서 한참 헤맸습니다. UE 에디터는 포그라운드가
아니면 게임스레드 틱을 스로틀링하고, MCP HTTP 핸들러가 게임스레드에서 돌기 때문입니다.
창을 포그라운드로 올리면 즉시 응답합니다.

---

## 8. 검증

`bSimulate: true`로 PIE를 띄우고 `GetEntityTransform`으로 0.5초 간격 샘플링:

```
대상: SpinnerEntity | 컴포넌트: ['transform_component', 'spin_component', 'hello_component']

1회차  0.5초 간격 Yaw: [162.0, -157.5, -117.0, -76.5, -36.0, 4.5]    → 구간당 +40.5°  (81°/초)
2회차  0.5초 간격 Yaw: [175.5, -144.0,  -99.0, -54.0,  -9.0, 36.0]   → 구간당 +45.0°  (90°/초)
```

(180도에서 부호가 뒤집히는 것을 감안한 값입니다.)

![PIE 시뮬레이션 중](images/03-pie-simulating.png)
*`bSimulate: true`로 실행한 PIE. 아웃라이너가 `Lvl_ThirdPerson (PIE)`로 바뀐다.*

설정값은 `DegreesPerSecond = 90`, `UpdateInterval = 0.05`이므로 이론상 90°/초입니다.
2회차는 정확히 맞았고, 1회차는 81°/초로 10% 느렸습니다.

이 차이가 오히려 중요한 관찰이었습니다. `Sleep(0.05)`는 프레임 경계로 반올림되므로,
에디터가 바쁠 때는 0.5초에 10회가 아니라 9회만 돌아 그만큼 느려집니다.
**고정 스텝 × 고정 각도 방식은 프레임레이트에 종속됩니다.** 프레임과 무관한 회전이
필요하면 경과 시간을 직접 재서 곱해야 합니다.

---

## 삽질 요약

| # | 벽 | 알아낸 방법 |
|---|---|---|
| ① | uproject에 Verse 필드가 없음 | `PluginDescriptor.h` vs `ProjectDescriptor.h` 비교 |
| ② | `Print`가 EntityFramework에 안 딸려옴 | 생성된 `.vproject`의 `dependencyPackages` 확인 |
| ③ | Verse 컴파일러가 실패해도 exit 0 | 일부러 깨뜨려서 확인 |
| ④ | epic_internal은 도메인 기준 게이팅 | `VerseScope` 바꿔보고 에러 메시지 확인 |
| ⑤ | 같은 이름의 함수 두 개 (멤버 vs SceneGraphAPI) | 에디터 자체 코드 grep |
| ⑥ | 백그라운드 에디터는 MCP 응답 없음 | 창 포그라운드로 올려보고 확인 |
| ⑦ | 메시는 에셋별 생성 컴포넌트 클래스로 붙임 | 에디터 배치 팩토리 코드 추적 |

## 다시 한다면

1. 플러그인부터 만든다 (uproject에 직접 못 넣음)
2. 쓸 Verse API가 어느 플러그인 소속인지 `.vproject`로 먼저 확인한다
3. 씬 그래프를 코드로 다룰 거면 처음부터 `UE::SceneGraphAPI` 네임스페이스만 쓴다
4. 에디터 자동화 전에 창을 포그라운드로 올린다
