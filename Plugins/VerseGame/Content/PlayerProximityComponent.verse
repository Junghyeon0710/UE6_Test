# 플레이어와의 거리에 따라 라이트를 바꾼다.
#
# 플레이어 폰은 UActorEntityComponent + UActorEntityPrefabComponent 로 씬 그래프에
# 브릿지되어 LevelEntity 트리 안에 들어와 있다. 그래서 트리 순회로 찾을 수 있다.
# 식별은 possessable_component 유무로 한다 - 브릿지된 폰에만 자동으로 붙는다.

using { /Verse.org }
using { /Verse.org/Verse }
using { /Verse.org/Colors }
using { /Verse.org/Native }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

player_proximity_component<public> := class<final_super>(component):

    # 이 거리 안에 들어오면 최대 반응
    @editable
    var NearDistance<public>:float = 200.0

    # 이 거리 밖이면 반응 없음
    @editable
    var FarDistance<public>:float = 1200.0

    @editable
    var NearIntensity<public>:float = 90.0

    @editable
    var FarIntensity<public>:float = 4.0

    @editable
    var UpdateInterval<public>:float = 0.1

    # 트리 최상단까지 올라간다.
    # var 를 쓰면 allocates 이펙트가 붙어서 <reads> 로는 선언할 수 없다.
    FindRoot(From:entity)<transacts>:entity =
        var Current:entity = From
        loop:
            if (Parent := Current.GetParent[]):
                set Current = Parent
            else:
                break
        Current

    # 서브트리의 모든 엔티티를 평탄하게 모은다
    CollectAll(Root:entity)<transacts>:[]entity =
        var Result:[]entity = array{ Root }
        for (Child : Root.GetEntities()):
            set Result = Result + CollectAll(Child)
        Result

    # possessable_component 를 가진 첫 엔티티 = 브릿지된 플레이어
    FindPossessable(Root:entity)<transacts>:?entity =
        var Found:?entity = false
        for (E : CollectAll(Root)):
            if (not Found?, E.GetComponent[possessable_component]):
                set Found = option{ E }
        Found

    # 엔티티의 월드 위치
    GetWorldLocation(E:entity)<reads><decides>:vector3 =
        Tc := E.GetComponent[transform_component]
        Tc.GlobalTransform.Translation

    OnBeginSimulation<override>():void =
        (super:)OnBeginSimulation()
        Print("player_proximity_component: 시작", ?Duration := 4.0)

    OnSimulate<override>()<suspends>:void =
        if (Light := Entity.GetComponent[sphere_light_component]):
            Root := FindRoot(Entity)

            loop:
                Sleep(UpdateInterval)

                if:
                    Player := FindPossessable(Root)?
                    MyPos := GetWorldLocation[Entity]
                    PlayerPos := GetWorldLocation[Player]
                then:
                    Dist := Distance(MyPos, PlayerPos)

                    # 거리를 0(가까움)..1(멂) 로 정규화
                    Raw := (Dist - NearDistance) / (FarDistance - NearDistance)
                    T := if (Raw < 0.0) then 0.0 else if (Raw > 1.0) then 1.0 else Raw

                    set Light.Intensity = NearIntensity + (FarIntensity - NearIntensity) * T
                    # 가까우면 붉게, 멀면 푸르게 (색상환 0도 -> 220도)
                    set Light.ColorFilter = MakeColorFromHSV(220.0 * T, 0.9, 1.0)
                else:
                    # 플레이어를 못 찾으면 어둡게 두고 계속 감시
                    set Light.Intensity = FarIntensity
        else:
            Print("player_proximity_component: sphere_light_component 가 없습니다")
