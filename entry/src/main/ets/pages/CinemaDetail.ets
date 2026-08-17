import HttpUtil from '../../http/HttpUtil'
import { formatEndTime, formatMonthDate, formatStartTime } from '../common/DateUtil'
import { Cinema } from '../model/Cinema'
import { HttpResponseResult } from '../model/HttpResponseResult'
import { Movie } from '../model/Movie'
import { Schedule, ScheduleGroup } from '../model/Schedule'
import { UserAccount } from '../model/UserAccount'
import {MovieListScroll} from './MovieListScroll'

@Entry
@Component
struct CinemaDetail{
  @State movies: Movie[] = [];
  @State @Watch("onMovieIndexChange") currentIndex:number=0;
  @State cinema: Cinema | null = null;
  @State movie: Movie | null = null;
  @State cinemaId:number=0;
  @State movieId:number=0;
  @State selectSchedules:ScheduleGroup[]=[];
  @State schedulIndex:number=0;
  @StorageLink("userAccount")
  userAccount: UserAccount | undefined = undefined;

  aboutToAppear(): void {
    const params: ESObject = this.getUIContext().getRouter().getParams()
    this.cinemaId = params?.cinemaId ?? 0
    this.movieId = params?.movieId ?? 0
    this.selectCinemaById() // 影院获取
    this.selectMoviesByCinemaId() // 影片加载完成后会继续加载排片
  }


  async selectCinemaById(){
    const httpResponse = await HttpUtil.get<HttpResponseResult<Cinema>>
    ("/user/cinema/detail?cinemaId=" + this.cinemaId);
    if (httpResponse.code == 200) {
      this.cinema = httpResponse.data ?? null
    }
  }

  async selectMoviesByCinemaId() {
    const httpResponse = await HttpUtil.get<HttpResponseResult<Movie[]>>
    ("/user/movie/cinema?cinemaId="+this.cinemaId);
    if (httpResponse.code == 200) {
      this.movies = httpResponse.data??[]
      if (this.movieId != 0) {
        this.currentIndex = this.movies.findIndex(m => m.id == this.movieId)
      } else {
        this.currentIndex = 0
      }
      this.onMovieIndexChange()
      }
    }
  // 滑动切换影片时,同步刷新选中影片和排片信息
  async onMovieIndexChange(){
    const httpResponse = await HttpUtil.get<HttpResponseResult<Movie>>
    ("/user/movie/detail?movieId=" + this.movies[this.currentIndex].id);
    if (httpResponse.code == 200) {
      this.movie= httpResponse.data ?? null
    }
    this.selectScheduleByMovieId()
  }


