// UE6 프로젝트 전용 씬 그래프 자동화 유틸리티.

#include "SceneGraphTestUtils.h"

#include "Component.h"
#include "Entity.h"
#include "LevelEntity.h"
#include "SceneGraphUtil.h"
#include "TransformEntityComponent.h"

#include "Engine/Engine.h"
#include "Engine/Level.h"
#include "Engine/World.h"

namespace
{
	/** UObject 를 엔티티로 안전하게 캐스팅한다. */
	verse::entity* AsEntity(UObject* Object)
	{
		return Cast<verse::entity>(Object);
	}

	/** WorldContextObject 에서 월드를 얻는다. */
	UWorld* ResolveWorld(UObject* WorldContextObject)
	{
		if (!WorldContextObject)
		{
			return nullptr;
		}

		return GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
	}
}

UObject* USceneGraphTestUtils::SpawnEntityWithComponents(UObject* WorldContextObject, const TArray<UClass*>& ComponentClasses, const FTransform& Transform, FName EntityName)
{
	UWorld* World = ResolveWorld(WorldContextObject);
	if (!World || !World->PersistentLevel)
	{
		return nullptr;
	}

	UE::SceneGraphUtil::FCreateEntityParams Params(World);
	Params.SetInitialTransform(Transform);

	if (!EntityName.IsNone())
	{
		Params.SetEntityName(EntityName);
	}

	verse::entity* Entity = UE::SceneGraphUtil::CreateEntity(Params);

	// 트랜스폼 컴포넌트가 있어야 엔티티가 씬에서 위치를 가진다.
	if (verse::component* TransformComp = Entity->GetOrCreateComponentByType(verse::transform_component::StaticClass()))
	{
		CastChecked<verse::transform_component>(TransformComp)->SetGlobalFTransform(Transform);
	}

	for (UClass* ComponentClass : ComponentClasses)
	{
		AddComponentToEntity(Entity, ComponentClass);
	}

	return Entity;
}

UObject* USceneGraphTestUtils::AddComponentToEntity(UObject* EntityObject, UClass* ComponentClass)
{
	verse::entity* Entity = AsEntity(EntityObject);
	if (!Entity || !ComponentClass)
	{
		return nullptr;
	}

	// TSubclassOf 는 component 파생이 아니면 Get() 에서 nullptr 을 돌려준다.
	const TSubclassOf<verse::component> TypedClass(ComponentClass);
	if (!TypedClass.Get())
	{
		return nullptr;
	}

	return Entity->GetOrCreateComponentByType(TypedClass);
}

bool USceneGraphTestUtils::GetEntityTransform(UObject* EntityObject, FTransform& OutTransform)
{
	verse::entity* Entity = AsEntity(EntityObject);
	if (!Entity)
	{
		return false;
	}

	return UE::SceneGraphUtil::GetEntityTransform(Entity, OutTransform);
}

TArray<UObject*> USceneGraphTestUtils::GetAllEntities(UObject* WorldContextObject)
{
	TArray<UObject*> Result;

	UWorld* World = ResolveWorld(WorldContextObject);
	if (!World || !World->PersistentLevel)
	{
		return Result;
	}

	ALevelEntity* LevelEntityActor = ALevelEntity::GetLevelEntityActor(World->PersistentLevel);
	if (!LevelEntityActor)
	{
		return Result;
	}

	FForEachEntityHelper::ForEachEntityAndDescendants(LevelEntityActor->GetLevelEntity(), [&Result](TNotNull<verse::entity*> Entity)
	{
		Result.Add(Entity);
		return true;
	});

	return Result;
}

TArray<UObject*> USceneGraphTestUtils::GetEntityComponents(UObject* EntityObject)
{
	TArray<UObject*> Result;

	verse::entity* Entity = AsEntity(EntityObject);
	if (!Entity)
	{
		return Result;
	}

	for (const TNonNullPtr<verse::component>& Component : Entity->GetComponents())
	{
		Result.Add(Component);
	}

	return Result;
}
