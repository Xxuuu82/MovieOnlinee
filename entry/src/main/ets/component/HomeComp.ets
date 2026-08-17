import { http } from "@kit.NetworkKit";
import HttpUtil from "../../http/HttpUtil";
import { HttpResponseResult } from "../model/HttpResponseResult";
import { Movie } from "../model/Movie";
@Entry
@Component
export struct HomeComp{

  @State movies:Movie[]=[]
  @State comingMovie:Movie[]=[]

  aboutToAppear(): void {
    this.getHotMovies();
    this.getcomingUpMovies();
  }
  async getHotMovies(){
    const httpRespone = await HttpUtil.get<HttpResponseResult<Movie[]>>(
      "/user/movie/getHotMovies");
    if(httpRespone.code==200){
      this.movies = httpRespone.data ?? [];
    }
  }

  async getcomingUpMovies(){
    const httpRespone1 = await HttpUtil.get<HttpResponseResult<Movie[]>>(
      "/user/movie/getUpcomingMovies");
    this.comingMovie = httpRespone1.data ?? [];
  }



  build(){
    Column(){
      Search({placeholder:"猜你想看"})
        .width("90%")

      Swiper(){
       ForEach(this.movies,(item:Movie)=>{
         Image("http://10.98.15.30:8081/movieplatform"+item.posterUrl)

           .width("100%")
           .height(120)
       })
      }.width("95%")
      .height(120)
      .borderRadius(10)
      .loop(true)
      .autoPlay(true)
      .interval(1000)
      .indicator(false)

      Column({space:10}) {
        Text("正在热映")
          .alignSelf(ItemAlign.Start)
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
        Scroll() {
          Row({ space: 10 }) {
            ForEach(this.movies, (movie: Movie) => {
              Column({space:5}) {

                Stack({alignContent: Alignment.BottomStart}){
                  Image("http://10.98.15.30:8081/movieplatform"+movie.posterUrl)
                    .width(120)
                    .height(160)
                  Text(movie.movieRating+"分")
                    .fontWeight(FontWeight.Bold)
                    .fontColor("#ffe7c61f")
                }

                Text(movie.movieName)
                  .fontWeight(FontWeight.Bold)
                  .width(120)
                  .textOverflow({overflow:TextOverflow.Ellipsis})
                  .maxLines(1)
                  .textAlign(TextAlign.Center)
                Button("购票")
                  .fontSize(15)
                  .height(30)
                  .onClick(() => {
                    // 记录想买的影片，切到影院Tab让用户先选影院
                    AppStorage.setOrCreate("pendingMovieId", movie.id)
                    AppStorage.setOrCreate("currentTabIndex", 2)
                  })
              }
            })
          }
        }.width("95%")
        .scrollable(ScrollDirection.Horizontal)
      }
      .margin({ top: 20 })

      Column({space:10}){
        Text("即将上映")
          .alignSelf(ItemAlign.Start)
          .fontWeight(FontWeight.Bold)
          .fontSize(25)
        List({space:10}){
          ForEach(this.comingMovie,(item:Movie)=>{
            ListItem(){
              Column({space:5}){
                Image("http://10.98.15.30:8081/movieplatform"+item.posterUrl)
                  .width(120)
                  .height(160)
                  .backgroundColor("#DDDDDD")
                Text(item.movieName)
                  .fontWeight(FontWeight.Bold)
                  .width(120)
                  .textOverflow({overflow:TextOverflow.Ellipsis})
                  .maxLines(1)
                  .textAlign(TextAlign.Center)
              }
            }
          })
        }.width("95%")
        .listDirection(Axis.Horizontal)

      }
      .margin({ top: 20 })
      .margin({bottom:60})
    }.width("100%")
    .height("100%")

  }
}