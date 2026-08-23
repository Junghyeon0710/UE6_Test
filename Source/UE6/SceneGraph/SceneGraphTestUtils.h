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

	/** 월드의 레벨 루트 엔티티 아래에 있는 모든 엔티티를 반환한다. */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static TArray<UObject*> GetAllEntities(UObject* WorldContextObject);

	/** 엔티티에 붙어 있는 컴포넌트 목록. */
	UFUNCTION(BlueprintCallable, Category="SceneGraph|Test")
	static TArray<UObject*> GetEntityComponents(UObject* Entity);
};
