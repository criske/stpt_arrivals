import 'dart:math';

import 'package:flutter/cupertino.dart';

class DraggableWidget extends StatefulWidget {
  final Widget child;
  final Rect draggingBounds;
  final Size draggableWidgetSize;
  final Alignment alignment;
  final EdgeInsets padding;

  DraggableWidget({
    Key key,
    @required this.child,
    @required this.draggingBounds,
    @required this.draggableWidgetSize,
    this.alignment = const Alignment(0, 0),
    this.padding = const EdgeInsets.all(0)
  }) : super(key: key);

  @override
  _DraggableWidgetState createState() => _DraggableWidgetState();
}

//todo need to work about screen orientation
class _DraggableWidgetState extends State<DraggableWidget> {
  Offset offset;

  @override
  void initState() {
    super.initState();

    offset = widget.alignment.withinRect(widget.draggingBounds);
    //center the offset around the alignment point
    offset = offset +
        Offset(max(0, -widget.draggableWidgetSize.width / 2),
            max(0, -widget.draggableWidgetSize.height / 2));

    offset = offset.translate(widget.padding.left, widget.padding.top);

    if (offset.dy + widget.draggableWidgetSize.height >
        widget.draggingBounds.height) {
      offset = Offset(
          offset.dx,
          widget.draggingBounds.height -
              ((offset.dy + widget.draggableWidgetSize.height) -
                  widget.draggingBounds.height ));
    }

    if (offset.dx + widget.draggableWidgetSize.width >
        widget.draggingBounds.width) {
      offset = Offset(
          widget.draggingBounds.width -
              ((offset.dx + widget.draggableWidgetSize.width) -
                  widget.draggingBounds.width),
          offset.dy);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: offset.dx,
        top: offset.dy,
        child: Container(
          width: widget.draggableWidgetSize.width,
          height: widget.draggableWidgetSize.height,
          child: GestureDetector(
            onPanUpdate: (details) {
              final candidate = offset + details.delta;
              final rect = widget.draggingBounds;
              if (rect.contains(candidate) &&
                  rect.contains(candidate +
                      Offset(widget.draggableWidgetSize.width,
                          widget.draggableWidgetSize.height)))
                setState(() {
                  offset = candidate;
                });
            },
            child: widget.child,
          ),
        ));
  }
}
