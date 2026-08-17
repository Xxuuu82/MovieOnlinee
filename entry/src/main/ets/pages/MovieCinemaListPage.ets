import { Cinema } from '../model/Cinema';
import { Movie } from '../model/Movie';
import { Schedule } from '../model/Schedule';
import HttpUtil from '../http/HttpUtil';
import { HttpResponseResult } from '../model/HttpResponseResult';

interface MovieTypeOption {
  id: number;
  typeName: string;
  description: string;
  sortOrder: number;
  status: number;
}

interface CinemaPrice {
  cinemaId: number;
  price: number;
}

@Entry
@Component
export struct MovieCinemaListPage {
  @State movie: Movie | null = null;
  @State cinemas: Cinema[] = [];
  @State movieTypeOptions: MovieTypeOption[] = [];
  @State cinemaPrices: CinemaPrice[] = [];

  @State isMovieLoading: boolean = true;
  @State isCinemaLoading: boolean = true;

  private movieId: number = 0;

  // ==================== 生命周期 ====================

  aboutToAppear(): void {
    const params: Record<string, Object> =
      this.getUIContext().getRouter().getParams() as Record<string, Object>;

    this.movieId = (params?.movieId as number) ?? 0;

    if (this.movieId > 0) {
      this.loadData();
    } else {
      this.isMovieLoading = false;
      this.isCinemaLoading = false;
    }
  }

  async loadData(): Promise<void> {
    await Promise.all([
      this.loadMovieDetail(),
      this.loadMovieTypeOptions(),
      this.loadCinemas()
    ]);
  }

  // ==================== 电影 ====================

  async loadMovieDetail(): Promise<void> {
    try {
      const response: HttpResponseResult<Movie> =
        await HttpUtil.get<HttpResponseResult<Movie>>(
          `/user/movie/detail?movieId=${this.movieId}`
        );

      if (response.code === 200 && response.data) {
        this.movie = response.data;
      }
    } catch (error) {
      console.error('获取电影详情异常:', error);
    } finally {
      this.isMovieLoading = false;
    }
  }

  async loadMovieTypeOptions(): Promise<void> {
    try {
      const response: HttpResponseResult<MovieTypeOption[]> =
        await HttpUtil.get<HttpResponseResult<MovieTypeOption[]>>(
          '/user/movie/typeOptions'
        );

      if (response.code === 200 && response.data) {
        this.movieTypeOptions = response.data;
      }
    } catch (error) {
      console.error('获取电影类型异常:', error);
    }
  }

  getTypeNameById(id: number): string {
    const option: MovieTypeOption | undefined =
      this.movieTypeOptions.find(
        (item: MovieTypeOption) => item.id === id
      );

    return option ? option.typeName : '';
  }

  formatMovieType(type: string): string {
    if (!type) {
      return '未知类型';
    }

    const names: string[] = [];

    type.split(',').forEach((item: string) => {
      const value: string = item.trim();

      if (!value) {
        return;
      }

      const id: number = Number(value);

      if (!isNaN(id)) {
        const name: string = this.getTypeNameById(id);

        if (name) {
          names.push(name);
        }
      } else {
        names.push(value);
      }
    });

    return names.length > 0 ? names.join(' / ') : '未知类型';
  }

  // ==================== 影院 ====================

  async loadCinemas(): Promise<void> {
    try {
      const response: HttpResponseResult<Cinema[]> =
        await HttpUtil.get<HttpResponseResult<Cinema[]>>(
          `/user/movie/cinemas?movieId=${this.movieId}`
        );

      if (response.code === 200 && response.data) {
        this.cinemas = response.data;
        await this.loadCinemaPrices();
      } else {
        this.cinemas = [];
      }
    } catch (error) {
      console.error('获取影院列表异常:', error);
      this.cinemas = [];
    } finally {
      this.isCinemaLoading = false;
    }
  }

