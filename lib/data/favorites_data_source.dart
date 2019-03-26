import 'package:stpt_arrivals/data/string_data_source.dart';

abstract class FavoritesDataSource extends StringDataSource {}

class FavoritesDataSourceImpl extends StringDataSourceImpl
    implements FavoritesDataSource {
  static const _favoritesKey = "FAVORITES_KEY";

  static final FavoritesDataSourceImpl _singleton =
      FavoritesDataSourceImpl._internal();

  factory FavoritesDataSourceImpl() => _singleton;

  FavoritesDataSourceImpl._internal();

  @override
  String get key => _favoritesKey;
}
