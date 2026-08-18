import { Cinema } from '../model/Cinema';
import { Movie } from '../model/Movie';
import { Schedule, ScheduleGroup } from '../model/Schedule';
import { MovieListScroll } from './MovieListScroll';
import HttpUtil from '../http/HttpUtil';
import { HttpResponseResult } from '../model/HttpResponseResult';

interface MovieTypeOption {
  id: number;
  typeName: string;
  description: string;
  sortOrder: number;
  status: number;
}

@Entry
@Component
struct CinemaDetail {
  @State movies: Movie[] = [];
  @State @Watch('onCurrentIndexChange') currentIndex: number = 0; // 切换电影显示相应的排片
  @State cinema: Cinema | null = null;
  @State cinemaId: number = 0;
  @State movieId: number = 0;
  @State posterUrl:string = '';
  @State schedules: Schedule[] = [];  // 当前电影的所有排片
  @State scheduleGroups: ScheduleGroup[] = [];  // 按日期分组后的排片
  @State selectedDate: string = '';// 当前选择的日期
  @State movieTypeOptions: MovieTypeOption[] = [];  // 电影类型列表
  @State isLoading: boolean = true;  // 页面整体加载
  @State isScheduleLoading: boolean = false;  // 排片加载
  private scheduleRequestId: number = 0;

  // 生命周期
  aboutToAppear(): void {
    const params: Record<string, Object> = this.getUIContext().getRouter().getParams() as Record<string, Object>;
    this.cinemaId = (params?.cinemaId as number) ?? 0;
    this.movieId = (params?.movieId as number) ?? 0;
    this.posterUrl = params.posterUrl as string;
    this.loadAllData();
  }

