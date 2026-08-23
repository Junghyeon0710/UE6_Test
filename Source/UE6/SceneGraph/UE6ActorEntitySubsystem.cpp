// 액터를 씬 그래프에 브릿지하기 위한 인터롭 규칙 제공자.

#include "UE6ActorEntitySubsystem.h"

#include "TransformEntityComponent.h"

#include "GameFramework/Character.h"

const TArray<FActorEntityInteropRules>& UUE6ActorEntitySubsystem::GetActorEntityInteropRules() const
{
	if (CachedRules.Num() == 0)
	{
		// 규칙은 IsChildOf 로 매칭된다. ACharacter 를 걸어두면 템플릿의
		// BP_ThirdPersonCharacter 도 함께 잡힌다.
		FActorEntityInteropRules& Rule = CachedRules.AddDefaulted_GetRef();
		Rule.ActorClass = ACharacter::StaticClass();
		Rule.ActorEntityConsidered = EConsideredForActorEntityInterop::Yes;
		Rule.AllowedEntityComponents.Add(verse::transform_component::StaticClass());
		Rule.bEnableEntityReplication = false;
	}

	return CachedRules;
}