  async selectScheduleByMovieId() {
    const httpResponse = await HttpUtil.get<HttpResponseResult<Schedule[]>>
    ("/user/schedule/cinema-movie?cinemaId="+this.cinemaId+"&movieId="+this.movie?.id);
    if (httpResponse.code == 200) {
      const schedules = httpResponse.data??[];
      this.selectSchedules=[]
      for(const schedule of schedules){
        const dateStr=formatMonthDate(schedule.showTime.toString())
        let flag=false
        this.selectSchedules.some(scheduleGroup=>{
          if(scheduleGroup.date== dateStr){
            scheduleGroup.schedules.push(schedule)
            flag=true
          }
        })
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
    }
  }


  build() {
    Column() {
      // 顶部影院信息区域（固定高度）
      Column() {
        // 返回按钮和影院名称
        Row() {
          SymbolGlyph($r("sys.symbol.chevron_left"))
            .fontSize(24)
            .padding({ left: 5 })
          Text(this.cinema?.cinemaName ?? '')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
          Blank()
        }
        .width("100%")
        .height(40)

        Divider().height(2)

        // 影院地址
        Text(this.cinema?.address ?? '')
          .fontSize(14)
          .padding({ top: 8, bottom: 8 })

        // 营业时间和电话
        Row() {
          Text("营业时间：" + (this.cinema?.businessHours ?? ''))
            .fontSize(14)
          Text("电话：" + (this.cinema?.phone ?? ''))
            .fontSize(14)
        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .width("100%")
        .padding({ bottom: 10 })
      }
      .width("100%")


      // 影片滚动列表（固定高度）
      MovieListScroll({
        movies: this.movies,
        currentIndex: this.currentIndex
      })
        .height(240) // 设置固定高度，或使用 .layoutWeight(0) 表示不参与分配

      // 当前选中的影片信息（固定高度）
      Column() {
        Text(this.movie?.movieName ?? '')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text((this.movie?.movieTypes?.map(t=> t.typeName).join(",") ?? '') +
          "|" + (this.movie?.duration ?? 0) + "分钟")
          .fontSize(16)
          .fontColor('#666666')
      }
      .width("100%")
      .height(60)
      .justifyContent(FlexAlign.Center)

      Divider().height(1)

      // 排片信息 Tabs（占据剩余空间）
      if (this.selectSchedules.length > 0) {
        Tabs({ barPosition: BarPosition.Start }) {
          ForEach(this.selectSchedules, (item: ScheduleGroup) => {
            TabContent() {
              // 使用 Scroll 包裹，防止内容超出
              Scroll() {
                Column({ space: 12 }) {
                  ForEach(item.schedules, (schedule: Schedule) => {
                    Row() {
                      // 时间列
                      Column() {
                        Text(formatStartTime(schedule.showTime.toString()))
                          .fontSize(20)
                          .fontWeight(FontWeight.Bolder)
                          .fontColor('#333333')
                        Text(formatEndTime(schedule.showTime.toString(), this.movie?.duration ?? 0) + "离场")
                          .fontSize(12)
                          .fontColor('#999999')
                      }
                      .alignItems(HorizontalAlign.Start)
                      .width(80)

                      // 影厅信息列
                      Column() {
                        Text(schedule.hallType)
                          .fontSize(12)
                          .fontColor('#ffba3c3c')
                          .border({ width: 1, color: '#ffba3c3c', radius: 2 })
                          .padding({ left: 4, right: 4 })
                        Text(schedule.hallName)
                          .fontSize(13)
                          .fontColor('#333333')
                          .margin({ top: 4 })
                      }
                      .alignItems(HorizontalAlign.Center)
                      .layoutWeight(1)

                      // 价格列
                      Text(schedule.price + "元起")
                        .fontSize(20)
                        .fontColor("#ff6d2f2f")
                        .fontWeight(FontWeight.Bold)
                        .width(80)

                      // 购票按钮
                      Button("购票")
                        .fontSize(14)
                        .fontColor('#FFFFFF')
                        .backgroundColor('#ff6d2f2f')
                        .borderRadius(20)
                        .width(60)
                        .height(32)
                        .onClick(() => {
                          if (this.userAccount) {
                            // 已登录：直接进选座页
                            this.getUIContext().getRouter().pushUrl({
                              url:"pages/SelectSeatPage",
                              params:{
                                scheduleId:schedule.id
                              }
                            })
                          } else {
                            // 未登录：先跳登录页，登录成功后返回本页再点购票
                            this.getUIContext().getRouter().pushUrl({
                              url:"pages/loginPage"
                            })
                          }
                        })
                    }
                    .justifyContent(FlexAlign.SpaceBetween)
                    .width("100%")
                    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                    .backgroundColor('#FFFFFF')
                    .borderRadius(8)
                  })
                }
                .width("100%")
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              }
              .width("100%")
              .height("100%")
              .align(Alignment.TopStart)
              .scrollBar(BarState.Off)
            }
            .tabBar(item.date)
            .width("100%")
            .height("100%")
          })
        }
        .barMode(BarMode.Scrollable)
        .width("100%")
        .layoutWeight(1) // 占据剩余空间
        .backgroundColor('#F8F8F8')
      } else {
        // 没有排片时显示占位
        Column() {
          Text('暂无排片信息')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width("100%")
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F8F8F8')
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor('#FFFFFF')
  }
}