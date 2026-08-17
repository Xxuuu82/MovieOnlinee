import { Cinema } from '../model/Cinema';
import { HttpResponseResult } from '../model/HttpResponseResult';
import { Movie } from '../model/Movie'
import { Schedule, ScheduleGroup } from '../model/Schedule';
import httpUtil from '../http/HttpUtil';
import { MovieListScroll } from './MovieListScroll'
import { formatEndTime, formatMonthDate, formatStartTime } from '../common/DateUtil';

@Entry
@Component
struct CinemaDetail{
  @State movies:Movie[]=[];
  @State @Watch("changeMovies") currentIndex:number =0;
  @State cinema:Cinema=null!
  @State movie:Movie=null!
  @State cinemaId:number=0
  @State movieId:number=0
  @State selectSchedules:ScheduleGroup[]=[]
  @State scheduleIndex:number=0

  async aboutToAppear(): Promise<void> {
    const params:ESObject=this.getUIContext().getRouter().getParams()
    this.cinemaId = params?.cinemaId as number ?? 0;
    this.movieId = params?.movieId as number ?? 0;
    await this.selectCinemaById()
    await this.selectMoviesByCinemaId()
    //this.selectScheduleByMovieId()


  }



  async  selectCinemaById(){
    const httpResponse = await httpUtil.get<HttpResponseResult<Cinema>>
    ("/user/cinema/detail?cinemaId="+this.cinemaId);
    if(httpResponse.code==200 ){
      this.cinema=httpResponse.data

    }
  }

  async  selectMoviesByCinemaId(){
    const httpResponse = await httpUtil.get<HttpResponseResult<Movie[]>>
    ("/user/movie/cinema?cinemaId="+this.cinemaId);
    if(httpResponse.code==200 ){
      this.movies=httpResponse.data
      if(this.movieId!=0){
        this.currentIndex=this.movies.findIndex(m=>m.id==this.movieId)
      }else {
        this.currentIndex=0
      }
      await this.changeMovies()
    }
  }
  async changeMovies(){
    const httpResponse = await httpUtil.get<HttpResponseResult<Movie>>
    ("/user/movie/detail?movieId="+this.movies[this.currentIndex].id);
    if(httpResponse.code==200 ){
      this.movie=httpResponse.data
    }
    await this.selectScheduleByMovieId()
  }

  async  selectScheduleByMovieId(){
    console.log('===== 获取排片 =====')
    console.log('cinemaId:', this.cinemaId)
    console.log('movieId:', this.movie?.id)
    const httpResponse = await httpUtil.get<HttpResponseResult<Schedule[]>>
    ("/user/schedule/cinema-movie?cinemaId="+this.cinemaId+"&movieId="+this.movie?.id);
    console.log('排片接口返回:', JSON.stringify(httpResponse))
    if(httpResponse.code==200 ){
      const schedules=httpResponse.data;
      console.log('排片数据条数:', schedules.length)
      this.selectSchedules=[]
      for(const schedule of schedules){
        console.log('处理排期:', schedule)
        const dateStr=formatMonthDate(schedule.showTime.toString())
        let flag = false;
        this.selectSchedules.some(scheduleGroup=>{
          if(scheduleGroup.date==dateStr){
            scheduleGroup.schedules.push(schedule)
            flag=true;
          }
        })
        console.log(flag+"")
        if(!flag){
          let ss:Schedule[]=[]
          ss.push(schedule)
          this.selectSchedules.push({
            date:dateStr,
            schedules:ss
          })
        }
      }
      this.selectSchedules.sort((a,b)=> a.date.localeCompare(b.date))
      console.log('分组后的排片:', JSON.stringify(this.selectSchedules))
    }
  }

  build() {

    Column(){
      Row(){
        SymbolGlyph($r("sys.symbol.chevron_left"))
          .fontSize(24)
          .padding({left:5})
        Text(this.cinema?.cinemaName)
        Blank()
      }.justifyContent(FlexAlign.SpaceBetween)
      Divider().borderWidth(1)
      Text(this.cinema?.address)
      Row(){
        Text("营业时间"+this.cinema?.businessHours)
        Text("电话"+this.cinema?.phone)
      }.justifyContent(FlexAlign.SpaceEvenly)

      MovieListScroll({
        movies:this.movies,
        currentIndex:this.currentIndex

      }).width("100%")
        .height(240)

      Column(){
        Text(this.movie?.movieName)
        Text(`${(this.movie?.movieTypes?.map(t => t.typeName) ?? []).join(",")}|${this.movie?.duration ?? ""}分钟`)

      }

      Tabs({barPosition:BarPosition.Start}){
        ForEach(this.selectSchedules,(item:ScheduleGroup)=>{
          TabContent(){
            Scroll(){
              Column({space:10}){
                ForEach(item.schedules,(schedule:Schedule)=>{

                  Row(){
                    Column({space:10}){
                      Text(formatStartTime(schedule?.showTime?.toString())).fontSize(20)
                        .fontWeight(FontWeight.Bold)
                      Text(formatEndTime(schedule?.showTime?.toString(),this.movie.duration)+"离场")
                    }
                    Column({space:10}){
                      Text(schedule?.hallType)
                        .borderWidth(1)
                        .borderColor("#ff95ebf3")
                      Text(schedule?.hallName)
                    }
                    Text(schedule?.price+"元起")
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.Red)
                    Button("购票")
                      .onClick((event:ClickEvent)=>{
                        this.getUIContext().getRouter().pushUrl({
                          url:"pages/SelectSeatPage",
                          params:{
                            scheduleId:schedule.id
                          }
                        })

                      })
                  }.justifyContent(FlexAlign.SpaceBetween)
                  .width("100%")

                })

              }.width("100%")
              .justifyContent(FlexAlign.Start)
              //.alignSelf(ItemAlign.Start)
              //.backgroundColor("#FFFFFF")

            }.width("100%")
            .height("100%")
            .align(Alignment.Top)

          }.tabBar(item.date)
          .width("100%")
        })
      }.barMode(BarMode.Scrollable)
      .layoutWeight(1)
    }
    .height("100%")
    .width("100%")
  }
}