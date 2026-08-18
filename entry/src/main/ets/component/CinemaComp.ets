import { Cinema } from '../model/Cinema'
import { HttpResponseResult } from '../model/HttpResponseResult';
import httpUtil from '../http/HttpUtil';
@Component
export struct CinemaComp{


  @State city:string=""
  @State searchText:string=""
  @State cinemas:Cinema[]=[]
aboutToAppear(): void {
this.getCinemaByCondition()
}
async getCinemaByCondition(){

    const httpResponse: HttpResponseResult<Cinema[]> = await httpUtil.get<HttpResponseResult<Cinema[]>>
    ("/user/cinema/list?city="+encodeURIComponent(this.city)+"&searchText="+encodeURIComponent(this.searchText));
    if (httpResponse.code == 200) {
      this.cinemas = httpResponse.data;
    }

}


  build(){
    Column({space:10}){
      Swiper(){
        ForEach(this.cinemas,(cinema:Cinema)=>{
          Image(httpUtil.BASE_URL+cinema.imageUrl)
            .width("100%")
            .height(150)
            .onClick(()=>{
              this.getUIContext().getRouter().pushUrl({
                url:"pages/CinemaDetail",
                params:{
                  cinemaId:cinema.id
                }
              })

            })
        })
      }.loop(true)
      .autoPlay(true)
      .indicator(false)

      Row(){
        Text("全国")
        SymbolGlyph($r("sys.symbol.map"))
          .fontSize(18)
        Search()
          .width("85%")
          .backgroundColor("#FFFFFF")
          .onChange((value)=>{
            this.searchText=value
            this.getCinemaByCondition();
          })
      }.width("95%")
      .justifyContent(FlexAlign.SpaceBetween)

      List({space:10}){
        ForEach(this.cinemas,(cinema:Cinema)=>{
          ListItem(){
            Column({space:8}){
              Row(){
                Text(cinema.cinemaName)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                Text("39.9起")
                  .fontColor("#FF0000")
              }.justifyContent(FlexAlign.SpaceBetween)
              .width("100%")
              Text(cinema.address)
                .width("100%")
                .fontSize(14)
              Flex({direction:FlexDirection.Row,wrap:FlexWrap.Wrap}){
                ForEach(cinema.facilities.split(","),(item:string)=>{
                  Text(item)
                    .borderWidth(2).borderColor("#ffb9f0f6")
                    .borderRadius(3)
                    .padding(2).margin({right:5})
                    .fontSize(12)
                })
              }.width("100%")
              Text("营业时间："+cinema.businessHours)
                .width("100%")
                .fontSize(12)
            }.width("100%")
            .backgroundColor("#FFFFFF")
            .borderRadius(10)
            .padding(10)
            .onClick(()=>{
              this.getUIContext().getRouter().pushUrl({
                url:"pages/CinemaDetail",
                params:{
                  cinemaId:cinema.id
                }
              })
            })
          }
        })
      }.width("90%")
      .scrollBar(BarState.Off)
      .margin({bottom:230})
    }.backgroundColor("#ffe9e6e6")
    .width("100%")
    .height("100%")

  }
}