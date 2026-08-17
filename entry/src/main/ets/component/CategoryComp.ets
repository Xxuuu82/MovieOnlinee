import HttpUtil from "../../http/HttpUtil";
import { HttpResponseResult } from "../model/HttpResponseResult";
import { Movie } from "../model/Movie";
import { MovieType } from "../model/MovieTypes";

@Component
@Entry
export struct CategoryComp{
  @State movieTypes:MovieType[] = [];
  @State movies:Movie[] = [];
  @State currentIndex:number = 0;
  aboutToAppear(): void {
    this.movieTypes.push({id:0,typeName:"精选"})
    this.getMovieTypes();
    this.getMoviesByType(0);

  }
  async getMovieTypes(){
    const httpResponse = await HttpUtil.get<HttpResponseResult<MovieType[]>>
    ("/user/movie/typeOptions");
    if(httpResponse.code==200 && httpResponse.data){
      this.movieTypes = this.movieTypes.concat(httpResponse.data);
    }
  }
  async getMoviesByType(typeId:number){
    const httpResponse = await HttpUtil.get<HttpResponseResult<Movie[]>>
    ("/user/movie/list?typeId="+typeId);
    if(httpResponse.code==200){
      this.movies = httpResponse.data ?? [];
    }
  }


  build() {
    Row(){
      //左边竖着
      Column({space:20}){
        Text("")
          .margin({top:30})
        ForEach(this.movieTypes,(item:MovieType)=>{
          Text(item.typeName)
            .fontSize(18)
            .fontColor(this.currentIndex == item.id? "#ff1581ee" : "#ff151414")
            .onClick(()=>{
              this.currentIndex = item.id;
              this.getMoviesByType(item.id)
            })
        })
      }.width("20%")
      .height("100%")
      .backgroundColor("#DDDDDD")

      Column({space:10}){
        Text("影片库")
          .fontSize(32)
          .alignSelf(ItemAlign.Start)
          .fontWeight(FontWeight.Bold)
        Row(){
          Text("探索")
          Text(this.movies.length+"")
            .fontColor("#ffde260e")
          Text("部影片")
        }.alignSelf(ItemAlign.Start)
        Scroll(){
          GridRow({
            columns: {
              xs: 2, // 窗口宽度落入xs断点上，栅格容器分为2列。
              sm: 4, // 窗口宽度落入sm断点上，栅格容器分为4列。
              md: 8, // 窗口宽度落入md断点上，栅格容器分为8列。
              lg: 12, // 窗口宽度落入lg断点上，栅格容器分为12列。
            },
            breakpoints: {
              value: ['600vp', '840vp', '1440vp'],
              reference: BreakpointsReference.WindowSize
            }
          }){
            ForEach(this.movies,(item:Movie)=>{
              GridCol({span:1}){
                Column(){
                  Image(HttpUtil.BASE_URL+item.posterUrl)
                    .width(125)
                    .height(180)
                    .borderRadius(10)
                  Text(item.movieName).width(120)
                    .textOverflow({overflow: TextOverflow.Ellipsis})
                    .maxLines(1)
                    .fontWeight(FontWeight.Bold)
                    .textAlign(TextAlign.Center)
                    .margin({ top: 8 })
                  Row(){
                    Rating({rating:1})
                      .stars(1)
                    Text(item.movieRating+"")
                      .fontColor("#ffeca008")
                  }

                }

              }
            })

          }
        }

      }.width("80%")
      .margin({bottom:80})

    }.width("100%")
  }
}