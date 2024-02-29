import 'package:flutter/material.dart';
import 'package:indexed/indexed.dart';

// FlipAnimation 위젯 정의
class FlipAnimation extends StatefulWidget {
  final List<Color> colors;

  const FlipAnimation({
    required this.colors,
    Key? key,
  }) : super(key: key);

  @override
  State<FlipAnimation> createState() => _FlipAnimationState();
}

class _FlipAnimationState extends State<FlipAnimation>
    with TickerProviderStateMixin {
  late List<FlipCard> dataSource;
  late List<double> tops;
  late List<double> lefts;
  late List<double> widths;
  late List<double> heights;
  late List<int> indexes;
  late List<UniqueKey> flipKeys;
  late double size;
  late AnimationController _handleUpController;
  late AnimationController _switchingIndexController;
  late AnimationController _handleDownController;
  double newDx = 0;
  double newDy = 0;
  late Offset center;
  double initialTop = 500;
  double initialLeft = 0;
  late double lastLeft;
  int rotatingCount = 1;
  int animatingSpeed = 500;

  @override
  void initState() {
    super.initState();
    initializeVariables();
    initializeControllers();
    createCards();
  }

  // 필드 변수 초기화 함수
  void initializeVariables() {
    size = 300;
    double initialWidth = size;
    double initialHeight = size / 3 * 2;
    tops = List.generate(widget.colors.length,
        (index) => initialTop + index * (size / (size / 20)));
    lefts = List.generate(
        widget.colors.length, (index) => initialLeft - index * (size / 20));
    lastLeft = lefts.last;
    widths = List.generate(widget.colors.length,
        (index) => initialWidth + (index * initialWidth / 10));
    heights = List.generate(widget.colors.length,
        (index) => initialHeight + (index * initialHeight / 10));
    indexes = List.generate(widget.colors.length, (index) => index);
    flipKeys = List.generate(widget.colors.length, (index) => UniqueKey());
  }

  // 애니메이션 컨트롤러 초기화 함수
  void initializeControllers() {
    _handleUpController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: animatingSpeed),
    );

    _switchingIndexController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0),
    );

    _handleDownController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: animatingSpeed),
    );
  }

  // 카드 생성 함수
  void createCards() {
    dataSource = List.generate(widget.colors.length, (index) {
      return FlipCard(
        color: widget.colors[index],
        top: tops[index],
        left: lefts[index],
        width: widths[index],
        height: heights[index],
        index: indexes[index],
        flipKey: flipKeys[index],
      );
    });
  }

  // 위쪽 탭 처리 함수
  void _handleUpTap(int index) {
    double firstCenterX = lefts.first - (widths.first / 2);
    double lastCenterX = lefts.last - (widths.last / 2);
    double diffX = firstCenterX - lastCenterX;
    setState(() {
      dataSource[index] = dataSource[index].copyWith(
        top: 0 + (size / 3),
        left: diffX == 0
            ? lastLeft
            : diffX > 0
                ? (lefts.last - firstCenterX) / 2
                : (firstCenterX + widths.last / 2) / 2,
        width: size / 1.2,
        height: size / 3 * 2 / 1.2,
      );
      _handleUpController.reset();
      _handleUpController.forward().then((_) {
        _switchingIndexTap(index);
      });
    });
  }

  // 카드 전환 처리 함수
  void _switchingIndexTap(int index) {
    for (int i = 0; i < dataSource.length; i++) {
      if (dataSource[i].index == dataSource.length - 1) {
        dataSource[i] = dataSource[i].copyWith(
          index: indexes[0],
        );
      } else {
        dataSource[i] = dataSource[i].copyWith(
          index: dataSource[i].index + 1,
        );
      }
    }
    _switchingIndexController.reset();
    _switchingIndexController.forward().then((_) {
      _handleDownTap(index);
    });
  }

  // 아래쪽 탭 처리 함수
  void _handleDownTap(int index) {
    setState(() {
      for (int i = 0; i < dataSource.length; i++) {
        if (dataSource[i].index == 0) {
          dataSource[i] = dataSource[i].copyWith(
            top: tops[0],
            left: lefts[0],
            width: widths[0],
            height: heights[0],
          );
        } else {
          dataSource[i] = dataSource[i].copyWith(
            top: tops[dataSource[i].index],
            left: lefts[dataSource[i].index],
            width: widths[dataSource[i].index],
            height: heights[dataSource[i].index],
          );
        }
      }
      _handleDownController.reset();
      _handleDownController.forward();
    });
  }

  //PanUpdate 위치 변형 함수
  void getWidgetsPositions(DragUpdateDetails details) {
    setState(() {
      newDx = details.globalPosition.dx;
      newDy = details.globalPosition.dy;
      double diffX = (center.dx - newDx).clamp(-20, 50);
      double diffY = (center.dy - newDy).clamp(-20, 40);
      tops = List.generate(
          widget.colors.length, (index) => initialTop - index * (diffY));
      lefts = List.generate(
          widget.colors.length, (index) => initialLeft - index * (diffX));
      for (int i = 0; i < dataSource.length; i++) {
        dataSource[i] = dataSource[i].copyWith(
            top: tops[dataSource[i].index], left: lefts[dataSource[i].index]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    center =
        Offset(screenWidth / 2, screenHeight - initialTop + heights.first / 2);
    double radius = size * 0.1;
    return Indexer(children: [
      ...dataSource.map((data) {
        int index = dataSource.indexOf(data);
        return Indexed(
          key: data.flipKey,
          index: data.index,
          child: AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            top: data.top,
            left: screenWidth / 2 + data.left - widths.first / 2,
            curve: Curves.easeInOut,
            child: _buildCardWidget(data, _handleDownController, radius, index),
          ),
        );
      }).toList(),
    ]);
  }

  Widget _buildGeneralWidget(FlipCard data, double radius) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: data.color,
      ),
    );
  }

  Widget _buildRotatedWidget(
      FlipCard data, Animation<double> animation, double radius) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: rotatingCount / 2)
          .animate(animation), //end값을 증가 시키면 회전 수 변경
      child: _buildGeneralWidget(data, radius),
    );
  }

  Widget _buildCardWidget(
      FlipCard data, Animation<double> animation, double radius, int index) {
    return GestureDetector(
      onTap: () {
        _handleUpTap(index);
      },
      onPanUpdate: (details) {
        getWidgetsPositions(details);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: data.width,
        height: data.height,
        curve: Curves.easeInOut,
        child: data.index == 0
            ? _buildRotatedWidget(data, _handleDownController, radius)
            : data.index == dataSource.length - 1
                ? _buildRotatedWidget(data, _handleUpController, radius)
                : _buildGeneralWidget(data, radius),
      ),
    );
  }

  @override
  void dispose() {
    _handleUpController.dispose();
    _switchingIndexController.dispose();
    _handleDownController.dispose();
    super.dispose();
  }
}

// FlipCard 클래스 정의
class FlipCard {
  final Color color;
  final double top;
  final double left;
  final double width;
  final double height;
  final int index;
  final UniqueKey flipKey;

  FlipCard({
    required this.color,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    required this.index,
    required this.flipKey,
  });

  FlipCard copyWith({
    Color? color,
    double? top,
    double? left,
    double? width,
    double? height,
    int? index,
    UniqueKey? flipKey,
  }) {
    return FlipCard(
      color: color ?? this.color,
      top: top ?? this.top,
      left: left ?? this.left,
      width: width ?? this.width,
      height: height ?? this.height,
      index: index ?? this.index,
      flipKey: flipKey ?? this.flipKey,
    );
  }
}
