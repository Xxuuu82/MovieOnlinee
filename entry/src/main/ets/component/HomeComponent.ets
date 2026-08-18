import { router } from '@kit.ArkUI';
import HttpUtil from '../http/HttpUtil';
import { HttpResponseResult } from '../model/HttpResponseResult';
import { Movie } from '../model/Movie';

@Entry
@Component
export struct HomeComponent {
  // ===== 状态变量 =====
  @State hotMovies: Movie[] = [];
  @State upcomingMovies: Movie[] = [];
  @State isLoading: boolean = true;
  private mainScroller: Scroller = new Scroller();  // 外层滚动控制器

  // ===== 页面加载时自动执行 =====
  aboutToAppear(): void {
    this.loadAllData();
  }

  /**
   * 加载所有数据
   */
  async loadAllData() {
    this.isLoading = true;
    try {
      await Promise.all([
        this.getHotMovies(),
        this.getUpcomingMovies()
      ]);
    } catch (error) {
      console.error('加载数据失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 获取正在热映电影
   */
  async getHotMovies() {
    try {
      const response = await HttpUtil.get<HttpResponseResult<Movie[]>>(
        '/user/movie/getHotMovies'
      );

      if (response.code === 200 && response.data) {
        this.hotMovies = response.data;
        console.info('热映电影数量:', this.hotMovies.length);
      } else {
        console.error('获取热映电影失败:', response.message);
      }
    } catch (error) {
      console.error('请求热映电影异常:', error);
    }
  }

  /**
   * 获取即将上映电影
   */
  async getUpcomingMovies() {
    try {
      const response = await HttpUtil.get<HttpResponseResult<Movie[]>>(
        '/user/movie/getUpcomingMovies'
      );

      if (response.code === 200 && response.data) {
        this.upcomingMovies = response.data;
        console.info('即将上映电影数量:', this.upcomingMovies.length);
      } else {
        console.error('获取即将上映电影失败:', response.message);
      }
    } catch (error) {
      console.error('请求即将上映电影异常:', error);
    }
  }

  /**
   * 跳转到电影详情页
   */
  goToMovieDetail(movieId: number) {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/MovieDetailPage',
      params: { movieId: movieId }
    });
  }

  /**
   * 跳转到影片对应影院列表
   */
  goToMovieCinemaList(movieId: number, movieName: string, posterUrl: string) {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/MovieCinemaListPage',
      params: {
        movieId: movieId,
        movieName: movieName,
        posterUrl: posterUrl
      }
    });
  }

  /**
   * 获取完整的图片URL
   */
  getFullImageUrl(path: string): string {
    if (!path) return '';
    // HttpUtil.BASE_URL 已包含 http://10.98.174.215:8081/movieplatform
    return HttpUtil.BASE_URL + path;
  }

  build() {
    Scroll(this.mainScroller) {
      Column() {
        // ===== 1. 搜索框 =====
        Search({ placeholder: "What do you want ?" })
          .width("95%")
          .margin({ bottom: 16 })

        // ===== 2. 轮播图 =====
        if (this.hotMovies.length > 0) {
          Swiper() {
            ForEach(this.hotMovies.slice(0, 3), (movie: Movie) => {
              Stack() {
                // 图片
                Image(this.getFullImageUrl(movie.posterUrl))
                  .width("100%")
                  .height("100%")
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .backgroundColor('#E0E0E0')

                // 底部文字遮罩
                Column() {
                  Text(movie.movieName)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                  Text(`评分: ${movie.movieRating}`)
                    .fontSize(14)
                    .fontColor('#FFD700')
                }
                .width("100%")
                .height(50)
                .padding({ left: 16 })
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Start)
                .backgroundColor('rgba(0,0,0,0.5)')
                .borderRadius({ bottomLeft: 8, bottomRight: 8 })
              }
              .width('100%')
              .height('100%')
              .alignContent(Alignment.Bottom)
            }, (movie: Movie) => movie.id.toString())
          }
          .width("95%")
          .height(180)
          .borderRadius(10)
          .loop(true)
          .autoPlay(true)
          .interval(5000)
          .margin({ bottom: 20 })
        }

        // ===== 3. 正在热映 =====
        Column({ space: 10 }) {
          Text("正在热映")
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 10  })

          Scroll() {
            Row({ space: 10 }) {
              ForEach(this.hotMovies, (movie: Movie) => {
                // 每个电影卡片：海报 + 电影名 + 评分 + 购票按钮
                Column({ space: 4 }) {
                  // ===== Stack：海报 + 底部悬浮评分 =====
                  Stack() {
                    // 海报底层
                    Image(this.getFullImageUrl(movie.posterUrl))
                      .width(110)
                      .height(150)
                      .objectFit(ImageFit.Cover)
                      .borderRadius(8)
                      .backgroundColor('#E0E0E0')

                    // 悬浮在海报底部居中：⭐ + 分数
                    Row() {
                      Text('★')
                        .fontSize(14)
                        .fontColor('#FF9800')
                      Text(`${movie.movieRating}分`)
                        .fontSize(12)
                        .fontColor('#FF9800')
                        .margin({ left: 3 })

                    }
                    .width('100%')
                    .padding({ bottom: 6 })
                    .justifyContent(FlexAlign.Center)
                    .offset({x:-25,y:65})
                  }
                  .width(110)
                  .height(150)
                  .borderRadius(8)
                  .clip(true)

                  // 电影名称
                  Text(movie.movieName)
                    .fontSize(13)
                    .width(110)
                    .textAlign(TextAlign.Center)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  // 购票按钮
                  Button("购票")
                    .width(60)
                    .height(30)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .backgroundColor('#ff5db1cf')
                    .fontColor('#FFFFFF')
                    .borderRadius(18)
                    .border({ width: 0 })
                    .stateStyles({
                      pressed: { backgroundColor: '#ff0f6b91' }
                    })
                    .onClick(() => {
                      this.goToMovieCinemaList(movie.id, movie.movieName,movie.posterUrl);
                    })
                }
                .width(110)
                .alignItems(HorizontalAlign.Center)
                .onClick(() => {
                  this.goToMovieDetail(movie.id);
                })
              }, (movie: Movie) => movie.id.toString())
            }
            .padding({ left: 10, right: 10 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .width('100%')
          .height(250)
          .nestedScroll({
            scrollForward: NestedScrollMode.PARENT_FIRST,
            scrollBackward: NestedScrollMode.PARENT_FIRST
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .margin({ bottom: 20 })

        // ===== 4. 即将上映 =====
        Column({ space: 10 }) {
          Text("即将上映")
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 10 })

          Scroll() {
            Row({ space: 10 }) {
              ForEach(this.upcomingMovies, (movie: Movie) => {
                Column() {
                  Image(this.getFullImageUrl(movie.posterUrl))
                    .width(110)
                    .height(150)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)
                    .backgroundColor('#E0E0E0')

                  Text(movie.movieName)
                    .fontSize(13)
                    .width(110)
                    .textAlign(TextAlign.Center)
                    .margin({ top: 4 , bottom: 8})
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(`📅 ${movie.releaseDate.split('T')[0]}`)
                    .fontSize(12)
                    .fontColor('#999999')
                    .width(110)
                    .textAlign(TextAlign.Center)
                    .margin({ bottom: 10})
                }
                .onClick(() => {
                  this.goToMovieDetail(movie.id);
                })
              }, (movie: Movie) => movie.id.toString())
            }
            .padding({ left: 10, right: 10 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .width('100%')
          .height(200)
          .nestedScroll({
            scrollForward: NestedScrollMode.PARENT_FIRST,
            scrollBackward: NestedScrollMode.PARENT_FIRST
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .width("100%")
      .backgroundColor('#F5F5F5')
      .padding({ top: 16 })
    }
    // 外层Scroll属性配置
    .width("100%")
    .height("100%")
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .enableScrollInteraction(true)
  }
}