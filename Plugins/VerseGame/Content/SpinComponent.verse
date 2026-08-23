# 엔티티를 Yaw 축으로 계속 회전시키는 Scene Graph 컴포넌트.
# 같은 엔티티에 transform_component 가 있어야 동작한다.

using { /Verse.org }
using { /Verse.org/Verse }
using { /Verse.org/Native }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }
using { /Verse.org/SpatialMath }

spin_component<public> := class<final_super>(component):

    # 초당 회전 각도(도)
    @editable
    var DegreesPerSecond<public>:float = 90.0

    # 회전을 갱신하는 주기(초). 작을수록 부드럽고 비용이 크다.
    @editable
    var UpdateInterval<public>:float = 0.05

    OnSimulate<override>()<suspends>:void =
        if (TransformComponent := Entity.GetComponent[transform_component]):
            var Yaw:float = 0.0
            loop:
                Sleep(UpdateInterval)
                set Yaw = Yaw + DegreesPerSecond * UpdateInterval
                var LocalTransform:transform = TransformComponent.LocalTransform
                set LocalTransform.Rotation = MakeRotationFromYawPitchRollDegrees(Yaw, 0.0, 0.0)
                set TransformComponent.LocalTransform = LocalTransform
        else:
            Print("spin_component: 같은 엔티티에 transform_component 가 없습니다")
