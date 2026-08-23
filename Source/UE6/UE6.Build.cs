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
			"Slate"
		});

		PrivateDependencyModuleNames.AddRange(new string[] { });

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
			"UE6/Variant_SideScrolling/UI"
		});

		// Uncomment if you are using Slate UI
		// PrivateDependencyModuleNames.AddRange(new string[] { "Slate", "SlateCore" });

		// Uncomment if you are using online features
		// PrivateDependencyModuleNames.Add("OnlineSubsystem");

		// To include OnlineSubsystemSteam, add it to the plugins section in your uproject file with the Enabled attribute set to true
	}
}