  // 获取所有影院的最低票价
  async loadCinemaPrices(): Promise<void> {
    const prices: CinemaPrice[] = [];

    for (const cinema of this.cinemas) {
      const price: number = await this.getCinemaMinPrice(cinema.id);

      prices.push({
        cinemaId: cinema.id,
        price: price
      });
    }

    this.cinemaPrices = prices;
  }

  // 查询某影院该电影的所有排片，并取最低价格
  async getCinemaMinPrice(cinemaId: number): Promise<number> {
    try {
      const response: HttpResponseResult<Schedule[]> =
        await HttpUtil.get<HttpResponseResult<Schedule[]>>(
          `/user/schedule/cinema-movie?cinemaId=${cinemaId}&movieId=${this.movieId}`
        );

      if (
        response.code !== 200 ||
          !response.data ||
          response.data.length === 0
      ) {
        return -1;
      }

      let minPrice: number = Number.MAX_VALUE;

      response.data.forEach((schedule: Schedule) => {
        const price: number = Number(schedule.price);

        if (!isNaN(price) && price < minPrice) {
          minPrice = price;
        }
      });

      return minPrice === Number.MAX_VALUE ? -1 : minPrice;
    } catch (error) {
      console.error(
        `获取影院 ${cinemaId} 票价异常:`,
        error
      );

      return -1;
    }
  }

  getCinemaPrice(cinemaId: number): number {
    const item: CinemaPrice | undefined =
      this.cinemaPrices.find(
        (price: CinemaPrice) => price.cinemaId === cinemaId
      );

    return item ? item.price : -1;
  }

  formatPrice(cinemaId: number): string {
    const price: number = this.getCinemaPrice(cinemaId);

    if (price < 0) {
      return '暂无场次';
    }

    return price % 1 === 0
      ? `¥${price.toFixed(0)}起`
      : `¥${price.toFixed(1)}起`;
  }

  getFacilityTags(facilities: string): string[] {
    if (!facilities) {
      return [];
    }

    return facilities
      .split(',')
      .map((item: string) => item.trim())
      .filter((item: string) => item.length > 0);
  }

  // ==================== 页面跳转 ====================

  goBack(): void {
    this.getUIContext().getRouter().back();
  }

  goToCinemaDetail(cinemaId: number): void {
    this.getUIContext()
      .getRouter()
      .pushUrl({
        url: 'pages/CinemaDetail',
        params: {
          cinemaId: cinemaId,
          movieId: this.movieId
        }
      });
  }

  getFullImageUrl(path: string): string {
    if (!path) {
      return '';
    }

    if (
      path.startsWith('http://') ||
        path.startsWith('https://')
    ) {
      return path;
    }

    return HttpUtil.BASE_URL + path;
  }

  // ==================== 页面 ====================

