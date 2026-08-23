# 같은 엔티티의 sphere_light_component 를 맥동시키고 색을 순환시킨다.
# spin_component 와 함께 붙이면 회전하는 컬러 라이트가 된다.

using { /Verse.org }
using { /Verse.org/Verse }
using { /Verse.org/Colors }
using { /Verse.org/Native }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

light_pulse_component<public> := class<final_super>(component):

    # 가장 어두울 때 밝기 (칸델라)
    @editable
    var MinIntensity<public>:float = 2.0

    # 가장 밝을 때 밝기 (칸델라)
    @editable
    var MaxIntensity<public>:float = 60.0

    # 어두웠다 밝아졌다 한 바퀴 도는 데 걸리는 시간(초)
    @editable
    var PulsePeriod<public>:float = 2.0

    # 색상환을 한 바퀴 도는 데 걸리는 시간(초)
    @editable
    var ColorCyclePeriod<public>:float = 8.0

    # 갱신 주기(초). 작을수록 부드럽고 비용이 크다.
    @editable
    var UpdateInterval<public>:float = 0.05

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Print("light_pulse_component: 시작")

    OnSimulate<override>()<suspends>:void =
        if (Light := Entity.GetComponent[sphere_light_component]):
            var Elapsed:float = 0.0
            var Hue:float = 0.0

            loop:
                Sleep(UpdateInterval)
                set Elapsed = Elapsed + UpdateInterval

                # 사인파를 0..1 로 정규화해서 밝기에 매핑
                Wave := (Sin(Elapsed / PulsePeriod * 2.0 * PiFloat) + 1.0) / 2.0
                set Light.Intensity = MinIntensity + (MaxIntensity - MinIntensity) * Wave

                # 색상환을 일정 속도로 돈다
                set Hue = Hue + 360.0 * UpdateInterval / ColorCyclePeriod
                if (Hue > 360.0):
                    set Hue = Hue - 360.0
                set Light.ColorFilter = MakeColorFromHSV(Hue, 0.85, 1.0)
        else:
            Print("light_pulse_component: 같은 엔티티에 sphere_light_component 가 없습니다")
