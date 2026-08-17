import HttpUtil from "../../http/HttpUtil";
import { Cinema } from "../model/Cinema";
import { HttpResponseResult } from "../model/HttpResponseResult";

@Component

export struct CinemaComp{
  @State city:string=""
  @State searchText:string=""
  @State cinemas:Cinema[]=[]
  aboutToAppear(): void {
    this.getCinemasByCondition()
  }
  async getCinemasByCondition() {
      const httpRespone = await HttpUtil.get<HttpResponseResult<Cinema[]>>(
        "/user/cinema/list?city="+encodeURIComponent(this.city)+"&searchText="+encodeURIComponent(this.searchText));
      this.cinemas = httpRespone.data ?? [];
    }

  // 读取首页「购票」时记录的影片ID，读取后清空，避免影响后续正常进入
  getPendingMovieId(): number {
    const movieId = AppStorage.get<number>("pendingMovieId") ?? 0
    AppStorage.setOrCreate("pendingMovieId", 0)
    return movieId
  }

  build() {
    //最上面图片
    Column({space:10}){
      Swiper(){
        ForEach(this.cinemas,(cinema:Cinema)=>{
          Image(HttpUtil.BASE_URL+cinema.imageUrl)
            .width("100%")
            .height(180)
            .onClick(()=>{
              this.getUIContext().getRouter().pushUrl({
                url:"pages/CinemaDetail",
                params:{cinemaId:cinema.id,movieId:this.getPendingMovieId()}
              })
          })
        })
      }.loop(true)
      .autoPlay(true)
      .indicator(false)
      //搜索框
      Row(){
        Text("全国")
        SymbolGlyph($r("sys.symbol.map"))
          .fontSize(18)
        Search({value:this.searchText})
          .width("85%")
          .backgroundColor("#FFFFFF")
          .onChange((value)=>{
            this.searchText=value
            this.getCinemasByCondition()
          })
      }.width("95%")
      .justifyContent(FlexAlign.SpaceBetween)
      //下面小框
      List({space:10}){
        ForEach(this.cinemas,(cinema:Cinema)=>{
          ListItem(){
            Column({space:8}){
              Row(){
                Text(cinema.cinemaName)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                Text("39.9起")
                  .fontColor("#ffcf3535")
                  .fontWeight(FontWeight.Bold)
              }.justifyContent(FlexAlign.SpaceBetween)
              .width("100%")
              Text(cinema.address)
                .width("100%")
              Flex({direction:FlexDirection.Row,wrap:FlexWrap.Wrap}){
                ForEach(cinema.facilities.split(","),(item:string)=>{
                  Text(item)
                    .borderWidth(2)
                    .borderColor("#ffbae5c0")
                    .borderRadius(5)
                    .padding(3)//定义前后左右
                    .margin({right:5})
                })
              }.width("100%")
              Text("营业时间:"+cinema.businessHours)
                .width("100%")
            }.width("100%")
            .backgroundColor("#ffffff")
            .borderRadius(10)
            .padding(10)
            .onClick(()=>{
              this.getUIContext().getRouter().pushUrl({
                url:"pages/CinemaDetail",
                params:{cinemaId:cinema.id,movieId:this.getPendingMovieId()}
              })
            })
          }
        })
      }.scrollBar(BarState.Off)
      .width("100%")
      .margin({bottom:85})
      .padding({ left: 12, right: 12 })
    }.backgroundColor("#ffd9d4d4")
    .width("100%")
    .height("100%")

  }
 }