  build() {
    Column() {

      // 顶部
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#333333'])
          .onClick(() => {
            this.goBack();
          })

        Text('影院选择')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 10 })
      }
      .width('100%')
      .height(44)
      .padding({ left: 12, right: 16 })
      .backgroundColor('#FFFFFF')


      // ==================== 电影信息 ====================

      if (this.isMovieLoading) {

        Column() {
          LoadingProgress()
            .width(30)
            .height(30)
            .color('#1698CE')

          Text('正在加载电影信息...')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .height(190)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')

      } else if (this.movie) {

        Row() {

          Image(
            this.getFullImageUrl(
              this.movie.posterUrl
            )
          )
            .width(125)
            .height(170)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .backgroundColor('#EEEEEE')

          Column() {

            Text(this.movie.movieName || '未知电影')
              .fontSize(21)
              .fontWeight(FontWeight.Bold)
              .fontColor('#222222')
              .maxLines(1)
              .textOverflow({
                overflow: TextOverflow.Ellipsis
              })

            Row() {
              Text('类型')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')

              Text(
                this.formatMovieType(
                  String(this.movie.type || '')
                )
              )
                .fontSize(15)
                .fontColor('#555555')
                .margin({ left: 8 })
                .maxLines(2)
                .textOverflow({
                  overflow: TextOverflow.Ellipsis
                })
            }
            .width('100%')
            .margin({ top: 12 })

            Row() {
              Text('时长')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')

              Text(`${this.movie.duration || 0}分钟`)
                .fontSize(15)
                .fontColor('#555555')
                .margin({ left: 8 })
            }
            .width('100%')
            .margin({ top: 8 })

          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })

        }
        .width('100%')
        .height(190)
        .padding({
          left: 20,
          right: 20,
          top: 10,
          bottom: 10
        })
        .backgroundColor('#FFFFFF')
      }


      // ==================== 在售影院 ====================

      Text('在售影院')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 8, bottom: 12 })
        .backgroundColor('#FFFFFF')


      // ==================== 影院列表 ====================

      if (this.isCinemaLoading) {

        Column() {
          LoadingProgress()
            .width(30)
            .height(30)
            .color('#1698CE')

          Text('正在加载影院...')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .padding({ top: 30 })
        .backgroundColor('#F5F5F5')

      } else if (this.cinemas.length === 0) {

        Column() {
          SymbolGlyph($r('sys.symbol.map'))
            .fontSize(40)
            .fontColor(['#CCCCCC'])

          Text('暂无在售影院')
            .fontSize(15)
            .fontColor('#999999')
            .margin({ top: 12 })

          Text('当前电影暂未安排影院场次')
            .fontSize(12)
            .fontColor('#CCCCCC')
            .margin({ top: 6 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .padding({ top: 40 })
        .backgroundColor('#F5F5F5')

      } else {

        Scroll() {

          Column() {

            ForEach(
              this.cinemas,
              (cinema: Cinema) => {

                Column() {

                  // 影院名称 + 最低价格
                  Row() {

                    Text(
                      cinema.cinemaName || '未知影院'
                    )
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#222222')
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({
                        overflow: TextOverflow.Ellipsis
                      })

                    Text(
                      this.formatPrice(cinema.id)
                    )
                      .fontSize(17)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FF6B35')

                  }
                  .width('100%')


                  // 地址
                  Row() {

                    SymbolGlyph($r('sys.symbol.map'))
                      .fontSize(14)
                      .fontColor(['#999999'])

                    Text(
                      cinema.address || '地址待更新'
                    )
                      .fontSize(14)
                      .fontColor('#666666')
                      .margin({ left: 4 })
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({
                        overflow: TextOverflow.Ellipsis
                      })

                  }
                  .width('100%')
                  .margin({ top: 5 })


                  // 影院设施
                  Flex({
                    wrap: FlexWrap.Wrap
                  }) {

                    ForEach(
                      this.getFacilityTags(
                        cinema.facilities
                      ),
                      (tag: string) => {

                        Text(tag)
                          .fontSize(11)
                          .fontColor('#156B91')
                          .padding({
                            left: 8,
                            right: 8,
                            top: 2,
                            bottom: 2
                          })
                          .backgroundColor('#99C4E5')
                          .borderRadius(4)
                          .margin({
                            right: 6,
                            bottom: 6
                          })
                      },
                      (tag: string) => tag
                    )
                  }
                  .width('100%')
                  .margin({ top: 7 })


                  // 营业时间
                  Row() {

                    SymbolGlyph($r('sys.symbol.clock'))
                      .fontSize(14)
                      .fontColor(['#999999'])

                    Text(
                      `营业时间：${cinema.businessHours || '待更新'}`
                    )
                      .fontSize(13)
                      .fontColor('#999999')
                      .margin({ left: 4 })

                  }
                  .width('100%')
                  .margin({ top: 2 })

                }
                .width('100%')
                .padding({
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: 14
                })
                .backgroundColor('#FFFFFF')
                .onClick(() => {
                  this.goToCinemaDetail(cinema.id);
                })


                Divider()
                  .height(1)
                  .color('#E5E5E5')

              },
              (cinema: Cinema) => cinema.id.toString()
            )

          }
          .width('100%')
          .justifyContent(FlexAlign.Start)

        }
        .width('100%')
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .backgroundColor('#F5F5F5')
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}