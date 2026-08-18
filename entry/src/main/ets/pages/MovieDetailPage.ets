import HttpUtil from '../http/HttpUtil';
import { HttpResponseResult } from '../model/HttpResponseResult';
import { Movie } from '../model/Movie';
import { MovieComment } from '../model/MovieComment';
import { UserAccount } from '../model/UserAccount';
import {
  formatCommentDate,
  formatMovieDate,
  getCommentUserName,
  getMovieTypeText,
  isCurrentUserStateRequest,
  ratingToStars,
  starsToRating
} from '../common/MovieDetailUtil';

interface FavoriteToggleResult {
  favorited: boolean;
}

interface FavoriteToggleRequest {
  userId: number;
  movieId: number;
}

interface CommentAddRequest {
  userId: number;
  movieId: number;
  rating: number;
  content: string;
}

interface CommentUpdateRequest {
  id: number;
  userId: number;
  movieId: number;
  rating: number;
  content: string;
}

@Entry
@Component
export struct MovieDetailPage {
  // ===== 页面状态 =====
  @StorageLink('userAccount')
  userAccount: UserAccount | null = null;

  @State movie: Movie | null = null;
  @State comments: MovieComment[] = [];
  @State myComment: MovieComment | null = null;
  @State selectedStars: number = 0;
  @State commentContent: string = '';
  @State isFavorite: boolean = false;
  @State isLoading: boolean = true;
  @State isSubmitting: boolean = false;
  @State isTogglingFavorite: boolean = false;
  // loading表示正在请求，loaded表示状态已经成功读取
  @State isMyCommentLoading: boolean = false;
  @State isMyCommentLoaded: boolean = false;
  @State isFavoriteLoading: boolean = false;
  @State isFavoriteLoaded: boolean = false;
  @State errorMessage: string = '';
  @State commentErrorMessage: string = '';

  // ===== 请求参数和用户状态 =====
  private movieId: number = 0;
  private loadedUserId: number = -1;
  private myCommentRequestId: number = 0;
  private favoriteRequestId: number = 0;

  // ===== 生命周期 =====
  aboutToAppear(): void {
    const params: Record<string, Object> =
      this.getUIContext().getRouter().getParams() as Record<string, Object>;
    this.movieId = (params?.movieId as number) ?? 0;

    if (this.movieId <= 0) {
      this.isLoading = false;
      this.errorMessage = '影片信息不存在';
      return;
    }
    this.loadPageData();
  }

  onPageShow(): void {
    const userId: number = this.userAccount ? this.userAccount.id : 0;
    if (!this.isLoading && this.movie && userId !== this.loadedUserId) {
      this.loadUserMovieState();
    }
  }

  // 加载影片、评论及当前用户状态
  async loadPageData(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    await this.loadMovieDetail();
    if (this.movie) {
      await this.loadComments();
      await this.loadUserMovieState();
    }
    this.isLoading = false;
  }

  // 获取影片详情
  async loadMovieDetail(): Promise<void> {
    try {
      const response: HttpResponseResult<Movie> =
        await HttpUtil.get<HttpResponseResult<Movie>>(
          `/user/movie/detail?movieId=${this.movieId}`
        );

      if (response.code === 200 && response.data) {
        this.movie = response.data;
      } else {
        this.movie = null;
        this.errorMessage = response.message || '影片详情加载失败';
      }
    } catch (error) {
      console.error('获取影片详情异常:', error);
      this.movie = null;
      this.errorMessage = '影片详情加载失败';
    }
  }

  // 获取全部评论
  async loadComments(): Promise<void> {
    this.commentErrorMessage = '';
    try {
      const response: HttpResponseResult<MovieComment[]> =
        await HttpUtil.get<HttpResponseResult<MovieComment[]>>(
          `/user/movie/comment/list?movieId=${this.movieId}`
        );

      if (response.code === 200) {
        this.comments = response.data || [];
      } else {
        this.comments = [];
        this.commentErrorMessage = response.message || '评论加载失败';
      }
    } catch (error) {
      console.error('获取影片评论异常:', error);
      this.comments = [];
      this.commentErrorMessage = '评论加载失败';
    }
  }

