import { curves, window, display, mediaquery, UIContext } from '@kit.ArkUI';
import { UIAbility } from '@kit.AbilityKit';
import { Movie } from '../model/Movie';
import HttpUtil from '../http/HttpUtil';

export default class GlobalContext extends AppStorage {
  static mainWin: window.Window | undefined = undefined;
  static mainWindowSize: window.Size | undefined = undefined;
}

/**
 * 窗口、屏幕相关信息管理类
 */
export class WindowManager {
  private static instance: WindowManager | null = null;
  private displayInfo: display.Display | null = null;
  private uiContext: UIContext;
  private orientationListener: mediaquery.MediaQueryListener;

  constructor(uiContext: UIContext) {
    this.uiContext = uiContext;
    this.orientationListener = this.uiContext.getMediaQuery().matchMediaSync('(orientation: landscape)');
    this.orientationListener.on('change', (mediaQueryResult: mediaquery.MediaQueryResult) => {
      this.onPortrait(mediaQueryResult);
    });
    this.loadDisplayInfo();
  }

  /**
   * 设置主window窗口
   * @param win 当前app窗口
   */
  setMainWin(win: window.Window) {
    if (win == null) {
      return;
    }
    GlobalContext.mainWin = win;
    win.on('windowSizeChange', (data: window.Size) => {
      if (GlobalContext.mainWindowSize == undefined || GlobalContext.mainWindowSize == null) {
        GlobalContext.mainWindowSize = data;
      } else {
        if (GlobalContext.mainWindowSize.width == data.width && GlobalContext.mainWindowSize.height == data.height) {
          return;
        }
        GlobalContext.mainWindowSize = data;
      }

      let winWidth = this.getMainWindowWidth();
      AppStorage.setOrCreate<number>('mainWinWidth', winWidth);
      let winHeight = this.getMainWindowHeight();
      AppStorage.setOrCreate<number>('mainWinHeight', winHeight);
      let context: UIAbility = new UIAbility();
      context.context.eventHub.emit('windowSizeChange', winWidth, winHeight);
    });
  }

  static getInstance(uiContext: UIContext): WindowManager {
    if (WindowManager.instance == null) {
      WindowManager.instance = new WindowManager(uiContext);
    }
    return WindowManager.instance;
  }

  private onPortrait(mediaQueryResult: mediaquery.MediaQueryResult) {
    if (mediaQueryResult.matches == AppStorage.get<boolean>('isLandscape')) {
      return;
    }
    AppStorage.setOrCreate<boolean>('isLandscape', mediaQueryResult.matches);
    this.loadDisplayInfo();
  }

  /**
   * 切换屏幕方向
   * @param ori 常量枚举值：window.Orientation
   */
  changeOrientation(ori: window.Orientation) {
    if (GlobalContext.mainWin != null) {
      GlobalContext.mainWin.setPreferredOrientation(ori);
    }
  }

  private loadDisplayInfo() {
    this.displayInfo = display.getDefaultDisplaySync();
    AppStorage.setOrCreate<number>('displayWidth', this.getDisplayWidth());
    AppStorage.setOrCreate<number>('displayHeight', this.getDisplayHeight());
  }

  /**
   * 获取main窗口宽度，单位vp
   */
  getMainWindowWidth(): number {
    return GlobalContext.mainWindowSize != null ? this.uiContext.px2vp(GlobalContext.mainWindowSize.width) : 0;
  }

  /**
   * 获取main窗口高度，单位vp
   */
  getMainWindowHeight(): number {
    return GlobalContext.mainWindowSize != null ? this.uiContext.px2vp(GlobalContext.mainWindowSize.height) : 0;
  }

  /**
   * 获取屏幕宽度，单位vp
   */
  getDisplayWidth(): number {
    return this.displayInfo != null ? this.uiContext.px2vp(this.displayInfo.width) : 0;
  }

  /**
   * 获取屏幕高度，单位vp
   */
  getDisplayHeight(): number {
    return this.displayInfo != null ? this.uiContext.px2vp(this.displayInfo.height) : 0;
  }

  /**
   * 释放资源
   */
  release() {
    if (this.orientationListener) {
      this.orientationListener.off('change', (mediaQueryResult: mediaquery.MediaQueryResult) => {
        this.onPortrait(mediaQueryResult);
      });
    }
    if (GlobalContext.mainWin != null) {
      GlobalContext.mainWin.off('windowSizeChange');
    }
    WindowManager.instance = null;
  }
}