  // 加载页面全部数据
  async loadAllData() {
    this.isLoading = true;
    try {
      await Promise.all([
        this.selectCinemaById(),
        this.selectMoviesByCinema(),
        this.loadMovieTypeOptions()
      ]);
      let targetIndex: number = 0;
      if (this.movieId > 0 && this.movies.length > 0) {
        const index: number = this.movies.findIndex((movie: Movie) => movie.id === this.movieId);
        if (index >= 0) {
          targetIndex = index;
        }
      }
      // 设置当前电影
      if (targetIndex !== 0) {
        this.currentIndex = targetIndex;
      } else {
        if (this.movies.length > 0) {
          const firstMovie: Movie = this.movies[0];
          if (firstMovie) {
            await this.selectScheduleByMovieId(firstMovie.id);
          }
        }
      }
    } catch (error) {
      console.error('加载影院详情失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  // 获取影院信息
  async selectCinemaById() {
    if (this.cinemaId === 0) {
      return; }
    try {
      const response: HttpResponseResult<Cinema> = await HttpUtil.get<HttpResponseResult<Cinema>>(
          `/user/cinema/detail?cinemaId=${this.cinemaId}`
        );
      if (response.code === 200 && response.data) {
        this.cinema = response.data;
        console.info('影院信息获取成功:', this.cinema.cinemaName);
      } else {
        console.error('获取影院信息失败:', response.message);
      }
    } catch (error) {
      console.error('请求影院信息异常:', error);
    }
  }

  // 获取影院正在上映电影
  async selectMoviesByCinema() {
    if (this.cinemaId === 0) {
      return;
    }
    try {
      const response: HttpResponseResult<Movie[]> = await HttpUtil.get<HttpResponseResult<Movie[]>>(
          `/user/movie/cinema?cinemaId=${this.cinemaId}`
        );
      if (response.code === 200 && response.data) {
        this.movies = response.data;
        // 找到用户点击购买的电影在影院电影列表中的位置
        const index = this.movies.findIndex(
          (movie: Movie) => movie.id === this.movieId
        );
        if (index >= 0) {
          this.currentIndex = index;
        }
        console.info('影院影片数量:', this.movies.length);
        console.info('当前电影索引:', this.currentIndex);
      } else {
        console.error('获取影院影片失败:', response.message);
        this.movies = [];
      }
    } catch (error) {
      console.error('请求影院影片异常:', error);
      this.movies = [];
    }
  }

  // 获取电影类型
  async loadMovieTypeOptions() {
    try {
      const response:
        HttpResponseResult<MovieTypeOption[]> = await HttpUtil.get<HttpResponseResult<MovieTypeOption[]>>(
          '/user/movie/typeOptions'
        );

      if (response.code === 200 && response.data) {
        this.movieTypeOptions = response.data;
        console.info('电影类型数量:', this.movieTypeOptions.length);
      } else {
        console.error('获取电影类型失败:', response.message);
        this.movieTypeOptions = [];
      }
    } catch (error) {
      console.error('请求电影类型异常:', error);
      this.movieTypeOptions = [];
    }
  }

  // 根据类型ID获取类型名称
  getTypeNameById(typeId: number): string {
    for (let i = 0; i < this.movieTypeOptions.length; i++) {
      const option: MovieTypeOption = this.movieTypeOptions[i];
      if (option && option.id === typeId) {
        return option.typeName;
      }
    }
    return '';
  }

  // 格式化电影类型
  formatMovieType(typeValue: string): string {
    if (!typeValue) {return '未知类型';}
    const parts: string[] = typeValue.split(',');
    const names: string[] = [];
    parts.forEach((part: string) => {
      const value: string = part.trim();
      if (!value) {return;}
      const id: number = Number(value);
      // 如果是数字ID
      if (!isNaN(id)) {
        const typeName: string = this.getTypeNameById(id);
        if (typeName) {
          names.push(typeName);
        } else {
          names.push(value);
          }
        } else {
          names.push(value);
        }
      }
    );
    if (names.length === 0) {return '未知类型';}
    return names.join(' / ');
  }

  // currentIndex发生变化
  onCurrentIndexChange(): void {
    if (this.currentIndex < 0 || this.currentIndex >= this.movies.length) {
      return;
    }
    const movie: Movie = this.movies[this.currentIndex];
    if (!movie) {
      return;}
    console.info('当前电影切换:', movie.movieName, 'movieId:', movie.id);
    // 重新请求当前电影排片
    this.selectScheduleByMovieId(movie.id);
  }

  // 获取指定电影排片
  async selectScheduleByMovieId(movieId: number) {
    if (this.cinemaId === 0 || movieId === 0) {
      return;
    }
    // 每发起一次请求，序号+1
    this.scheduleRequestId++;
    const currentRequestId: number = this.scheduleRequestId;
    this.isScheduleLoading = true;
    // 切换电影后先清空旧排片
    this.schedules = [];
    this.scheduleGroups = [];
    this.selectedDate = '';
    try {
      console.info('开始请求排片:', 'cinemaId =', this.cinemaId, 'movieId =', movieId);
      const response: HttpResponseResult<Schedule[]> = await HttpUtil.get<HttpResponseResult<Schedule[]>>(
          `/user/schedule/cinema-movie?cinemaId=${this.cinemaId}&movieId=${movieId}`
        );

      // 如果这不是最新的一次请求，直接丢弃结果
      if (currentRequestId !== this.scheduleRequestId) {
        console.info('忽略过期排片请求:', movieId);
        return;
      }
      if (response.code === 200 && response.data) {
        this.schedules = response.data;
        console.info('当前电影排片数量:', this.schedules.length);
        // 按日期分组
        this.groupSchedulesByDate();
      } else {
        console.error('获取排片失败:', response.message);
        this.schedules = [];
        this.scheduleGroups = [];
        this.selectedDate = '';
      }
    } catch (error) {
      if (currentRequestId !== this.scheduleRequestId) {
        return;
      }
      console.error('请求排片异常:', error);
      this.schedules = [];
      this.scheduleGroups = [];
      this.selectedDate = '';
    } finally {
      if (currentRequestId === this.scheduleRequestId) {
        this.isScheduleLoading = false;
      }
    }
  }

  // 按日期分组
  groupSchedulesByDate() {
    const groupMap: Map<string, Schedule[]> = new Map();
    this.schedules.forEach((schedule: Schedule) => {
      const showTime: string = schedule.showTime;
      if (!showTime) {return;}
      const timeParts: string[] = showTime.split('T');
      if (timeParts.length === 0) {return;}
      const date: string = timeParts[0];
      if (!groupMap.has(date)) {
        groupMap.set(date, []);
      }
      const group: Schedule[] | undefined = groupMap.get(date);
      if (group) {
          group.push(schedule);
        }
      }
    );
    this.scheduleGroups = [];
    groupMap.forEach((schedules: Schedule[], date: string) => {
      schedules.sort((a: Schedule, b: Schedule) => {
        return a.showTime.localeCompare(b.showTime);
      });
      this.scheduleGroups.push({ date: date, schedules: schedules });
    });

    // 日期升序
    this.scheduleGroups.sort((a: ScheduleGroup, b: ScheduleGroup) => {
      return a.date.localeCompare(b.date)
      ;}
    );

    // 默认选择第一个有排片的日期
    if (this.scheduleGroups.length > 0) {
      this.selectedDate = this.scheduleGroups[0].date;
    }
    console.info('排片日期数量:', this.scheduleGroups.length);
    console.info('默认选择日期:', this.selectedDate);
  }

  // 选择日期
  selectDate(date: string) {
    this.selectedDate = date;
    console.info('切换排片日期:', date);
  }

  // 获取完整图片URL
  getFullImageUrl(path: string): string {
    if (!path) {return '';}
    return HttpUtil.BASE_URL + path;
  }

  // 返回上一页
  goBack() {
    this.getUIContext().getRouter().back();
  }

  // 跳转购票
  goToTicket(scheduleId: number) {
    this.getUIContext()
      .getRouter()
      .pushUrl({ url: 'pages/SelectSeatPage', params: { scheduleId: scheduleId } });
  }

  // 格式化日期
  formatDate(dateStr: string): string {
    if (!dateStr) {
      return '';
    }
    const parts: string[] = dateStr.split('-');
    if (parts.length === 3) {
      const month: number = Number(parts[1]);
      const day: number = Number(parts[2]);
      return `${month}月${day}日`;
    }
    return dateStr;
  }

  // 格式化时间
  formatTime(showTime: string): string {
    if (!showTime) {
      return '--:--';
    }
    const parts: string[] = showTime.split('T');
    if (parts.length !== 2) {
      return '--:--';
    }
    const timeParts: string[] = parts[1].split(':');
    if (timeParts.length < 2) {
      return '--:--';
    }
    return `${timeParts[0]}:${timeParts[1]}`;
  }

  // 计算结束时间
  calculateEndTime(
    startTime: string,
    duration: number
  ): string {
    if (!startTime || duration <= 0) {return '';}
    const parts: string[] = startTime.split('T');
    if (parts.length !== 2) {return '';}
    const timeParts: string[] = parts[1].split(':');
    if (timeParts.length < 2) {return '';}
    let hours: number = Number(timeParts[0]);
    let minutes: number = Number(timeParts[1]);
    if (isNaN(hours) || isNaN(minutes)) {return '';}
    minutes += duration;
    hours += Math.floor(minutes / 60);
    minutes = minutes % 60;
    hours = hours % 24;
    const hourText: string = String(hours).padStart(2, '0');
    const minuteText: string = String(minutes).padStart(2, '0');
    return `${hourText}:${minuteText}离场`;
  }

  build() {

      Column() {
        // 1. 顶部导航栏
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(26)
            .onClick(() => {
              this.goBack();
            })
          Text(this.cinema?.cinemaName || '影院详情')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 12 })
            .layoutWeight(1)
        }
        .width('100%')
        .height(44)
        .padding({ left: 12, right: 16 })
        .backgroundColor('#FFFFFF')

        // 2. 影院信息
        if (this.cinema) {
          Column() {
            // 地址
            Row() {
              SymbolGlyph($r('sys.symbol.map'))
                .fontSize(16)
                .fontColor(['#ffdd7733'])
              Text(this.cinema.address || '地址待更新')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ left: 4 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .margin({ bottom: 4 })
            // 营业时间
            Row() {
              SymbolGlyph($r('sys.symbol.clock'))
                .fontSize(16)
                .fontColor(['#ffdd7733'])
              Text(`营业时间：${this.cinema.businessHours || '待更新'}`)
                .fontSize(14)
                .fontColor('#666666')
                .margin({ left: 4 })
            }
            .width('100%')
            .margin({ bottom: 4 })
            // 联系电话
            Row() {
              SymbolGlyph($r('sys.symbol.phone'))
                .fontSize(16)
                .fontColor(['#ffdd7733'])
              Text(`联系电话：${this.cinema.phone || '待更新'}`)
                .fontSize(14)
                .fontColor('#666666')
                .margin({ left: 4 })
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor('#FFFFFF')
        }

        Divider()
          .height(1)
          .color('#FFFFFF')

        // 3. 电影海报滑动区域
        if (this.movies.length > 0) {
          MovieListScroll({
            movies: this.movies,
            currentIndex: this.currentIndex
          })
            .width('100%')
            .height(240)
        }

        // 4. 当前电影名称 + 类型 + 时长
        if (this.movies.length > 0 && this.currentIndex >= 0 && this.currentIndex < this.movies.length) {
          Column() {
            // 电影名称
            Text(this.movies[this.currentIndex].movieName)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .width('100%')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            // 类型 + 时长
            Row() {
              Text(this.formatMovieType(String(this.movies[this.currentIndex].type)))
                .fontSize(14)
                .fontColor('#888888')

              Text(' · ')
                .fontSize(14)
                .fontColor('#AAAAAA')

              Text(`${this.movies[this.currentIndex].duration || 0}分钟`)
                .fontSize(14)
                .fontColor('#888888')
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .margin({ top: 5 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .backgroundColor('#FFFFFF')
        }

        // 5. 排片日期
        if (this.scheduleGroups.length > 0) {
          Scroll() {
            Row({ space: 10 }) {
              ForEach(this.scheduleGroups, (group: ScheduleGroup) => {
                  Column() {
                    Text(this.formatDate(group.date))
                      .fontSize(15)
                      .fontWeight(this.selectedDate === group.date ? FontWeight.Bold : FontWeight.Medium)
                      .fontColor(this.selectedDate === group.date ? '#FFFFFF' : '#333333')
                  }
                  .width(76)
                  .height(48)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  .backgroundColor(this.selectedDate === group.date ? '#1698CE' : '#F5F5F5')
                  .borderRadius(8)
                  .onClick(() => {
                    this.selectDate(group.date);
                  });
                }, (group: ScheduleGroup) => group.date)
            }
            .padding({ left: 16, right: 16 })
          }
          .width('100%')
          .height(54)
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .backgroundColor('#FFFFFF')}

        // 6. 排片区域
        Scroll() {
          Column() {
            // 排片加载中
            if (this.isScheduleLoading) {
              Column() {
                LoadingProgress()
                  .width(30)
                  .height(30)
                  .color('#1698CE')
                Text('正在加载排片...')
                  .fontSize(13)
                  .fontColor('#999999')
                  .margin({ top: 8 })
              }
              .width('100%')
              .padding({ top: 30, bottom: 30 })
              .justifyContent(FlexAlign.Center)
            }
            // 没有排片
            else if (this.scheduleGroups.length === 0) {
              Column() {
                Text('暂无排片信息')
                  .fontSize(14)
                  .fontColor('#999999')
                Text('当前电影暂未安排场次')
                  .fontSize(12)
                  .fontColor('#CCCCCC')
                  .margin({ top: 6 })
              }
              .width('100%')
              .padding({ top: 30, bottom: 30 })
              .justifyContent(FlexAlign.Center)
            }
            // 有排片
            else {
              ForEach(this.scheduleGroups, (group: ScheduleGroup) => {
                  if (group.date === this.selectedDate) {
                      // 当天所有场次
                      Column({ space: 8 }) {
                        ForEach(group.schedules, (schedule: Schedule) => {
                          Row() {
                              // 时间
                              Column() {
                                Text(this.formatTime(schedule.showTime))
                                  .fontSize(18)
                                  .fontWeight(FontWeight.Bold)
                                  .fontColor('#1698CE')
                                Text(this.calculateEndTime(schedule.showTime, schedule.movieDuration))
                                  .fontSize(11)
                                  .fontColor('#999999')
                                  .margin({ top: 2 })
                              }
                              .width(78)
                              .alignItems(HorizontalAlign.Center)
                              // 分割线
                              Divider()
                                .height(38)
                                .width(1)
                                .color('#E5E5E5')
                                .margin({ left: 4, right: 10 })
                              // 影厅
                              Column() {
                                Text(schedule.hallName || '未知影厅')
                                  .fontSize(15)
                                  .fontWeight(FontWeight.Medium)
                                  .maxLines(1)
                                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                                Text(schedule.hallType || '普通厅')
                                  .fontSize(12)
                                  .fontColor('#999999')
                                  .margin({ top: 3 })
                              }
                              .layoutWeight(1)
                              .alignItems(HorizontalAlign.Start)
                              // 价格
                              Row() {
                                Text(`¥${schedule.price || 0}`)
                                  .fontSize(17)
                                  .fontWeight(FontWeight.Bold)
                                  .fontColor('#FF6B35')
                                Text('起')
                                  .fontSize(11)
                                  .fontColor('#FF6B35')
                              }
                              .margin({ right: 8 })
                              // 购票按钮
                              Button('购票')
                                .width(58)
                                .height(32)
                                .fontSize(13)
                                .backgroundColor('#1698CE')
                                .fontColor('#FFFFFF')
                                .borderRadius(7)
                                .onClick(() => {
                                  this.goToTicket(schedule.id);
                                })
                            }
                            .width('100%')
                            .padding({ left: 10, right: 10, top: 9, bottom: 9 })
                            .backgroundColor('#FFFFFF')
                            .borderRadius(9);
                          },
                          (schedule: Schedule) => schedule.id.toString())
                      }
                      .width('100%')
                      .padding({ left: 10, right: 10, bottom: 14 })
                  }
                },
                (group: ScheduleGroup) => group.date)
            }
          }
          .width('100%')
          .backgroundColor('#F5F5F5')
          .padding({ top: 10, bottom: 20 })
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
  }
}