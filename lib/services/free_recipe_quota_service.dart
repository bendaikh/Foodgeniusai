import 'recipe_access_service.dart';

/// Compatibility wrapper around [RecipeAccessService].
class FreeRecipeQuotaService {
  FreeRecipeQuotaService._();
  static final FreeRecipeQuotaService instance = FreeRecipeQuotaService._();

  Future<bool> hasUsedFreeRecipe() {
    return RecipeAccessService.instance.hasUsedFreeRecipe();
  }

  Future<void> markUsed() {
    return RecipeAccessService.instance.markFreeRecipeUsed();
  }
}