  // 登录状态变化后重新读取个人评论和收藏状态
  async loadUserMovieState(): Promise<void> {
    this.loadedUserId = this.userAccount ? this.userAccount.id : 0;
    this.myComment = null;
    this.selectedStars = 0;
    this.commentContent = '';
    this.isFavorite = false;
    this.isMyCommentLoading = false;
    this.isMyCommentLoaded = false;
    this.isFavoriteLoading = false;
    this.isFavoriteLoaded = false;

    if (!this.userAccount) {
      this.myCommentRequestId++;
      this.favoriteRequestId++;
      return;
    }

    await Promise.all([
      this.loadMyComment(),
      this.loadFavoriteStatus()
    ]);
  }

  // 获取当前用户对影片的评论
  async loadMyComment(): Promise<void> {
    const userId: number = this.userAccount ? this.userAccount.id : 0;
    if (userId <= 0) {
      return;
    }

    const requestId: number = ++this.myCommentRequestId;
    this.isMyCommentLoading = true;
    this.isMyCommentLoaded = false;
    try {
      const response: HttpResponseResult<MovieComment> =
        await HttpUtil.get<HttpResponseResult<MovieComment>>(
          `/user/movie/comment/my?userId=${userId}&movieId=${this.movieId}`
        );

      const currentUserId: number = this.userAccount ? this.userAccount.id : 0;
      if (!isCurrentUserStateRequest(userId, currentUserId, requestId, this.myCommentRequestId)) {
        return;
      }
      if (response.code === 200) {
        this.isMyCommentLoaded = true;
        if (response.data) {
          this.myComment = response.data;
          this.selectedStars = ratingToStars(response.data.rating);
          this.commentContent = response.data.content;
        }
      }
    } catch (error) {
      const currentUserId: number = this.userAccount ? this.userAccount.id : 0;
      if (!isCurrentUserStateRequest(userId, currentUserId, requestId, this.myCommentRequestId)) {
        return;
      }
      console.error('获取我的评论异常:', error);
    } finally {
      const currentUserId: number = this.userAccount ? this.userAccount.id : 0;
      if (isCurrentUserStateRequest(userId, currentUserId, requestId, this.myCommentRequestId)) {
        this.isMyCommentLoading = false;
      }
    }
  }

  // 获取当前用户的收藏状态
  async loadFavoriteStatus(): Promise<void> {
    const userId: number = this.userAccount ? this.userAccount.id : 0;
    if (userId <= 0) {
      return;
    }

    const requestId: number = ++this.favoriteRequestId;
    this.isFavoriteLoading = true;
    this.isFavoriteLoaded = false;
    try {
      const response: HttpResponseResult<boolean> =
        await HttpUtil.get<HttpResponseResult<boolean>>(
          `/user/favorite/check?userId=${userId}&movieId=${this.movieId}`
        );
      const currentUserId: number = this.userAccount ? this.userAccount.id : 0;
      if (!isCurrentUserStateRequest(userId, currentUserId, requestId, this.favoriteRequestId)) {
        return;
      }
      if (response.code === 200) {
        this.isFavorite = response.data === true;
        this.isFavoriteLoaded = true;
      }
    } catch (error) {
      const currentUserId: number = this.userAccount ? this.userAccount.id : 0;
      if (!isCurrentUserStateRequest(userId, currentUserId, requestId, this.favoriteRequestId)) {
        return;
      }
      console.error('获取收藏状态异常:', error);
    } finally {
      const currentUserId: number = this.userAccount ? this.userAccount.id : 0;
      if (isCurrentUserStateRequest(userId, currentUserId, requestId, this.favoriteRequestId)) {
        this.isFavoriteLoading = false;
      }
    }
  }

