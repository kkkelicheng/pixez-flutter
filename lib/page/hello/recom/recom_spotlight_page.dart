/*
 * Copyright (C) 2020. by perol_notsf, All rights reserved
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pixez/component/illust_card.dart';
import 'package:pixez/component/spotlight_card.dart';
import 'package:pixez/generated/l10n.dart';
import 'package:pixez/lighting/lighting_store.dart';
import 'package:pixez/main.dart';
import 'package:pixez/models/illust.dart';
import 'package:pixez/network/api_client.dart';
import 'package:pixez/page/hello/ranking/rank_page.dart';
import 'package:pixez/page/hello/recom/spotlight_store.dart';
import 'package:pixez/page/spotlight/spotlight_page.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class RecomSpolightPage extends StatefulWidget {
  @override
  _RecomSpolightPageState createState() => _RecomSpolightPageState();
}

class _RecomSpolightPageState extends State<RecomSpolightPage>
    with AutomaticKeepAliveClientMixin {
  SpotlightStore spotlightStore;
  LightingStore _lightingStore;

  @override
  void initState() {
    _easyRefreshController = RefreshController(initialRefresh: true);
    spotlightStore = SpotlightStore();
    _lightingStore =
        LightingStore(() => apiClient.getRecommend(), _easyRefreshController);

    super.initState();
  }

  RefreshController _easyRefreshController;

  Future<void> fetchT() async {
    await spotlightStore.fetch();
    await _lightingStore.fetch();
  }

  @override
  void dispose() {
    _easyRefreshController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Observer(builder: (_) {
      return buildEasyRefresh(context);
    });
  }

  bool needToBan(Illusts illust) {
    for (var i in muteStore.banillusts) {
      if (i.illustId == illust.id.toString()) return true;
    }
    for (var j in muteStore.banUserIds) {
      if (j.userId == illust.user.id.toString()) return true;
    }
    for (var t in muteStore.banTags) {
      for (var f in illust.tags) {
        if (f.name == t.name) return true;
      }
    }
    return false;
  }

  Widget buildEasyRefresh(BuildContext context) {
    return SmartRefresher(
      controller: _easyRefreshController,
      enablePullDown: true,
      enablePullUp: true,
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = Text(I18n.of(context).Pull_Up_To_Load_More);
          } else if (mode == LoadStatus.loading) {
            body = CircularProgressIndicator();
          } else if (mode == LoadStatus.failed) {
            body = Text(I18n.of(context).Loading_Failed_Retry_Message);
          } else if (mode == LoadStatus.canLoading) {
            body = Text(I18n.of(context).Let_Go_And_Load_More);
          } else {
            body = Text(I18n.of(context).No_More_Data);
          }
          return Container(
            height: 55.0,
            child: Center(child: body),
          );
        },
      ),
      onRefresh: () {
        return fetchT();
      },
      onLoading: () {
        return _lightingStore.fetchNext();
      },
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return StaggeredGridView.countBuilder(
      crossAxisCount: userSetting.crossCount,
      staggeredTileBuilder: (int index) {
        if (index < 3) return StaggeredTile.fit(userSetting.crossCount);
        var illust = _lightingStore.iStores[index - 3].illusts;
        if (needToBan(illust)) return StaggeredTile.extent(1, 0.0);
        double screanWidth = MediaQuery.of(context).size.width;
        double itemWidth = (screanWidth /userSetting.crossCount.toDouble()) - 32.0;
        double radio =
            _lightingStore.iStores[index - 3].illusts.height.toDouble() /
                _lightingStore.iStores[index - 3].illusts.width.toDouble();
        double mainAxisExtent;
        if (radio > 2)
          mainAxisExtent = itemWidth;
        else
          mainAxisExtent = itemWidth * radio;
        return StaggeredTile.extent(1, mainAxisExtent + 80.0);
      },
      itemCount: _lightingStore.iStores.length + 3,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0)
          return AppBar(
            elevation: 0.0,
            titleSpacing: 0.0,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            title: _buildFirstRow(context),
          );
        if (index == 1) return _buildSpotlightContainer();
        if (index == 2) return _buildSecondRow(context);
        if (_lightingStore.iStores.isNotEmpty)
          return IllustCard(
            store: _lightingStore.iStores[index - 3],
            iStores: _lightingStore.iStores,
          );
        return Container();
      },
    );
  }

  Widget _buildSpotlightContainer() {
    return Container(
      height: 230.0,
      child: spotlightStore.articles.isNotEmpty
          ? ListView.builder(
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final spotlight = spotlightStore.articles[index];
                return SpotlightCard(
                  spotlight: spotlight,
                );
              },
              itemCount: spotlightStore.articles.length,
              scrollDirection: Axis.horizontal,
            )
          : Container(),
    );
  }

  Widget _buildFirstRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            child: Padding(
              child: Text(
                I18n.of(context).Spotlight,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30.0,
                    color: Theme.of(context).textTheme.headline6.color),
              ),
              padding: EdgeInsets.only(left: 20.0, bottom: 10.0),
            ),
          ),
          Padding(
            child: FlatButton(
              child: Text(I18n.of(context).More),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (BuildContext context) {
                  return SpotLightPage();
                }));
              },
            ),
            padding: EdgeInsets.all(8.0),
          )
        ],
      ),
    );
  }

  Widget _buildSecondRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Container(
          child: Padding(
            child: Container(
              child: Text(
                I18n.of(context).Recommend_for_you,
                overflow: TextOverflow.clip,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30.0),
              ),
            ),
            padding: EdgeInsets.only(left: 20.0, bottom: 10.0),
          ),
        ),
        Padding(
          child: FlatButton(
            child: Text(I18n.of(context).More),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return Scaffold(
                  body: RankPage(),
                );
              }));
            },
          ),
          padding: EdgeInsets.all(8.0),
        )
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
