import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:infosha/screens/home/SectonView/src/sectionViewTip.dart';

import 'sectionViewAlphabetList.dart';
import 'sectionViewModel.dart';
import 'package:characters/characters.dart';

class SectionView<T, N> extends StatefulWidget {
  SectionView(
      {required this.source,
      required this.onFetchListData,
      required this.headerBuilder,
      required this.itemBuilder,
      this.refreshBuilder,
      this.alphabetAlign = Alignment.center,
      this.alphabetInset = const EdgeInsets.all(4.0),
      this.enableSticky = true,
      this.alphabetBuilder,
      this.tipBuilder,
      this.physics,
      this.scrollBehavior,
      this.onChange,
      Key? key})
      : super(key: key);

  final List<T> source;
  final SectionViewOnFetchListData<T, N> onFetchListData;
  final SectionViewHeaderBuilder<T> headerBuilder;
  final SectionViewItemBuilder<T, N> itemBuilder;
  final SectionViewAlphabetBuilder<T>? alphabetBuilder;
  final SectionViewTipBuilder<T>? tipBuilder;
  final SectionViewRefreshBuilder? refreshBuilder;
  final bool enableSticky;
  final Alignment alphabetAlign;
  final EdgeInsets alphabetInset;
  var onChange;

  /// Inherit from scrollview
  final ScrollPhysics? physics;
  final ScrollBehavior? scrollBehavior;

  @override
  _SectionViewState<T, N> createState() => _SectionViewState<T, N>();
}

class _SectionViewState<T, N> extends State<SectionView> {
  final FlutterListViewController _controller = FlutterListViewController();

  /// listData will used to bind [ScrollablePositionedList]
  List<SectionViewData> _listData = [];

  /// Map header to index of [ScrollablePositionedList]
  List<AlphabetModel<T>> _headerToIndexMap = [];

  final alphabetTipKey = GlobalKey<SectionViewTipState>();
  final sectionViewAlphabetListKey = GlobalKey<SectionViewAlphabetListState>();

  SectionView<T, N> get ownWidget {
    return widget as SectionView<T, N>;
  }

  _buildList() {
    List<SectionViewData> _buildData = [];
    List<AlphabetModel<T>> _buildMap = [];
    int _headerIndex = 0;
    int _listIndex = 0;

    for (T _header in ownWidget.source) {
      _buildData.add(SectionViewData(
          type: SectionViewDataType.dataHeader,
          headerIndex: _headerIndex,
          headerData: _header));

      var _itemIndex = 0;
      _buildMap.add(AlphabetModel(
          mapIndex: _listIndex,
          headerData: _header,
          headerIndex: _headerIndex));

      _listIndex++;

      var _itemList = ownWidget.onFetchListData(_header);
      for (N _item in _itemList) {
        _buildData.add(SectionViewData(
            type: SectionViewDataType.dataItem,
            headerIndex: _headerIndex,
            headerData: _header,
            itemIndex: _itemIndex,
            itemData: _item));
        _itemIndex++;
        _listIndex++;
      }

      _headerIndex++;
    }

    _listData = _buildData;
    _headerToIndexMap = _buildMap;
  }

  _stickyHeaderChanged() {
    var stickyIndex = _controller.sliverController.stickyIndex.value;

    if (stickyIndex != null) {
      var currentTopItem = _listData[stickyIndex];

      sectionViewAlphabetListKey.currentState!.topItem = currentTopItem;
      // ownWidget.onChange(stickyIndex);
    } else {
      sectionViewAlphabetListKey.currentState!.topItem = null;
    }
    // ownWidget.onChange(stickyIndex);
  }

  _fetchStickHeader() async {
    await Future.delayed(const Duration(milliseconds: 50));
    var stickyIndex = _controller.sliverController.stickyIndex.value;
    if (stickyIndex != null) {
      var currentTopItem = _listData[stickyIndex];
      sectionViewAlphabetListKey.currentState!.topItem = currentTopItem;
    } else {
      sectionViewAlphabetListKey.currentState!.topItem = null;
    }
  }

