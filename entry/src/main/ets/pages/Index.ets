import { CategoryComp } from '../component/CategoryComp';
import { CinemaComp } from '../component/CinemaComp';
import { HomeComp } from '../component/HomeComponent';
import { MyComp } from '../component/MyComp';

@Entry
@Component
struct Index {
  @State currentIndex:number=0;
  @Builder
  tabBuilder(index:number,title:string,icon:Resource){
    Column({space:5}){
      SymbolGlyph(icon)
        .fontSize(30)
        .fontColor(this.currentIndex==index?["#ff70b7f1"]:["#ff797700"])
      Text(title)
        .fontSize(18)
        .fontColor(this.currentIndex==index?"#ff70b7f1":"#ff797700")
    }
  }



  build() {
    Tabs() {
      TabContent() {
        HomeComp()
      }.tabBar(this.tabBuilder(0, "首页", $r("sys.symbol.house")))

      TabContent() {
        CategoryComp()
      }.tabBar(this.tabBuilder(1, "分类", $r("sys.symbol.list_bullet")))

      TabContent() {
        CinemaComp()
      }.tabBar(this.tabBuilder(2, "影院", $r("sys.symbol.media_center")))

      TabContent() {
        MyComp()
      }.tabBar(this.tabBuilder(3, "我的", $r("sys.symbol.person")))

    }.vertical(false)
    .barPosition(BarPosition.End)
    .barHeight(80)
    .onChange((index)=>{
      this.currentIndex=index
    })




    .height('100%')
    .width('100%')
  }
}