  // ===== 评论和收藏操作 =====
  async toggleFavorite(): Promise<void> {
    if (!this.userAccount) {
      this.showToast('请先登录');
      this.goToLogin();
      return;
    }
    if (this.isFavoriteLoading) {
      return;
    }
    if (!this.isFavoriteLoaded) {
      await this.loadFavoriteStatus();
      if (!this.isFavoriteLoaded) {
        this.showToast('收藏状态读取失败');
      }
      return;
    }
    if (this.isTogglingFavorite) {
      return;
    }

    this.isTogglingFavorite = true;
    try {
      const request: FavoriteToggleRequest = {
        userId: this.userAccount.id,
        movieId: this.movieId
      };
      const response: HttpResponseResult<FavoriteToggleResult> =
        await HttpUtil.post<HttpResponseResult<FavoriteToggleResult>>(
          '/user/favorite/toggle',
          request
        );

      if (response.code === 200 && response.data) {
        this.isFavorite = response.data.favorited;
        this.showToast(this.isFavorite ? '收藏成功' : '已取消收藏');
      } else {
        this.showToast(response.message || '收藏操作失败');
      }
    } catch (error) {
      console.error('切换收藏状态异常:', error);
      this.showToast('收藏操作失败');
    } finally {
      this.isTogglingFavorite = false;
    }
  }

