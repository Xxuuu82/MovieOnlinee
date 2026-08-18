import { text } from '@kit.ArkGraphics2D'
import httpUtil from '../http/HttpUtil';
import { Movie } from '../model/Movie';
import { MovieType } from '../model/MovieType';
import { HttpResponseResult } from '../model/HttpResponseResult';

@Component
export struct CategoryComp{
  @State movieTypes:MovieType[]=[];
  @State movies:Movie[]=[];
  @State currentIndex:number=0;
  aboutToAppear(): void {
    this.movieTypes.push({id:0,typeName:"精选"})
    this.getMovieTypes();
    this.getMoviesByType(0);

  }
  async getMovieTypes(){
    // HttpUtil → httpUtil
    const httpResponse = await httpUtil.get<HttpResponseResult<MovieType[]>>("/user/movie/typeOptions");
    if(httpResponse.code==200 && httpResponse.data){
      this.movieTypes.push(...httpResponse.data);
      //this.movieTypes = this.movieTypes.concat(httpResponse.data);
    }
  }

  async getMoviesByType(typeId:number){
    // HttpUtil → httpUtil
    const httpResponse = await httpUtil.get<HttpResponseResult<Movie[]>>
    ("/user/movie/list?typeId="+typeId);
    if(httpResponse.code==200){
      this.movies = httpResponse.data ?? [];
    }
  }


  build() {
    Row(){
      Column({space:20}) {
        Text("")
          .margin({top:30})
        ForEach(this.movieTypes, (item:MovieType) => {
          Text(item.typeName)
            .fontColor(this.currentIndex==item.id? "#ff1f60a0" : "#ff090808")
            .onClick(()=>{
              this.currentIndex=item.id;
              this.getMoviesByType(item.id)

            })
        })
      }.width("20%")
      .height("100%")
      .backgroundColor("#FFE2DFDF")
      Column(){
          Text("影片库").fontSize(32).alignSelf(ItemAlign.Start)
        Row(){
          Text("探索")
          Text(this.movies.length+"")
          Text("部电影")
        }
        Scroll(){
          GridRow({
            columns: {
              xs: 2, // 窗口宽度落入xs断点上，栅格容器分为2列。
              sm: 4, // 窗口宽度落入sm断点上，栅格容器分为4列。
              md: 8, // 窗口宽度落入md断点上，栅格容器分为8列。
              lg: 12, // 窗口宽度落入lg断点上，栅格容器分为12列。
              //xl: 12, // 窗口宽度落入xl断点上，栅格容器分为12列。

            },
            breakpoints: {
              value: ['600vp', '840vp', '1440vp'], // 表示在保留默认断点['320vp', '600vp', '840vp']的同时自定义增加'1440vp', '1600vp'的断点，实际开发中需要根据实际使用场景，合理设置断点值实现一次开发多端适配。
              reference: BreakpointsReference.WindowSize
            }
          }){
            ForEach(this.movies,(item:Movie)=>{
              GridCol({span:1}){
                Column({space:5}){
                  Image(httpUtil.BASE_URL+item.posterUrl)
                    .width(125)
                    .height(180)
                    .borderRadius(10)
                  Text(item.movieName).width(120)
                    .textOverflow({overflow:TextOverflow.Ellipsis})
                    .maxLines(1)
                    .textAlign(TextAlign.Center)
                  Row(){
                    Rating({rating:1})
                      .stars(1)
                    Text(item.movieRating+"")
                      .fontColor("#ffeca008")
                  }

                }
                .alignItems(HorizontalAlign.Center)

              }
            })

          }
        }


      }.width("80%")
      .margin({bottom:65})
    }.width("100%")
  }
}