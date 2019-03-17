import 'package:flutter/cupertino.dart';
import 'package:stpt_arrivals/data/cool_down_data_source.dart';
import 'package:stpt_arrivals/presentation/application_state_bloc.dart';
import 'package:stpt_arrivals/services/parser/time_converter.dart';
import 'package:stpt_arrivals/services/restoring_cooldown_manager.dart';

class ApplicationStateWidget extends StatefulWidget {
  final Widget child;

  final ApplicationStateBloc bloc = ApplicationStateBloc(
      RestoringCoolDownManagerImpl(CoolDownDataSourceImpl()),
      SystemTimeProvider());

  ApplicationStateWidget({Key key, this.child}) : super(key: key);

  @override
  _ApplicationStateWidgetState createState() => _ApplicationStateWidgetState();

  static ApplicationStateWidget of(BuildContext context) {
    var inheritFromWidgetOfExactType = context.ancestorWidgetOfExactType(ApplicationStateWidget)
          as ApplicationStateWidget;
    return inheritFromWidgetOfExactType;
  }
}

class _ApplicationStateWidgetState extends State<ApplicationStateWidget> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    widget.bloc.dispose();
    super.dispose();
  }
}
