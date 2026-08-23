# Scene Graph 컴포넌트 기본형.
# 엔진 템플릿(Engine/Plugins/EntityFramework/Source/Component/ScriptTemplates/ComponentTemplate.verse) 기준.

using { /Verse.org }
using { /Verse.org/Verse }
using { /Verse.org/Native }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

# 엔티티에 붙일 수 있는 Verse 컴포넌트
hello_component<public> := class<final_super>(component):

    # 에디터 디테일 패널에 노출되는 값
    @editable
    var Greeting<public>:string = "Hello from Verse"

    @editable
    var RepeatSeconds<public>:float = 3.0

    # 게임이 시작되어 컴포넌트가 시뮬레이션을 시작할 때 1회 실행
    OnBeginSimulation<override>():void =
        # 부모 클래스 로직을 먼저 실행
        (super:)OnBeginSimulation()
        Print("hello_component: OnBeginSimulation")

    # 컴포넌트 수명 동안 중단(suspend) 가능한 로직.
    # 컴포넌트가 파괴되거나 게임이 끝나면 자동으로 취소된다.
    OnSimulate<override>()<suspends>:void =
        loop:
            Print(Greeting)
            Sleep(RepeatSeconds)