  @override
  void initState() {
    _controller.sliverController.stickyIndex.addListener(_stickyHeaderChanged);
    _buildList();
    _fetchStickHeader();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant SectionView oldWidget) {
    _buildList();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // bool _getPhysicsIsBounce() {
  //   late ScrollPhysics physics;
  //   if (ownWidget.physics != null) {
  //     physics = ownWidget.physics!;
  //   } else {
  //     var sc = ScrollConfiguration.of(context);
  //     physics = sc.getScrollPhysics(context);
  //   }
  //   return physics is BouncingScrollPhysics;
  // }

  Widget _renderList() {
    Widget result = FlutterListView(
        physics: ownWidget.physics,
        shrinkWrap: true,
        scrollBehavior: ownWidget.scrollBehavior,
        delegate: FlutterListViewDelegate(
            (BuildContext context, int index) {
              SectionViewData itemData = _listData[index];
              switch (itemData.type) {
                case SectionViewDataType.dataHeader:
                  return ownWidget.headerBuilder(
                      context, itemData.headerData, itemData.headerIndex);
                case SectionViewDataType.dataItem:
                  return ownWidget.itemBuilder(
                      context,
                      itemData.itemData,
                      itemData.itemIndex!,
                      itemData.headerData,
                      itemData.headerIndex);
              }
            },
            childCount: _listData.length,
            onItemSticky: (index) {
              if (ownWidget.enableSticky) {
                final data = _listData[index];
                if (data.type == SectionViewDataType.dataHeader) {
                  return true;
                }
              }

              return false;
            }),
        controller: _controller);

    if (ownWidget.refreshBuilder != null) {
      result = ownWidget.refreshBuilder!(result);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Stack(
      children: [
        //   SingleChildScrollView(
        //   child: Column(
        //     children: [
        //       nameText(text: "adkf"),
        //       _renderList(),
        //     ],
        //   ),
        // ),
        NotificationListener(
          child: _renderList(),
          onNotification: (val) {
            //  print(val);
            return false;
          },
        ),
        SectionViewAlphabetList<T>(
          alphabetBuilder: ownWidget.alphabetBuilder,
          headerToIndexMap: _headerToIndexMap,
          alphabetAlign: ownWidget.alphabetAlign,
          alphabetInset: ownWidget.alphabetInset,
          key: sectionViewAlphabetListKey,
          onSelect: <T>(item) {
            if (alphabetTipKey.currentState != null) {
              alphabetTipKey.currentState!.tipData = item.headerData;
            }

            _controller.sliverController.jumpToIndex(item.mapIndex);
          },
        ),

        SectionViewTip(
          tipBuilder: ownWidget.tipBuilder,
          key: alphabetTipKey,
        )
      ],
    );

    return content;
  }
}

SectionViewAlphabetBuilder<T> getDefaultAlphabetBuilder<T>(
  String Function(T data) fetchAlphabet,
) {
  return (BuildContext context, T headerData, bool isCurrent, int headerIndex) {
    if (isCurrent) {
      return SizedBox(
        width: 20,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              isWellFormedUTF16(fetchAlphabet(headerData))
                  ? fetchAlphabet(headerData)
                  : "",
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 120,
        height: 20,
        alignment: Alignment.centerRight,
        child: Text(
          isWellFormedUTF16(fetchAlphabet(headerData))
              ? fetchAlphabet(headerData)
              : "",
          style: const TextStyle(
            color: Color(0xFF767676),
          ),
        ),
      );
    }
  };
}

bool isWellFormedUTF16(String input) {
  try {
    // Attempt to decode the string as UTF-16
    input.runes.toList();
    return true; // If decoding succeeds, the string is well-formed UTF-16
  } catch (e) {
    return false; // If decoding fails, the string is not well-formed UTF-16
  }
}

TextSpan getTextSpanWithEmoji(String text) {
  // Use the characters package to handle non-BMP characters like emojis
  Iterable<int> characters = Characters(text).iterator.utf16CodeUnits;
  List<WidgetSpan> emojiSpans = characters.map((char) {
    return WidgetSpan(
      child: Text(
        char.toString(),
        style: const TextStyle(fontSize: 16), // Adjust font size as needed
      ),
    );
  }).toList();

  return TextSpan(children: emojiSpans);
}

SectionViewTipBuilder<T> getDefaultTipBuilder<T>(
    String Function(T data) fetchAlphabet) {
  return (BuildContext context, T headerData) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xCC000000)),
        width: 50,
        height: 50,
        child: Center(
          child: Text(
            fetchAlphabet(headerData),
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ));
  };
}

SectionViewHeaderBuilder<T> getDefaultHeaderBuilder<T>(
    String Function(T data) fetchAlphabet,
    {Color? bkColor,
    TextStyle? style}) {
  return (BuildContext context, T headerData, int headerIndex) {
    return Container(
      color: bkColor ?? const Color(0xFFF3F4F5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Text(
          fetchAlphabet(headerData),
          style:
              style ?? const TextStyle(fontSize: 18, color: Color(0xFF767676)),
        ),
      ),
    );
  };
}

class EmojoText extends StatelessWidget {
  String text;
  EmojoText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: _buildText(this.text),
    );
  }

  TextSpan _buildText(String text) {
    final children = <TextSpan>[];
    final runes = text.runes;

    for (int i = 0; i < runes.length; /* empty */) {
      int current = runes.elementAt(i);

      // we assume that everything that is not
      // in Extended-ASCII set is an emoji...
      final isEmoji = current > 255;
      final shouldBreak = isEmoji ? (x) => x <= 255 : (x) => x > 255;

      final chunk = <int>[];
      while (!shouldBreak(current)) {
        chunk.add(current);
        if (++i >= runes.length) break;
        current = runes.elementAt(i);
      }

      children.add(
        TextSpan(
          text: String.fromCharCodes(chunk),
          style: TextStyle(
            fontFamily: isEmoji ? 'EmojiOne' : null,
          ),
        ),
      );
    }

    return TextSpan(children: children);
  }
}
