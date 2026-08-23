# Verse 동시성 3종(sync / race / branch)을 라이트 색으로 보여주는 데모.
#
# 핵심은 "무엇이 실행됐는가"가 아니라 "무엇이 실행되지 않았는가"다.
# race 에서 진 쪽은 자동 취소되므로, 패자 안의 코드는 절대 실행되면 안 된다.
# 그걸 눈에 띄게 만들어 두고 나타나지 않는지를 본다.

using { /Verse.org }
using { /Verse.org/Verse }
using { /Verse.org/Colors }
using { /Verse.org/Native }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

concurrency_demo_component<public> := class<final_super>(component):

    @editable
    var DimIntensity<public>:float = 6.0

    @editable
    var BrightIntensity<public>:float = 80.0

    # 라이트 색을 바꾼다
    SetColor(Light:sphere_light_component, NewColor:color):void =
        set Light.ColorFilter = NewColor

    # 이름표를 달고 기다렸다가 끝났다고 알린다
    Step(Label:string, Seconds:float)<suspends>:void =
        Sleep(Seconds)
        Print("    {Label} 끝", ?Duration := 3.0)

    # 서서히 밝아진다
    FadeIn(Light:sphere_light_component, Seconds:float)<suspends>:void =
        Steps := 20
        StepTime := Seconds / 20.0
        var I:int = 0
        loop:
            if (I >= Steps):
                break
            Ratio := 1.0 * I / 20.0
            set Light.Intensity = DimIntensity + (BrightIntensity - DimIntensity) * Ratio
            Sleep(StepTime)
            set I = I + 1

    # race 에서 지는 쪽. 여기 도달하면 취소가 동작하지 않은 것이다.
    ShouldBeCancelled(Light:sphere_light_component)<suspends>:void =
        Sleep(4.0)
        Print("!!! 취소 실패 - 이 줄이 보이면 버그 !!!", ?Duration := 30.0, ?Color := NamedColors.White)
        set Light.ColorFilter = NamedColors.White
        set Light.Intensity = 500.0

    # 배경에서 깜빡인다
    Blink(Light:sphere_light_component, Times:int)<suspends>:void =
        var I:int = 0
        loop:
            if (I >= Times):
                break
            set Light.Intensity = BrightIntensity
            Sleep(0.15)
            set Light.Intensity = DimIntensity
            Sleep(0.15)
            set I = I + 1

    OnSimulate<override>()<suspends>:void =
        if (Light := Entity.GetComponent[sphere_light_component]):

            # ---------- branch : 던져놓고 계속 진행 ----------
            # branch 는 loop 안에서 쓸 수 없다(V3552). 그래서 루프 진입 전에 한 번만.
            Print("[BRANCH] 깜빡임을 배경으로 던지고 즉시 진행", ?Duration := 4.0, ?Color := NamedColors.Lime)
            SetColor(Light, NamedColors.Lime)
            branch:
                Blink(Light, 8)
            Print("[BRANCH] 본류는 기다리지 않고 여기 도착", ?Duration := 3.0, ?Color := NamedColors.Lime)
            Sleep(4.0)

            loop:
                # ---------- sync : 둘 다 끝날 때까지 ----------
                Print("[SYNC] 2초 페이드 + 3초 대기 -> 3초 걸려야 정상", ?Duration := 4.0, ?Color := NamedColors.DodgerBlue)
                SetColor(Light, NamedColors.DodgerBlue)
                sync:
                    FadeIn(Light, 2.0)
                    Step("3초 쪽", 3.0)
                Print("[SYNC] 완료", ?Duration := 2.0, ?Color := NamedColors.DodgerBlue)
                Sleep(1.0)

                # ---------- race : 먼저 끝나는 쪽이 이긴다 ----------
                Print("[RACE] 1.5초 vs 4초 -> 4초 쪽은 취소돼야 정상", ?Duration := 4.0, ?Color := NamedColors.Red)
                SetColor(Light, NamedColors.Red)
                set Light.Intensity = BrightIntensity
                race:
                    Step("1.5초 쪽(승자)", 1.5)
                    ShouldBeCancelled(Light)
                Print("[RACE] 완료 - 패자 취소됨", ?Duration := 2.0, ?Color := NamedColors.Red)
                Sleep(2.0)
        else:
            Print("concurrency_demo_component: sphere_light_component 가 없습니다")
