import { CategoryComponent } from '../component/CategoryComponent';
import { CinemaComponent } from '../component/CinemaComponent';
import { HomeComponent } from '../component/HomeComponent';
import { MyComponent } from '../component/MyComponent';
import { url } from '@kit.ArkTS';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;

  // 用来通知“我的”页面重新获取余额
  @State balanceRefreshKey: number = 0;

  @Builder
  tabBuilder(title: string, targetIndex: number, icon: Resource) {
    Column() {
      SymbolGlyph(icon)
        .fontSize(32)
        .fontColor([
          this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B'
        ])

      Text(title)
        .fontSize(16)
        .fontColor(
          this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B'
        )
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .borderWidth({ top: 1 })
    .borderColor("#ffb0acac")
    .padding({ top: 10 })
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {

      // 首页
      TabContent() {
        HomeComponent()
      }
      .tabBar(
        this.tabBuilder(
          "首页",
          0,
          $r("sys.symbol.house")
        )
      )

      // 分类
      TabContent() {
        CategoryComponent()
      }
      .tabBar(
        this.tabBuilder(
          "分类",
          1,
          $r("sys.symbol.grid")
        )
      )

      // 影院
      TabContent() {
        CinemaComponent()
      }
      .tabBar(
        this.tabBuilder(
          "影院",
          2,
          $r("sys.symbol.local")
        )
      )

      // 我的
      TabContent() {
        MyComponent({
          refreshKey: this.balanceRefreshKey
        })
      }
      .tabBar(
        this.tabBuilder(
          "我的",
          3,
          $r("sys.symbol.person")
        )
      )

    }
    .onChange((index: number) => {
      this.currentIndex = index;

      // 每次切换到“我的”页面，都通知 MyComponent 刷新余额
      if (index === 3) {
        this.balanceRefreshKey++;

        console.info(
          '切换到“我的”页面，余额刷新次数:',
          this.balanceRefreshKey
        );
      }
    })
    .width("100%")
    .height("100%")
    .barHeight(60)
  }
}