@Entry
@Component
export struct MovieListScroll {
  displayWidth: number = WindowManager.getInstance(this.getUIContext()).getDisplayWidth();
  scroller: Scroller = new Scroller();
  cardSpace: number = 10; // 卡片间距
  cardWidth: number = 135; // 卡片宽度
  cardHeight: number = 200; // 卡片高度
  cardPosition: Array<number> = []; // 卡片初始位置
  startTime: number | undefined = undefined;
  @State taskViewOffsetX: number = 0;
  @State cardOffset: number = 0;
  lastCardOffset: number = 0;
  @Link @Watch("onIndexChange") currentIndex: number  //居中的索引
  @Link movies:Movie[]
  // 每个卡片初始位置
  aboutToAppear() {
    for (let i = 0; i < this.movies.length; i++) {
      this.cardPosition[i] = i * (this.cardWidth + this.cardSpace);
    }
    const itemWidth = this.cardWidth + this.cardSpace;
    this.cardOffset = -(this.currentIndex * itemWidth);
    this.lastCardOffset = this.cardOffset;
  }
  onIndexChange() {
    if (this.movies.length === 0) return;

    const itemWidth = this.cardWidth + this.cardSpace;
    const idx = Math.min(Math.max(0, this.currentIndex), this.movies.length - 1);

    animateTo({
      duration: 300,
      curve: curves.springMotion()
    }, () => {
      this.cardOffset = -(idx * itemWidth);
      this.lastCardOffset = this.cardOffset;
    });
  }
  // 每个卡片位置
  getProgress(index: number): number {
    const itemWidth = this.cardWidth + this.cardSpace;
    const cardCenter = index * itemWidth + this.cardWidth / 2;
    const currentPosition = this.cardOffset;
    const visualOffset = this.displayWidth / 2 - this.cardWidth / 2;
    // ✅ 相对于屏幕中心的进度
    const relativeCenter = cardCenter + currentPosition + visualOffset;
    return relativeCenter / this.displayWidth;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 滑动组件
      Scroll(this.scroller) {
        Row({ space: this.cardSpace }) {
          ForEach(this.movies, (item: Movie, index) => {
            Image(HttpUtil.BASE_URL + item.posterUrl)
              .width(this.cardWidth)
              .height(this.cardHeight)
              .borderRadius(5)
              // 计算子组件的仿射属性
              .scale((this.getProgress(index) >= 0.4 && this.getProgress(index) <= 0.6) ?
                {
                  x: 1.2 - Math.abs(0.5 - this.getProgress(index)),
                  y: 1.2 - Math.abs(0.5 - this.getProgress(index))
                } :
                { x: 1, y: 1 })
              .animation({ curve: Curve.Smooth })
              // 滑动动画
              .translate({ x: this.cardOffset })
              .animation({ curve: curves.springMotion() })
              .zIndex((this.getProgress(index) >= 0.4 && this.getProgress(index) <= 0.6) ? 2 : 1)
          })
        }
        .width((this.cardWidth + this.cardSpace) * (this.movies.length + 1))
        .height('100%')
        .padding({ left: this.displayWidth / 2 - this.cardWidth / 2 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .gesture(
        GestureGroup(GestureMode.Parallel,
          PanGesture({ direction: PanDirection.Horizontal, distance: 5 })
            .onActionStart((event: GestureEvent | undefined) => {
              if (event) {
                this.startTime = event.timestamp;
              }
            })
            .onActionUpdate((event) => {
              let offset = this.lastCardOffset + event.offsetX;

              const itemWidth = this.cardWidth + this.cardSpace;
              offset = Math.max(offset, -(this.movies.length - 1) * itemWidth);
              offset = Math.min(offset, 0);

              this.cardOffset = offset;
            })
            .onActionEnd(() => {
              const itemWidth = this.cardWidth + this.cardSpace;
              let idx = Math.round(-this.cardOffset / itemWidth);
              idx = Math.min(Math.max(0, idx), this.movies.length - 1);
              this.currentIndex = idx;
              animateTo({
                duration: 300,
                curve: curves.springMotion(0.6, 0.8)
              }, () => {
                this.cardOffset = -(idx * itemWidth);
                this.lastCardOffset = this.cardOffset;
              });
            })
        ), GestureMask.IgnoreInternal)
    }
    .width('100%')
    .height('100%')
  }
}