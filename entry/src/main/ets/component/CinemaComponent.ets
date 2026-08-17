import { router } from '@kit.ArkUI';
import HttpUtil from '../http/HttpUtil';
import { HttpResponseResult } from '../model/HttpResponseResult';
import { Cinema } from '../model/Cinema';

@Entry
@Component
export struct CinemaComponent {
  // ===== 状态变量 =====
  @State cinemas: Cinema[] = [];
  @State filteredCinemas: Cinema[] = [];
  @State bannerCinemas: Cinema[] = [];
  @State isLoading: boolean = true;
  @State isLoadingBanner: boolean = true;
  @State city: string = '全国';
  @State searchText: string = '';
  @State showCitySelector: boolean = false;

  // ===== 生命周期 =====
  aboutToAppear(): void {
    this.loadAllData();
  }

  /**
   * 加载所有数据
   */
  async loadAllData() {
    await Promise.all([
      this.loadBannerCinemas(),
      this.loadCinemas()
    ]);
  }

  /**
   * 加载轮播图影院数据（取前3个影院）
   */
  async loadBannerCinemas() {
    this.isLoadingBanner = true;
    try {
      const response = await HttpUtil.get<HttpResponseResult<Cinema[]>>(
        '/user/cinema/list'
      );
      if (response.code === 200 && response.data) {
        this.bannerCinemas = response.data.slice(0, 3);
        console.info('轮播图影院数量:', this.bannerCinemas.length);
      }
    } catch (error) {
      console.error('加载轮播图失败:', error);
    } finally {
      this.isLoadingBanner = false;
    }
  }

  /**
   * 加载影院列表
   */
  async loadCinemas() {
    this.isLoading = true;
    try {
      const params: Record<string, string> = {};
      if (this.city !== '全国') {
        params.city = this.city;
      }

      const response = await HttpUtil.get<HttpResponseResult<Cinema[]>>(
        '/user/cinema/list',
        params
      );

      if (response.code === 200 && response.data) {
        this.cinemas = response.data;
        this.applySearchFilter();
        console.info('影院数量:', this.cinemas.length);
      } else {
        console.error('获取影院列表失败:', response.message);
        this.cinemas = [];
        this.filteredCinemas = [];
      }
    } catch (error) {
      console.error('请求影院列表异常:', error);
      this.cinemas = [];
      this.filteredCinemas = [];
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 应用搜索过滤（本地过滤，匹配影院名称，支持中文）
   */
  applySearchFilter() {
    const keyword = this.searchText.trim();
    if (!keyword) {
      this.filteredCinemas = [...this.cinemas];
      return;
    }
    this.filteredCinemas = this.cinemas.filter(cinema => {
      const cinemaName = cinema.cinemaName ?? '';
      return cinemaName.includes(keyword);
    });
    console.info('筛选后影院数量:', this.filteredCinemas.length);
  }

  /**
   * 搜索影院（输入时触发）
   */
  onSearchInput(value: string) {
    this.searchText = value;
    this.applySearchFilter();
  }

  /**
   * 搜索提交
   */
  onSearchSubmit(value: string) {
    this.searchText = value;
    this.applySearchFilter();
  }

  /**
   * 切换城市
   */
  selectCity(city: string) {
    this.city = city;
    this.showCitySelector = false;
    this.searchText = '';
    this.loadCinemas();
  }

  /**
   * 获取完整的图片URL
   */
  getFullImageUrl(path: string): string {
    if (!path) return '';
    return HttpUtil.BASE_URL + path;
  }

  /**
   * 跳转到影院详情
   */
  goToCinemaDetail(cinemaId: number) {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/CinemaDetail',
      params: { cinemaId: cinemaId }
    });
  }

  /**
   * 获取设施标签列表
   */
  getFacilityTags(facilities: string): string[] {
    if (!facilities) return [];
    return facilities.split(',').map(tag => tag.trim());
  }

