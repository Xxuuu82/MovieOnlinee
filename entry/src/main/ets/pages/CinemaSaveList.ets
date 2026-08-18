import httpUtil from '../http/HttpUtil'
import { UserAccount } from '../model/UserAccount'
import { Movie } from '../model/Movie'

interface ApiResult<T> {
  code: number
  message: string
  data: T
}

interface FavoriteMovie {
  id: number
  userId: number
  movieId: number
  createTime: string
  favoriteMovie: Movie
}

@Entry
@Component
export struct CinemaSaveList {
  @StorageLink('userAccount')
  userAccount: UserAccount | null = null

  @State
  favoriteMovies: FavoriteMovie[] = []

  @State
  isLoading: boolean = true

  aboutToAppear() {
    this.loadFavoriteMovies()
  }

  async loadFavoriteMovies() {
    if (this.userAccount === null || this.userAccount.id === undefined) {
      this.favoriteMovies = []
      this.isLoading = false
      return
    }
    try {
      this.isLoading = true
      let result = await httpUtil.get<ApiResult<FavoriteMovie[]>>(
        `/user/favorite/list?userId=${this.userAccount.id}`
      )
      console.info("收藏数据:" + JSON.stringify(result))
      if (result.code === 200) {
        this.favoriteMovies = result.data || []
      } else {
        this.favoriteMovies = []
      }
    } catch (error) {
      console.error(JSON.stringify(error))
      this.favoriteMovies = []
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 海报地址
   */
  getPosterUrl(path: string): string {
    if (!path) {
      return ''
    }
    if (path.startsWith('http')) {
      return path
    }
    return httpUtil.BASE_URL + path
  }

  /**
   * 类型中文转换
   */
  getTypeName(movie: Movie): string {
    if (movie.movieTypes === undefined || movie.movieTypes.length === 0) {
      return '未知'
    }
    return movie.movieTypes.map(item => item.typeName).join('、')
  }

  formatCreateTime(time: string): string {
    if (!time) {
      return ''
    }
    if (time.includes('T')) {
      return time.split('T')[0]
    }
    return time
  }

  goBack() {
    this.getUIContext().getRouter().back()
  }

  goToMovieDetail(movieId: number) {
    console.info("进入电影详情:" + movieId)
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/MovieDetailPage',
      params: {
        movieId: movieId
      }
    })
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .margin({ left: 8 })
          .fontSize(24)
          .fontColor(['#333333'])
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
          .onClick(() => {
            this.goBack()
          })

        Text('我的收藏')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(24)
      }
      .height(50)
      .width('100%')
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(35)
            .height(35)
          Text('正在加载收藏...')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 10 })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      else if (this.favoriteMovies.length === 0) {
        Column() {
          Text('暂无收藏电影')
            .fontSize(16)
            .fontColor('#999999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      else {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.favoriteMovies, (item: FavoriteMovie) => {
              Row() {
                Image(this.getPosterUrl(item.favoriteMovie.posterUrl))
                  .width(110)
                  .height(150)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)

                Column() {
                  Text(item.favoriteMovie.movieName)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#222222')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Row() {
                    Text('类型')
                      .fontSize(15)
                      .fontWeight(FontWeight.Bold)
                    Text(this.getTypeName(item.favoriteMovie))
                      .fontSize(15)
                      .margin({ left: 10 })
                  }
                  .margin({ top: 14 })

                  Row() {
                    Text('时长')
                      .fontSize(15)
                      .fontWeight(FontWeight.Bold)
                    Text(item.favoriteMovie.duration + '分钟')
                      .fontSize(15)
                      .margin({ left: 10 })
                  }
                  .margin({ top: 8 })

                  Text('收藏于 ' + this.formatCreateTime(item.createTime))
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 8 })
                }
                .layoutWeight(1)
                .margin({ left: 15 })

                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(18)
                  .fontColor(['#777777'])
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(10)
              .onClick(() => {
                this.goToMovieDetail(item.movieId)
              })
            }, (item: FavoriteMovie) => {
              return item.id.toString()
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 12, right: 12, top: 0, bottom: 20 })
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.Top)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}