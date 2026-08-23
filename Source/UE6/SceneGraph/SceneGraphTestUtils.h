// UE6 프로젝트 전용 씬 그래프 자동화 유틸리티.

#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "SceneGraphTestUtils.generated.h"

/**
 *  Scene Graph(EntityFramework) 엔티티를 스크립트에서 다루기 위한 얇은 래퍼.
 *
 *  EntityFramework는 BlueprintCallable / Python API를 하나도 노출하지 않고,
 *  엔티티의 Components 프로퍼티는 protected라 리플렉션으로도 접근할 수 없다.
 *  그래서 에디터 자동화(파이썬, MCP)에 필요한 최소 동작만 여기서 감싼다.
 */
UCLASS()
class USceneGraphTestUtils : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:

	/**
	 *  레벨에 엔티티를 새로 만들고 지정한 컴포넌트들을 붙인다.
	 *  transform_component는 항상 보장된다.
	 *
	 *  @return 생성된 엔티티. 실패하면 nullptr.
	 */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static UObject* SpawnEntityWithComponents(UObject* WorldContextObject, const TArray<UClass*>& ComponentClasses, const FTransform& Transform, FName EntityName);

	/** 엔티티에 컴포넌트를 추가한다. 같은 타입이 이미 있으면 그것을 반환한다. */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static UObject* AddComponentToEntity(UObject* Entity, UClass* ComponentClass);

	/** 엔티티의 월드 트랜스폼을 읽는다. transform_component가 없으면 false. */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static bool GetEntityTransform(UObject* Entity, FTransform& OutTransform);

	/**
	 *  엔티티를 레벨에서 제거한다.
	 *  ALevelEntity::DestroyEntity 를 거쳐야 프록시 액터와 참조 정리까지 처리된다.
	 */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static bool DestroyEntity(UObject* Entity);

	/** 월드의 레벨 루트 엔티티 아래에 있는 모든 엔티티를 반환한다. */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static TArray<UObject*> GetAllEntities(UObject* WorldContextObject);

	/**
	 *  엔티티에 스태틱 메시를 붙여 화면에 보이게 한다(에디터 전용).
	 *
	 *  씬 그래프는 메시를 컴포넌트 프로퍼티로 들고 있지 않고, 에셋마다 전용
	 *  컴포넌트 클래스를 생성해 쓴다. 그 클래스를 찾아주는 헬퍼가 에디터
	 *  모듈에만 있어서 이 함수도 에디터 빌드에서만 동작한다.
	 */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static UObject* AddStaticMeshToEntity(UObject* Entity, UStaticMesh* Mesh);

	/**
	 *  액터에 대응하는 씬 그래프 엔티티를 얻는다. 없으면 만든다.
	 *
	 *  플레이어 폰 같은 평범한 Actor 는 씬 그래프에 존재하지 않는다.
	 *  UActorEntitySubsystem 이 액터<->엔티티 브릿지를 관리하므로 그걸 태운다.
	 */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static UObject* GetOrCreateEntityForActor(AActor* Actor);

	/**
	 *  액터에 UActorEntityComponent 를 붙여 씬 그래프에 브릿지한다.
	 *  UUE6ActorEntitySubsystem 이 인터롭 규칙을 제공해야 실제로 엔티티가 생긴다.
	 */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static UObject* BridgeActorToSceneGraph(AActor* Actor);

	/** 엔티티에 대응하는 액터를 되찾는다. 브릿지된 엔티티가 아니면 nullptr. */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static AActor* FindActorForEntity(UObject* Entity);

	/** 엔티티에 붙어 있는 컴포넌트 목록. */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static TArray<UObject*> GetEntityComponents(UObject* Entity);
};
