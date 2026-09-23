import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/failure_mapper.dart';
import 'package:colette/features/diversification/data/data_sources/catalog_asset_data_source.dart';
import 'package:colette/features/diversification/data/dtos/food_catalog_dto.dart';
import 'package:colette/features/diversification/domain/entities/food_catalog.dart';
import 'package:colette/features/diversification/domain/repositories/food_catalog_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Catalogue lu depuis l'asset JSON.
class AssetFoodCatalogRepository implements FoodCatalogRepository {
  const AssetFoodCatalogRepository(this._source);

  final CatalogAssetDataSource _source;

  @override
  Future<Either<Failure, FoodCatalog>> load() =>
      guard(() async => FoodCatalogDto.fromJson(await _source.load()));
}
