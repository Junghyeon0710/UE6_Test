// 액터를 씬 그래프에 브릿지하기 위한 인터롭 규칙 제공자.

#pragma once

#include "ActorEntitySubsystem.h"

#include "UE6ActorEntitySubsystem.generated.h"

/**
 *  UActorEntitySubsystem 은 Abstract 이고 엔진에 구체 서브클래스가 없다.
 *  그래서 액터<->엔티티 인터롭 전체가 동작하지 않는다.
 *
 *  이 클래스가 구체 구현을 제공해 서브시스템이 실제로 생성되게 하고,
 *  어떤 액터를 씬 그래프로 브릿지할지 규칙을 돌려준다.
 */
UCLASS()
class UUE6ActorEntitySubsystem : public UActorEntitySubsystem
{
	GENERATED_BODY()

public:

	//~ Begin UActorEntitySubsystem
	virtual const TArray<FActorEntityInteropRules>& GetActorEntityInteropRules() const override;
	//~ End UActorEntitySubsystem

private:

	/** 최초 조회 시 한 번 구성한다. */
	mutable TArray<FActorEntityInteropRules> CachedRules;
};