  async submitComment(): Promise<void> {
    if (!this.userAccount) {
      this.showToast('请先登录');
      this.goToLogin();
      return;
    }
    if (this.isMyCommentLoading) {
      return;
    }
    if (!this.isMyCommentLoaded) {
      this.showToast('请先重新读取评论状态');
      return;
    }
    if (this.selectedStars <= 0) {
      this.showToast('请选择评分');
      return;
    }

    const content: string = this.commentContent.trim();
    if (content.length === 0) {
      this.showToast('请输入评论内容');
      return;
    }
    if (this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    try {
      let response: HttpResponseResult<void>;
      if (this.myComment) {
        const request: CommentUpdateRequest = {
          id: this.myComment.id,
          userId: this.userAccount.id,
          movieId: this.movieId,
          rating: starsToRating(this.selectedStars),
          content: content
        };
        response = await HttpUtil.post<HttpResponseResult<void>>(
          '/user/movie/comment/update',
          request
        );
      } else {
        const request: CommentAddRequest = {
          userId: this.userAccount.id,
          movieId: this.movieId,
          rating: starsToRating(this.selectedStars),
          content: content
        };
        response = await HttpUtil.post<HttpResponseResult<void>>(
          '/user/movie/comment/add',
          request
        );
      }

      if (response.code === 200) {
        this.showToast(this.myComment ? '评论更新成功' : '评论发表成功');
        await this.loadMovieDetail();
        await this.loadComments();
        await this.loadMyComment();
      } else {
        this.showToast(response.message || '评论提交失败');
      }
    } catch (error) {
      console.error('提交影片评论异常:', error);
      this.showToast('评论提交失败');
    } finally {
      this.isSubmitting = false;
    }
  }

  // ===== 页面跳转 =====
  goBack(): void {
    this.getUIContext().getRouter().back();
  }

  goToLogin(): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/LoginPage'
    });
  }

  goToBuy(): void {
    if (!this.movie) {
      return;
    }
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/MovieCinemaListPage',
      params: {
        movieId: this.movie.id,
        movieName: this.movie.movieName,
        posterUrl: this.movie.posterUrl
      }
    });
  }

  showToast(message: string): void {
    this.getUIContext().getPromptAction().showToast({
      message: message
    });
  }

  // ===== 页面显示内容 =====
  getImageUrl(path: string): string {
    if (!path) {
      return '';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return HttpUtil.BASE_URL + path;
  }

  getMovieType(): string {
    if (!this.movie) {
      return '类型待定';
    }
    return getMovieTypeText(this.movie.movieTypes, this.movie.type || '');
  }

  getMovieRatingText(): string {
    if (!this.movie || !this.movie.movieRating) {
      return '暂无评分';
    }
    return `${Number(this.movie.movieRating).toFixed(1)}分`;
  }

  getCommentAvatarUrl(comment: MovieComment): string {
    if (!comment.userAccount?.avatarUrl) {
      return '';
    }
    return this.getImageUrl(comment.userAccount.avatarUrl);
  }

  getCommentAvatarText(comment: MovieComment): string {
    return getCommentUserName(comment.userAccount).substring(0, 1);
  }

  getFavoriteText(): string {
    if (this.userAccount && this.isFavoriteLoading) {
      return '读取中';
    }
    if (this.userAccount && !this.isFavoriteLoaded) {
      return '重试';
    }
    return this.isFavorite ? '已收藏' : '收藏';
  }

  getFavoriteColor(): string {
    return this.isFavorite && this.isFavoriteLoaded ? '#1698CE' : '#666666';
  }

  // ===== 页面组件 =====
  @Builder
  MovieInfoSection() {
    if (this.movie) {
      Column() {
        Row() {
          Image(this.getImageUrl(this.movie.posterUrl))
            .width(112)
            .height(156)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .backgroundColor('#EEEEEE')

          Column() {
            Text(this.movie.movieName || '未知影片')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#222222')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Row() {
              if (this.movie.movieRating) {
                Text(this.getMovieRatingText())
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF9800')
                Rating({
                  rating: ratingToStars(this.movie.movieRating),
                  indicator: true
                })
                  .stars(5)
                  .stepSize(0.5)
                  .width(72)
                  .margin({ left: 8 })
              } else {
                Text('暂无评分')
                  .fontSize(14)
                  .fontColor('#999999')
              }
            }
            .margin({ top: 12 })

            Text(this.getMovieType())
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 10 })

            Text(`${this.movie.duration || 0}分钟`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 7 })

            Text(`${formatMovieDate(this.movie.releaseDate || '')}上映`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 7 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Text(`导演：${this.movie.director || '待更新'}`)
          .fontSize(14)
          .fontColor('#555555')
          .margin({ top: 14 })

        Text(`主演：${this.movie.actors || '待更新'}`)
          .fontSize(14)
          .fontColor('#555555')
          .margin({ top: 7 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
  }

  @Builder
  DescriptionSection() {
    if (this.movie) {
      Column() {
        Text('剧情简介')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        Text(this.movie.description || '暂无剧情简介')
          .fontSize(14)
          .fontColor('#555555')
          .lineHeight(23)
          .margin({ top: 12 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
  }

  @Builder
  CommentEditor() {
    Column() {
      Row() {
        Text('评分与评论')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')
          .layoutWeight(1)

        Text(this.getMovieRatingText())
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.movie?.movieRating ? '#FF9800' : '#999999')
      }
      .width('100%')

      Divider()
        .color('#EEEEEE')
        .margin({ top: 14, bottom: 14 })

      if (this.userAccount) {
        if (this.isMyCommentLoading) {
          Row() {
            LoadingProgress()
              .width(24)
              .height(24)
              .color('#1698CE')

            Text('正在读取我的评论...')
              .fontSize(14)
              .fontColor('#888888')
              .margin({ left: 10 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else if (!this.isMyCommentLoaded) {
          Row() {
            Text('个人评论状态读取失败')
              .fontSize(14)
              .fontColor('#888888')
              .layoutWeight(1)

            Button('重试')
              .width(60)
              .height(32)
              .fontSize(13)
              .fontColor('#FFFFFF')
              .backgroundColor('#1698CE')
              .borderRadius(16)
              .onClick(() => {
                this.loadMyComment();
              })
          }
          .width('100%')
        } else {
          Row() {
            Text(this.myComment ? '修改我的评价' : '写下我的评价')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .layoutWeight(1)

            if (this.selectedStars > 0) {
              Text(`${this.selectedStars.toFixed(1)}星`)
                .fontSize(13)
                .fontColor('#FF9800')
            }
          }
          .width('100%')

          Rating({
            rating: this.selectedStars,
            indicator: false
          })
            .stars(5)
            .stepSize(0.5)
            .width(150)
            .margin({ top: 10 })
            .onChange((value: number) => {
              this.selectedStars = value;
            })

          TextArea({
            placeholder: '说说你对这部影片的看法',
            text: this.commentContent
          })
            .width('100%')
            .height(92)
            .fontSize(14)
            .fontColor('#333333')
            .placeholderColor('#AAAAAA')
            .backgroundColor('#F7F7F7')
            .borderRadius(8)
            .padding(10)
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.commentContent = value;
            })

          Button(this.isSubmitting ? '提交中...' : (this.myComment ? '更新评论' : '发表评论'))
            .width(108)
            .height(36)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#1698CE')
            .borderRadius(18)
            .alignSelf(ItemAlign.End)
            .margin({ top: 12 })
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.submitComment();
            })
        }
      } else {
        Row() {
          Text('登录后可以评分和评论')
            .fontSize(14)
            .fontColor('#888888')
            .layoutWeight(1)

          Button('登录')
            .width(60)
            .height(32)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor('#1698CE')
            .borderRadius(16)
            .onClick(() => {
              this.goToLogin();
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  CommentList() {
    Column() {
      Text(`全部评论 ${this.comments.length}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222222')

      if (this.commentErrorMessage) {
        Text(this.commentErrorMessage)
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 20, bottom: 8 })
          .alignSelf(ItemAlign.Center)
      } else if (this.comments.length === 0) {
        Text('暂无评论，来发表第一条评论吧')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 20, bottom: 8 })
          .alignSelf(ItemAlign.Center)
      } else {
        ForEach(this.comments, (comment: MovieComment, index: number) => {
          Column() {
            Row() {
              if (comment.userAccount?.avatarUrl) {
                Image(this.getCommentAvatarUrl(comment))
                  .width(38)
                  .height(38)
                  .borderRadius(19)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor('#EEEEEE')
              } else {
                Column() {
                  Text(this.getCommentAvatarText(comment))
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#666666')
                }
                .width(38)
                .height(38)
                .borderRadius(19)
                .backgroundColor('#EEEEEE')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              }

              Column() {
                Text(getCommentUserName(comment.userAccount))
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')

                Text(formatCommentDate(comment.createTime || ''))
                  .fontSize(11)
                  .fontColor('#AAAAAA')
                  .margin({ top: 3 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 10 })

              Column() {
                Rating({
                  rating: ratingToStars(comment.rating),
                  indicator: true
                })
                  .stars(5)
                  .stepSize(0.5)
                  .width(65)

                Text(`${comment.rating}分`)
                  .fontSize(11)
                  .fontColor('#FF9800')
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.End)
            }
            .width('100%')

            Text(comment.content)
              .fontSize(14)
              .fontColor('#444444')
              .lineHeight(22)
              .margin({ top: 10, left: 48 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ top: 14, bottom: 14 })

          if (index < this.comments.length - 1) {
            Divider()
              .color('#EEEEEE')
              .margin({ left: 48 })
          }
        }, (comment: MovieComment) => comment.id.toString())
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  BottomActionBar() {
    Row() {
      Column() {
        SymbolGlyph($r('sys.symbol.heart'))
          .fontSize(25)
          .fontColor([this.getFavoriteColor()])

        Text(this.getFavoriteText())
          .fontSize(12)
          .fontColor(this.getFavoriteColor())
          .margin({ top: 2 })
      }
      .width(84)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.toggleFavorite();
      })

      Button('购票')
        .layoutWeight(1)
        .height(42)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#1698CE')
        .borderRadius(21)
        .margin({ left: 8, right: 16 })
        .onClick(() => {
          this.goToBuy();
        })
    }
    .width('100%')
    .height(66)
    .backgroundColor('#FFFFFF')
  }

  // ===== 页面 =====
  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#333333'])
          .onClick(() => {
            this.goBack();
          })

        Text('影片详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(24)
      }
      .width('100%')
      .height(50)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(35)
            .height(35)
            .color('#1698CE')

          Text('正在加载影片详情...')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 10 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (!this.movie) {
        Column() {
          Text(this.errorMessage || '影片详情加载失败')
            .fontSize(15)
            .fontColor('#999999')

          Button('重新加载')
            .width(96)
            .height(36)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#1698CE')
            .borderRadius(18)
            .margin({ top: 16 })
            .onClick(() => {
              this.loadPageData();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 10 }) {
            this.MovieInfoSection();
            this.DescriptionSection();
            this.CommentEditor();
            this.CommentList();
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)

        this.BottomActionBar();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
