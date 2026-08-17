import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Movie } from '../model/Movie';
import { HttpResponseResult } from '../model/HttpResponseResult';
import httpUtil from '../http/HttpUtil';

@Component

export struct HomeComp{

  @State movies:Movie[]=[]
  @State comingMovies:Movie[]=[]

  aboutToAppear(): void {
    //正在热映电影数据
    this.getHotMovies()
    //即将上映电影
    this.getcomingUpMovies()
  }

  async getHotMovies() {
    // 使用实例 httpUtil.get()
    const httpResponse: HttpResponseResult<Movie[]> = await httpUtil.get<HttpResponseResult<Movie[]>>("/user/movie/getHotMovies");
    if (httpResponse.code == 200) {
      this.movies = httpResponse.data;
    }
  }

  async getcomingUpMovies() {
    const httpResponse1: HttpResponseResult<Movie[]> = await httpUtil.get<HttpResponseResult<Movie[]>>("/user/movie/getUpcomingMovies");
    this.comingMovies = httpResponse1.data;
  }


  build() {
    Scroll() {  // 外层包裹 Scroll
      Column({ space: 15 }) {
        Search({ placeholder: "请问你想看什么？" })
          .width("90%")

        Swiper() {
          ForEach(this.movies, (item: Movie) => {
            Image(httpUtil.BASE_URL + item.posterUrl)
              .width("100%")
              .height(120)
          })
        }
        .width("95%")
        .height(120)
        .borderRadius(10)
        .loop(true)
        .autoPlay(true)
        .interval(3000)

        Column({ space: 10 }) {
          Text("正在热映")
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
          Scroll() {
            Row({ space: 8 }) {
              ForEach(this.movies, (movie: Movie) => {
                Column({ space: 6 }) {
                  Stack({alignContent:Alignment.BottomStart}){
                    Image(httpUtil.BASE_URL + movie.posterUrl)
                      .width(100)
                      .height(142)
                      .borderRadius(8)
                      //.zIndex(2)
                    Text(movie.movieRating+"分")
                      .font({size:18,weight:FontWeight.Bold })
                      .fontColor(Color.Red)
                      .offset({x:15,y:-15})

                  }


                  Text(movie.movieName)
                    .fontSize(12)
                    .width(100)
                    .textAlign(TextAlign.Center)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                  Button("购票")
                    .fontSize(12)
                    .height(28)
                    .width(60)
                }
              })
            }
          }
          .width("95%")
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }

        Column({ space: 15 }) {
          Text("即将上映")
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
          List({ space: 8 }) {
            ForEach(this.comingMovies, (item: Movie) => {
              ListItem() {
                Column({ space: 6 }) {
                  Image(httpUtil.BASE_URL + item.posterUrl)
                    .width(100)
                    .height(142)
                    .borderRadius(8)
                  Text(item.movieName)
                    .fontSize(12)
                    .width(100)
                    .textAlign(TextAlign.Center)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .maxLines(1)
                }
                .alignItems(HorizontalAlign.Center)
              }
            })
          }
          .width("95%")
          .listDirection(Axis.Horizontal)
        }
      }
      .width("100%")
      .padding({ bottom: 65 })  // 添加底部内边距，避免被底部导航栏遮挡
    }
    .width("100%")
    .height("100%")
  }
}

