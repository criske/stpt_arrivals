import 'package:stpt_arrivals/data/transporter_repository.dart';
import 'package:stpt_arrivals/models/transporter.dart';
import 'package:test_api/test_api.dart';

void main() {
  TransporterRepository repository;

  setUp(() async {
    repository = TransporterRepositoryImpl();
    await repository.save([
      Transporter(1, "1", TransporterType.bus),
      Transporter(2, "2", TransporterType.tram),
      Transporter(3, "3", TransporterType.trolley),
      Transporter(4, "4", TransporterType.boat),
    ]);
  });

  test("should get all transporters", () async {
    final all = await repository.findAll();
    expect(all, [
      Transporter(1, "1", TransporterType.bus),
      Transporter(2, "2", TransporterType.tram),
      Transporter(3, "3", TransporterType.trolley),
      Transporter(4, "4", TransporterType.boat),
    ]);
  });

  test("should get all transporters by type", () async {
    final all = await repository.findAllByType(TransporterType.bus);
    expect(all, [Transporter(1, "1", TransporterType.bus)]);
  });

  test("should get all transporters by fav", () async {
    await repository.update(Transporter(1, "1", TransporterType.bus, true));
    final all = await repository.findAllByFavorites();
    expect(all, [Transporter(1, "1", TransporterType.bus, true)]);
  });

  test("should fail when updating a nonexisting transporter", () async {
    try {
      var transporter = Transporter(5, "5", TransporterType.bus, true);
      await repository.update(transporter);
      fail("Expected to fail for transporter with id ${transporter.id}");
    } catch (_) {}
  });
}
