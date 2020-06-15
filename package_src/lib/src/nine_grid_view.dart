import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// NineGridView Type.
enum NineGridType {
  /// normal.
  normal,

  /// like WeChat.
  weChat,

  /// like WeiBo International.
  weiBo,

  /// like WeChat group.
  weChatGp,

  /// like DingTalk group.
  dingTalkGp,
}

/// big image size cache map.
Map<String, Rect> ngvBigImageSizeMap = HashMap();

/// NineGridView
/// like WeChat, WeiBo International, WeChat group, DingTalk group.
///
class NineGridView extends StatefulWidget {
  /// create NineGridView.
  /// If you want to show a single big picture.
  /// It is recommended to use a medium-quality picture, because the original picture is too large and takes time to load.
  /// 单张大图建议使用中等质量图片，因为原图太大加载耗时。
  /// you need input (bigImageWidth + bigImageHeight) or (bigImage + bigImageUrl).
  NineGridView({
    Key key,
    this.width,
    this.height,
    this.space: 3,
    this.padding: EdgeInsets.zero,
    this.margin: EdgeInsets.zero,
    this.alignment,
    this.color,
    this.decoration,
    this.type: NineGridType.weChat,
    @required this.itemCount,
    @required this.itemBuilder,
    this.bigImageWidth,
    this.bigImageHeight,
    this.bigImage,
    this.bigImageUrl,
  })  : assert(type != null),
        assert(itemCount == null || itemCount >= 0),
        assert(itemBuilder != null),
        super(key: key);

  /// View width.
  final double width;

  /// View height.
  final double height;

  /// The number of logical pixels between each child.
  final double space;

  /// View padding.
  final EdgeInsets padding;

  /// View margin.
  final EdgeInsets margin;

  /// Align the [child] within the container.
  final AlignmentGeometry alignment;

  /// The color to paint behind the [child].
  final Color color;

  /// The decoration to paint behind the [child].
  final Decoration decoration;

  /// NineGridView type.s
  final NineGridType type;

  /// The total number of children this delegate can provide.
  final int itemCount;

  /// Called to build children for the view.
  final IndexedWidgetBuilder itemBuilder;

  /// Single big picture width.
  final int bigImageWidth;

  /// Single big picture height.
  final int bigImageHeight;

  /// It is recommended to use a medium-quality picture, because the original picture is too large and takes time to load.
  /// 单张大图建议使用中等质量图片，因为原图太大加载耗时。
  /// Single big picture Image.
  final Image bigImage;

  /// Single big picture url.
  final String bigImageUrl;

  @override
  State<StatefulWidget> createState() {
    return _NineGridViewState();
  }
}

