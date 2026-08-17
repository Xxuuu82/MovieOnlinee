import { CategoryComponent } from '../component/CategoryComponent';
import { CinemaComponent } from '../component/CinemaComponent';
import { HomeComponent } from '../component/HomeComponent';
import { MyComponent } from '../component/MyComponent';
import { url } from '@kit.ArkTS';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;
  @Builder
  tabBuilder(title: string, targetIndex: number, icon: Resource) {
    Column() {
      SymbolGlyph(icon).fontSize(32)
        .fontColor([this.currentIndex === targetIndex?'#1698CE' :'#6B6B6B'])
      Text(title).fontSize(16)
        .fontColor(this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .borderWidth({top:1})
    .borderColor("#ffb0acac")
    .padding({top:10})
  }

  build() {
    Tabs({barPosition:BarPosition.End}){
      TabContent(){
        HomeComponent()
      }
      .tabBar(this.tabBuilder("首页",0,$r("sys.symbol.house")))


      TabContent(){
        CategoryComponent()
      }.tabBar(this.tabBuilder("分类",1,$r("sys.symbol.grid")))

      TabContent(){
        CinemaComponent()
      }.tabBar(this.tabBuilder("影院",2,$r("sys.symbol.local")))

      TabContent(){
        MyComponent()
      }.tabBar(this.tabBuilder("我的",3,$r("sys.symbol.person")))

    }.onChange((index:number)=>{
      this.currentIndex=index
    })
    .width("100%")
    .height("100%")
    .barHeight(60)
  }
}
