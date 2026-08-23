# 자식 엔티티를 런타임에 만들어 궤도를 도는 계층 구조를 구성한다.
#
# 씬 그래프의 프리팹은 에디터에서 저작해야 하지만(에디터 밖에서는 아카타입에
# 컴포넌트를 선언할 수 없다), 런타임에 entity{} 를 만들고 컴포넌트를 붙여
# AddEntities 로 편입시키는 것은 전부 가능하다. 그쪽 경로를 쓴다.

using { /Verse.org }
using { /Verse.org/Verse }
using { /Verse.org/Colors }
using { /Verse.org/Native }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

orbit_system_component<public> := class<final_super>(component):

    # 만들 위성 개수
    @editable
    var SatelliteCount<public>:int = 5

    # 궤도 반지름(cm)
    @editable
    var OrbitRadius<public>:float = 250.0

    # 한 바퀴 도는 데 걸리는 시간(초)
    @editable
    var OrbitPeriod<public>:float = 8.0

    # 위성 라이트 밝기
    @editable
    var SatelliteIntensity<public>:float = 25.0

    @editable
    var UpdateInterval<public>:float = 0.05

    # 위성 하나를 만들어 자식으로 붙이고, 그 트랜스폼 컴포넌트를 돌려준다.
    # AddComponents / AddEntities 가 no_rollback 이라 이 함수도 no_rollback 이 된다.
    # 그래서 실패 컨텍스트(if (X := ...)) 안에서는 호출할 수 없다 -> 옵셔널 반환을 쓰지 않는다.
    MakeSatellite(Index:int):transform_component =
        Child := entity{}

        Tc := transform_component{ Entity := Child }
        Light := sphere_light_component{ Entity := Child }
        # 플레이어가 다가오면 각 위성이 스스로 반응한다
        Prox := player_proximity_component{ Entity := Child }
        Child.AddComponents(array{ Tc, Light, Prox })
        Entity.AddEntities(array{ Child })

        # 초기 색상. 시뮬레이션이 시작되면 player_proximity_component 가 덮어쓴다.
        Hue := 360.0 * Index / (1.0 * SatelliteCount)
        set Light.ColorFilter = MakeColorFromHSV(Hue, 0.9, 1.0)
        set Light.Intensity = SatelliteIntensity
        set Light.SourceRadius = 12.0
        # 감쇠 반경을 좁혀야 위성끼리 빛이 번지지 않고 각각 구분된다
        set Light.AttenuationRadius = option{ 300.0 }

        Tc

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Print("orbit_system_component: 위성 {SatelliteCount} 개 생성", ?Duration := 5.0)

    OnSimulate<override>()<suspends>:void =
        # 1) 위성들을 만든다
        var Satellites:[]transform_component = array{}
        var I:int = 0
        loop:
            if (I >= SatelliteCount):
                break
            Tc := MakeSatellite(I)
            set Satellites = Satellites + array{ Tc }
            set I = I + 1

        Print("생성 완료: {Satellites.Length} 개", ?Duration := 5.0)

        # 2) 궤도를 돈다. 부모 기준 LocalTransform 이라 부모가 움직이면 같이 따라간다.
        var Elapsed:float = 0.0
        loop:
            Sleep(UpdateInterval)
            set Elapsed = Elapsed + UpdateInterval

            BaseAngle := Elapsed / OrbitPeriod * 2.0 * PiFloat

            var K:int = 0
            for (Tc : Satellites):
                # 위성들을 원 위에 균등 배치
                Angle := BaseAngle + 2.0 * PiFloat * K / (1.0 * SatelliteCount)
                Offset := vector3:
                    Forward := OrbitRadius * Cos(Angle)
                    Left    := OrbitRadius * Sin(Angle)
                    Up      := 0.0

                set Tc.LocalTransform = transform:
                    Translation := Offset
                    Rotation := IdentityRotation()
                    Scale := vector3{ Forward := 1.0, Left := 1.0, Up := 1.0 }

                set K = K + 1
