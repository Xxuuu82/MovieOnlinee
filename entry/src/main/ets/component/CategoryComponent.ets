import { router } from '@kit.ArkUI';
import HttpUtil from '../http/HttpUtil';
import { HttpResponseResult } from '../model/HttpResponseResult';
import { MovieType } from '../model/MovieType';
import { Movie } from '../model/Movie';

@Entry
@Component
export struct CategoryComponent {
  // ===== 状态变量 =====
  @State movieTypes: MovieType[] = [];
  @State selectedTypeId: number = -1; // 默认 -1 代表全部影片
  @State moviesByType: Movie[] = [];
  @State isLoading: boolean = true;

  // ===== 断点：用于 GridRow 自适应 =====
  private breakpoints: BreakPoints = {
    value: ['600vp', '840vp', '1440vp']
  };

  // ===== 生命周期 =====
  aboutToAppear(): void {
    this.loadAllData();
  }

  /**
   * 加载所有数据
   */
  async loadAllData() {
    this.isLoading = true;
    try {
      await this.getMovieTypes();
      await this.getMoviesByType(-1);      // 默认加载全部影片
    } catch (error) {
      console.error('加载数据失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 获取所有电影类型
   */
  async getMovieTypes() {
    try {
      const response = await HttpUtil.get<HttpResponseResult<MovieType[]>>(
        '/user/movie/typeOptions'
      );
      if (response.code === 200 && response.data) {
        this.movieTypes = response.data;
      }
    } catch (error) {
      console.error('请求电影类型异常:', error);
    }
  }

  /**
   * 根据类型ID获取电影列表
   */
  async getMoviesByType(typeId: number) {
    this.selectedTypeId = typeId;
    try {
      let url: string;
      if (typeId === -1) {
        url = `/user/movie/list?typeId=0`;
      } else {
        url = `/user/movie/list?typeId=${typeId}`;
      }
      const response = await HttpUtil.get<HttpResponseResult<Movie[]>>(url);
      if (response.code === 200 && response.data) {
        this.moviesByType = response.data;
      } else {
        this.moviesByType = [];
      }
    } catch (error) {
      console.error('请求类型电影异常:', error);
      this.moviesByType = [];
    }
  }

  /**
   * 切换类型
   */
  selectType(typeId: number) {
    if (this.selectedTypeId !== typeId) {
      this.getMoviesByType(typeId);
    }
  }

  /**
   * 获取完整的图片URL
   */
  getFullImageUrl(path: string): string {
    if (!path) return '';
    return HttpUtil.BASE_URL + path;
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

  build() {
    Row() {
      // ===== 左侧：类型列表=====
      List({ space: 1 }) {
        ListItem() {
          Column() {
            Text("全部")
              .fontSize(16)
              .fontWeight(this.selectedTypeId === -1 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.selectedTypeId === -1 ? '#1698CE' : '#333333')
          }
          .width('100%')
          .height(50)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.selectedTypeId === -1 ? '#E8F4FD' : 'transparent')
        }
        .onClick(() => {
          this.selectType(-1);
        })
        ForEach(this.movieTypes, (type: MovieType) => {
          ListItem() {
            Column() {
              Text(type.typeName)
                .fontSize(16)
                .fontWeight(this.selectedTypeId === type.id ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedTypeId === type.id ? '#ff1185b8' : '#333333')
            }
            .width('100%')
            .height(50)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.selectedTypeId === type.id ? '#E8F4FD' : 'transparent')
          }
          .onClick(() => {
            this.selectType(type.id);
          })
        }, (type: MovieType) => type.id.toString())
      }
      .width(80)
      .height('100%')
      .backgroundColor('#F5F5F5')
      .divider({ strokeWidth: 1, color: '#EEEEEE' })
      .scrollBar(BarState.Auto)

      // ===== 右侧：电影网格 =====
      Column() {
        // 顶部标题
        Row() {
          Text("影片库")
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
          Blank()
          Text(`${this.moviesByType.length}部影片`)
            .fontSize(13)
            .fontColor('#999999')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        // 滚动容器：包裹网格内容，实现右侧滚动
        Scroll() {
          Column() {
            // 分支1：正在加载中
            if (this.isLoading) {
              Column() {
                LoadingProgress()
                  .width(40)
                  .height(40)
                  .color('#1698CE')
              }
              .width('100%')
              .height(300)
              .justifyContent(FlexAlign.Center)
            }
            // 分支2：加载完成，但是没有电影数据
            else if (this.moviesByType.length === 0) {
              Column() {
                Text('🎬')
                  .fontSize(48)
                Text('暂无影片')
                  .fontSize(16)
                  .fontColor('#999999')
                  .margin({ top: 12 })
              }
              .width('100%')
              .height(300)
              .justifyContent(FlexAlign.Center)
            }
            // 分支3：加载完成，有电影数据并显示
            else {
              GridRow({
                breakpoints: this.breakpoints,
                columns: { xs: 2, sm: 4, md: 8, lg: 12 }
              }) {
                ForEach(this.moviesByType, (movie: Movie) => {
                  GridCol() {
                    Column() {
                      // 电影海报
                      Image(this.getFullImageUrl(movie.posterUrl))
                        .width('100%')
                        .aspectRatio(2 / 3)
                        .objectFit(ImageFit.Cover)
                        .borderRadius(8)
                        .backgroundColor('#E0E0E0')

                      // 电影名称
                      Text(movie.movieName)
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .margin({ top: 6 })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                        .textAlign(TextAlign.Center)

                      // 评分
                      Row() {
                        if (movie.movieRating) {
                          Rating({
                            rating: Number(movie.movieRating) / 2,
                            indicator: true
                          })
                            .stars(5)
                            .stepSize(0.5)
                            .width(60)
                          Text(`${movie.movieRating}分`)
                            .fontSize(11)
                            .fontColor('#FF9800')
                            .margin({ left: 4 })
                        } else {
                          Text("暂无评分")
                            .fontSize(12)
                            .fontColor('#CCCCCC')
                        }
                      }
                      .margin({ top: 2 })
                      .width('100%')
                      .justifyContent(FlexAlign.Center)
                    }
                    .width('100%')
                    .padding({ left: 8, right: 8 }) // 横向影片间隔
                    .margin({ bottom: 16 }) // 上下两行影片间距
                    .onClick(() => {
                      this.goToMovieDetail(movie.id);
                    })
                  }
                }, (movie: Movie) => movie.id.toString())
              }
              .width('100%')
              .padding({ left: 8, right: 8, bottom: 16 })
            }
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}