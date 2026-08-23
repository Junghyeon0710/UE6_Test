# 플레이어 입력에 반응하는 컴포넌트.
#
# Verse 에는 공개 입력 API 가 없다. input_action 은 이름만 <public> 이고
# 클래스가 epic_internal 이며, 소비하는 공개 함수도 없다.
# 그래서 입력의 "결과"를 플레이어 엔티티의 트랜스폼 변화로 읽는다.
# (플레이어 폰은 C++ 인터롭 브릿지로 LevelEntity 트리 안에 들어와 있다)

using { /Verse.org }
using { /Verse.org/Verse }
using { /Verse.org/Colors }
using { /Verse.org/Native }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

input_reaction_component<public> := class<final_super>(component):

    @editable
    var IdleIntensity<public>:float = 6.0

    @editable
    var RunIntensity<public>:float = 70.0

    # 이 속도(cm/s)면 최대 반응
    @editable
    var MaxSpeed<public>:float = 450.0

    # 지면 기준보다 이만큼 위면 공중으로 본다 (cm)
    @editable
    var AirborneHeight<public>:float = 40.0

    # 수직 속도가 이 값보다 작으면 지면에 안착한 것으로 보고 기준 높이를 갱신한다 (cm/s)
    @editable
    var SettleSpeed<public>:float = 20.0

    @editable
    var UpdateInterval<public>:float = 0.1

    FindRoot(From:entity)<transacts>:entity =
        var Current:entity = From
        loop:
            if (Parent := Current.GetParent[]):
                set Current = Parent
            else:
                break
        Current

    CollectAll(Root:entity)<transacts>:[]entity =
        var Result:[]entity = array{ Root }
        for (Child : Root.GetEntities()):
            set Result = Result + CollectAll(Child)
        Result

    # 브릿지된 폰에만 possessable_component 가 붙는다
    FindPlayer(Root:entity)<transacts>:?entity =
        var Found:?entity = false
        for (E : CollectAll(Root)):
            if (not Found?, E.GetComponent[possessable_component]):
                set Found = option{ E }
        Found

    GetLocation(E:entity)<reads><decides>:vector3 =
        E.GetComponent[transform_component].GlobalTransform.Translation

    OnSimulate<override>()<suspends>:void =
        if (Light := Entity.GetComponent[sphere_light_component]):
            Root := FindRoot(Entity)
            var Prev:vector3 = vector3{}
            var HasPrev:logic = false
            var GroundLevel:float = 0.0
            var HasGround:logic = false

            loop:
                Sleep(UpdateInterval)

                if:
                    Player := FindPlayer(Root)?
                    Now := GetLocation[Player]
                then:
                    var Speed:float = 0.0
                    var VertSpeed:float = 0.0
                    if (HasPrev?):
                        # 수평 이동만 센다
                        Flat := vector3:
                            Forward := Now.Forward - Prev.Forward
                            Left := Now.Left - Prev.Left
                            Up := 0.0
                        set Speed = Flat.Length() / UpdateInterval
                        set VertSpeed = (Now.Up - Prev.Up) / UpdateInterval
                    set Prev = Now
                    set HasPrev = true

                    # 수직 이동이 거의 없으면 지면에 안착한 것으로 보고 기준을 갱신한다.
                    # 절대 Z 대신 이 기준을 쓰면 경사/높낮이가 달라져도 판정이 유지된다.
                    if (VertSpeed.IsAlmostZero[SettleSpeed]):
                        set GroundLevel = Now.Up
                        set HasGround = true

                    Airborne := if (HasGround?, Now.Up - GroundLevel > AirborneHeight) then true else false

                    Ratio := if (Speed > MaxSpeed) then 1.0 else Speed / MaxSpeed
                    set Light.Intensity = IdleIntensity + (RunIntensity - IdleIntensity) * Ratio

                    if (Airborne?):
                        # 공중이면 흰색
                        set Light.ColorFilter = NamedColors.White
                    else:
                        # 정지 청록 -> 전력질주 노랑
                        set Light.ColorFilter = MakeColorFromHSV(180.0 - 120.0 * Ratio, 0.9, 1.0)

                    # 검증용: 스케일에 두 값을 실어 보낸다.
                    # Forward = 1 + 속도비율, Up = 공중이면 2.0
                    # 메시가 없어 화면에는 안 보이지만 GetEntityTransform 으로 읽을 수 있다.
                    if (Tc := Entity.GetComponent[transform_component]):
                        set Tc.LocalTransform = transform:
                            Translation := Tc.LocalTransform.Translation
                            Rotation := Tc.LocalTransform.Rotation
                            Scale := vector3:
                                Forward := 1.0 + Ratio
                                Left := 1.0
                                Up := if (Airborne?) then 2.0 else 1.0