  build() {
    Column() {
      // ===== 1. 轮播图 =====
        Swiper() {
          ForEach(this.bannerCinemas, (cinema: Cinema) => {
            Stack() {
              Image(this.getFullImageUrl(cinema.imageUrl || '/images/cinema/default.jpg'))
                .width("100%")
                .height("100%")
                .objectFit(ImageFit.Cover)
                .backgroundColor('#E0E0E0')

              // 底部影院名称遮罩
              Column() {
                Text(cinema.cinemaName)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width("100%")
              .height(50)
              .padding({ left: 16 })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Start)
              .backgroundColor('rgba(0,0,0,0.4)')
            }
            .width('100%')
            .height('100%')
            .alignContent(Alignment.Bottom) // 遮罩停靠在Stack底部
            .onClick(() => {
              this.goToCinemaDetail(cinema.id);
            })
          }, (cinema: Cinema) => cinema.id.toString())
        }
        .width("100%")
        .height(160)
        .loop(true)
        .autoPlay(true)
        .interval(5000)
        .indicator(true)


      // ===== 2. 顶部搜索栏 =====
      Row() {
        // 城市选择按钮
        Row() {
          Text(this.city)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(14)
            .fontColor(['#999999'])
        }
        .padding({ left: 12, right: 8, top: 6, bottom: 6 })
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .onClick(() => {
          this.showCitySelector = !this.showCitySelector;
        })

        // 搜索框
        Search({
          placeholder: '请输入影院名称',
          value: this.searchText
        })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ left: 8 })
          .onSubmit((value: string) => {
            this.onSearchSubmit(value);
          })
          .onChange((value: string) => {
            this.onSearchInput(value);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor('#FFFFFF')

      // ===== 3. 影院列表 =====
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#1698CE')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.filteredCinemas.length === 0) {
        Column() {
          Text('🏠')
            .fontSize(48)
          Text(this.searchText.trim() ? '未找到匹配的影院' : '暂无影院')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 12 })
          Text(this.searchText.trim() ? '请尝试其他关键词' : '尝试更换城市或搜索关键词')
            .fontSize(13)
            .fontColor('#CCCCCC')
            .margin({ top: 4 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.filteredCinemas, (cinema: Cinema) => {
            ListItem() {
              // ===== 影院卡片 =====
              Column() {
                // 顶部：影院名称 + 价格
                Row() {
                  Text(cinema.cinemaName)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)

                  Text('39.9起')
                    .fontSize(14)
                    .fontColor('#FF6B35')
                    .fontWeight(FontWeight.Medium)
                    .margin({ left: 8 })
                }
                .width('100%')

                // 地址
                Row() {
                  SymbolGlyph($r('sys.symbol.map'))
                    .fontSize(14)
                    .fontColor(['#999999'])
                  Text(cinema.address || '地址待更新')
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ left: 4 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .margin({ top: 4 })

                // 设施标签
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.getFacilityTags(cinema.facilities), (tag: string) => {
                    Text(tag)
                      .fontSize(11)
                      .fontColor('#ff156b91')
                      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                      .backgroundColor('#ff99c4e5')
                      .borderRadius(4)
                      .margin({ right: 6, bottom: 6 }) // 标签之间间距
                  }, (tag: string, index: number) => tag + index)
                }
                .width('100%')
                .margin({ top: 6 })

                // 营业时间
                Row() {
                  SymbolGlyph($r('sys.symbol.clock'))
                    .fontSize(14)
                    .fontColor(['#999999'])
                  Text(`营业时间：${cinema.businessHours || '待更新'}`)
                    .fontSize(13)
                    .fontColor('#999999')
                    .margin({ left: 4 })
                }
                .width('100%')
                .margin({ top: 4 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
              .margin({ bottom: 12 })
              .onClick(() => {
                this.goToCinemaDetail(cinema.id);
              })
            }
          }, (cinema: Cinema) => cinema.id.toString())
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
        .scrollBar(BarState.Auto)
        .padding({ left: 16, right: 16, top: 10, bottom: 75 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}