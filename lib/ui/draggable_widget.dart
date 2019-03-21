import 'package:flutter/cupertino.dart';

class DraggableWidget extends StatefulWidget {
  final Widget child;
  final Widget feedback;
  final Widget childWhenDragging;
  final Offset initialPosition;
  final Rect bounds;

  DraggableWidget(
      {Key key,
      this.child,
      this.feedback,
      this.childWhenDragging,
      this.initialPosition,
      this.bounds})
      : super(key: key);

  factory DraggableWidget.simple(Widget child, Offset initialPosition, Rect bounds) =>
      DraggableWidget(
        child: child,
        feedback: child,
        childWhenDragging: Container(),
        initialPosition: initialPosition,
        bounds: bounds,
      );

  @override
  _DraggableWidgetState createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget> {
  Offset offset;

  @override
  void initState() {
    super.initState();
    if (offset == null) {
      offset = widget.initialPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: offset.dx,
        top: offset.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            final candidate = Offset(
                offset.dx + details.delta.dx, offset.dy + details.delta.dy);
            final rect =widget.bounds;
           // print("r:$rect\nc:$candidate");
            //if (rect.contains(details.globalPosition))
              setState(() {
                offset = candidate;
              });
          },
          child: widget.child,
        ));
  }
}
