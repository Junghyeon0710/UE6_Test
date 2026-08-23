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

#if WITH_EDITOR
#include "AssetRegistry/AssetData.h"
#include "Components/AssetComponentHelpers.h"
#include "Engine/StaticMesh.h"
#endif

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
	if (verse::transform_component* TransformComp = UE::SceneGraphAPI::GetOrCreateComponentByType<verse::transform_component>(Entity))
	{
		TransformComp->SetGlobalFTransform(Transform);
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

	// entity 의 멤버 함수가 아니라 UE::SceneGraphAPI 쪽을 써야 한다.
	// 멤버 함수는 컴포넌트를 붙이기만 하고, 에디터가 변경을 인식하는 데 필요한
	// 알림을 보내지 않아서 레벨에 직렬화되지 않는다.
	return UE::SceneGraphAPI::GetOrCreateComponentByType(Entity, TypedClass);
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

UObject* USceneGraphTestUtils::AddStaticMeshToEntity(UObject* EntityObject, UStaticMesh* Mesh)
{
#if WITH_EDITOR
	verse::entity* Entity = AsEntity(EntityObject);
	if (!Entity || !Mesh)
	{
		return nullptr;
	}

	// 메시 에셋에 대응하는 컴포넌트 클래스를 찾는다.
	// (씬 그래프는 에셋마다 전용 컴포넌트 클래스를 생성해 둔다)
	const TSubclassOf<verse::component> MeshComponentClass =
		FAssetComponentHelpers::FindAssetComponentChildClassForAssetData(FAssetData(Mesh));

	if (!MeshComponentClass)
	{
		return nullptr;
	}

	return UE::SceneGraphAPI::GetOrCreateComponentByType(Entity, MeshComponentClass);
#else
	return nullptr;
#endif
}

bool USceneGraphTestUtils::DestroyEntity(UObject* EntityObject)
{
	verse::entity* Entity = AsEntity(EntityObject);
	if (!Entity)
	{
		return false;
	}

	ALevelEntity* LevelEntityActor = ALevelEntity::GetLevelEntityActor(Entity);
	if (!LevelEntityActor)
	{
		return false;
	}

	LevelEntityActor->DestroyEntity(Entity);
	return true;
}
