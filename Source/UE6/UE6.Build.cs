// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;

public class UE6 : ModuleRules
{
	public UE6(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

		PublicDependencyModuleNames.AddRange(new string[] {
			"Core",
			"CoreUObject",
			"Engine",
			"InputCore",
			"EnhancedInput",
			"AIModule",
			"StateTreeModule",
			"GameplayStateTreeModule",
			"UMG",
			"Slate",
			// Scene Graph (EntityFramework) - SceneGraphTestUtils 에서 사용
			"Entity",
			"EntityLevel",
			"ActorEntity"
		});

		PrivateDependencyModuleNames.AddRange(new string[] { });

		// AddStaticMeshToEntity 가 쓰는 FAssetComponentHelpers 는 에디터 모듈에만 있다.
		if (Target.bBuildEditor)
		{
			PrivateDependencyModuleNames.Add("EntityEditor");
		}

		PublicIncludePaths.AddRange(new string[] {
			"UE6",
			"UE6/Variant_Platforming",
			"UE6/Variant_Platforming/Animation",
			"UE6/Variant_Combat",
			"UE6/Variant_Combat/AI",
			"UE6/Variant_Combat/Animation",
			"UE6/Variant_Combat/Gameplay",
			"UE6/Variant_Combat/Interfaces",
			"UE6/Variant_Combat/UI",
			"UE6/Variant_SideScrolling",
			"UE6/Variant_SideScrolling/AI",
			"UE6/Variant_SideScrolling/Gameplay",
			"UE6/Variant_SideScrolling/Interfaces",
			"UE6/Variant_SideScrolling/UI",
			"UE6/SceneGraph"
		});

		// Uncomment if you are using Slate UI
		// PrivateDependencyModuleNames.AddRange(new string[] { "Slate", "SlateCore" });

		// Uncomment if you are using online features
		// PrivateDependencyModuleNames.Add("OnlineSubsystem");

		// To include OnlineSubsystemSteam, add it to the plugins section in your uproject file with the Enabled attribute set to true
	}
}