/// _NineGridViewState.
class _NineGridViewState extends State<NineGridView> {
  ///  build nine grid view.
  Widget _buildChild(BuildContext context) {
    int itemCount = math.min(9, widget.itemCount);
    int crossAxisCount = 3;
    bool weChatFour = false;
    switch (widget.type) {
      case NineGridType.weChat:
        if (itemCount == 4) {
          weChatFour = true;
        }
        break;
      case NineGridType.weiBo:
        if (itemCount == 2 || itemCount == 4) {
          crossAxisCount = 2;
        }
        break;
    }
    return GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: widget.space,
          crossAxisSpacing: widget.space,
        ),
        itemCount: itemCount + (weChatFour ? 1 : 0),
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {
          if (weChatFour) {
            if (index == 2) {
              return Container();
            } else if (index > 2) {
              return widget.itemBuilder(context, index - 1);
            }
          }
          return widget.itemBuilder(context, index);
        });
  }

  /// build one child.
  Widget _buildOneChild(BuildContext context) {
    double bigImgWidth = widget.bigImageWidth?.toDouble();
    double bigImgHeight = widget.bigImageHeight?.toDouble();
    if (!_isZero(bigImgWidth) && !_isZero(bigImgHeight)) {
      return _getOneChild(context, bigImgWidth, bigImgHeight);
    } else if (widget.bigImage != null) {
      String bigImageUrl = widget.bigImageUrl;
      Rect bigImgRect = ngvBigImageSizeMap[bigImageUrl];
      bigImgWidth = bigImgRect?.width;
      bigImgHeight = bigImgRect?.height;
      if (!_isZero(bigImgWidth) && !_isZero(bigImgHeight)) {
        return _getOneChild(context, bigImgWidth, bigImgHeight);
      } else {
        _ImageUtil().getImageSize(widget.bigImage).then((rect) {
          ngvBigImageSizeMap[bigImageUrl] = rect;
          if (!mounted) return;
          setState(() {});
        }).catchError((e) {});
      }
    }
    return _buildChild(context);
  }

  /// get one child.
  Widget _getOneChild(BuildContext context, double width, double height) {
    Rect rect = _getBigImgSize(width, height);
    return SizedBox(
      width: rect.width,
      height: rect.height,
      child: widget.itemBuilder(context, 0),
    );
  }

  /// build weChat group.
  Widget _buildWeChatGroup(BuildContext context) {
    int itemCount = math.min(9, widget.itemCount);
    int crossAxisCount = 3;
    if (itemCount == 1) {
      crossAxisCount = 1;
    } else if (itemCount < 5) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }
    double itemWidth = (widget.width -
            widget.padding.left -
            widget.padding.right -
            (crossAxisCount - 1) * widget.space) /
        crossAxisCount;
    List<Widget> children = List();
    for (int i = 0; i < itemCount; i++) {
      children.add(SizedBox(
        width: itemWidth,
        height: itemWidth,
        child: widget.itemBuilder(context, i),
      ));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.end,
          verticalDirection: VerticalDirection.up,
          spacing: widget.space,
          runSpacing: widget.space,
          children: children,
        )
      ],
    );
  }

  /// build dingTalk group.
  Widget _buildDingTalkGroup(BuildContext context) {
    double width = widget.width - widget.padding.left - widget.padding.right;
    int itemCount = math.min(4, widget.itemCount);
    double itemW = (width - widget.space) / 2;
    List<Widget> children = List();
    for (int i = 0; i < itemCount; i++) {
      children.add(Positioned(
          top: (widget.space + itemW) * (i ~/ 2),
          left: (widget.space + itemW) *
              (((itemCount == 3 && i == 2) ? i + 1 : i) % 2),
          child: SizedBox(
            width: itemCount == 1 ? width : itemW,
            height:
                (itemCount == 1 || itemCount == 2 || (itemCount == 3 && i == 0))
                    ? width
                    : itemW,
            child: widget.itemBuilder(context, i),
          )));
    }
    return ClipOval(
      child: Stack(
        children: children,
      ),
    );
  }

  /// double is zero.
  bool _isZero(double value) {
    return value == null || value == 0;
  }

  /// get big image size.
  Rect _getBigImgSize(double originalWidth, double originalHeight) {
    double width = widget.width ??
        (MediaQuery.of(context).size.width -
            widget.margin.left -
            widget.margin.right);
    width = width - widget.padding.left - widget.padding.right;
    double itemW = (width - widget.space * 2) / 3;

    //double devicePixelRatio = MediaQuery.of(context)?.devicePixelRatio ?? 3;
    double devicePixelRatio = 1.0;
    double tempWidth = originalWidth / devicePixelRatio;
    double tempHeight = originalHeight / devicePixelRatio;
    double maxW = itemW * 2 + widget.space;
    double minW = width / 2;

    double relWidth = tempWidth >= maxW ? maxW : math.max(minW, tempWidth);

    double relHeight;
    double ratio = tempWidth / tempHeight;
    if (tempWidth == tempHeight) {
      relHeight = relWidth;
    } else if (tempWidth > tempHeight) {
      relHeight = relWidth / (math.min(ratio, 4 / 3));
    } else {
      relHeight = relWidth / (math.max(ratio, 3 / 4));
    }
    return Rect.fromLTRB(0, 0, relWidth, relHeight);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Container();
    switch (widget.type) {
      case NineGridType.normal:
      case NineGridType.weiBo:
      case NineGridType.weChat:
        if (widget.itemCount == 1) {
          child = _buildOneChild(context);
        } else {
          child = _buildChild(context);
        }
        break;
      case NineGridType.weChatGp:
        child = _buildWeChatGroup(context);
        break;
      case NineGridType.dingTalkGp:
        child = _buildDingTalkGroup(context);
        break;
    }
    return Container(
      alignment: widget.alignment,
      color: widget.color,
      decoration: widget.decoration,
      margin: widget.margin,
      padding: widget.padding,
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }
}

/// image util.
class _ImageUtil {
  ImageStreamListener listener;
  ImageStream imageStream;

  /// get image size.
  Future<Rect> getImageSize(Image image) {
    if (image == null) {
      return null;
    }
    Completer<Rect> completer = Completer<Rect>();
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        imageStream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete(Rect.fromLTWH(
              0, 0, info.image.width.toDouble(), info.image.height.toDouble()));
        }
      },
      onError: (dynamic exception, StackTrace stackTrace) {
        imageStream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.completeError(exception, stackTrace);
        }
      },
    );
    imageStream = image.image.resolve(ImageConfiguration());
    imageStream.addListener(listener);
    return completer.future;
  }
}
