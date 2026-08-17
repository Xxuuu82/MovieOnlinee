// pages/OrderListPage.ets
import httpUtil from '../http/HttpUtil';
import { HttpResponseResult } from '../model/HttpResponseResult';
import { UserAccount } from '../model/UserAccount';
import { Order } from '../model/Order';
import { OrderStatus, getOrderStatusText, getOrderStatusColor } from '../model/OrderStatus';
import { formatMonthDate, formatStartTime } from '../common/DateUtil';

// 定义状态标签接口
interface StatusTab {
  label: string;
  value: OrderStatus;
}

@Entry
@Component
struct OrderListPage {
  @State orders: Order[] = [];
  @State filteredOrders: Order[] = [];
  @State currentStatus: OrderStatus = OrderStatus.ALL;
  @State isLoading: boolean = false;
  @StorageLink("userAccount") userAccount: UserAccount | undefined = undefined;

  // 状态筛选标签
  private statusTabs: StatusTab[] = [
    { label: '全部', value: OrderStatus.ALL },
    { label: '待支付', value: OrderStatus.PENDING },
    { label: '已支付', value: OrderStatus.PAID },
    { label: '已取消', value: OrderStatus.CANCELLED },
    { label: '已出票', value: OrderStatus.TICKETED },
    { label: '已退款', value: OrderStatus.REFUNDED },
    { label: '已完成', value: OrderStatus.COMPLETED }
  ];

  async aboutToAppear(): Promise<void> {
    if (!this.userAccount) {
      this.getUIContext().getPromptAction().showToast({
        message: "请先登录",
        bottom: "40%"
      });
      setTimeout(() => {
        this.getUIContext().getRouter().back();
      }, 500);
      return;
    }
    await this.loadOrders();
  }

  async loadOrders(): Promise<void> {
    if (!this.userAccount?.id) return;

    this.isLoading = true;
    try {
      console.log('===== 获取订单列表 =====');
      console.log('userId:', this.userAccount.id);

      const result = await httpUtil.get<HttpResponseResult<Order[]>>(
        `/user/order/list?userId=${this.userAccount.id}`
      );

      console.log('订单列表响应:', JSON.stringify(result));

      if (result.code === 200 && result.data) {
        this.orders = result.data;
        this.filterOrders();
        console.log('订单数量:', this.orders.length);
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: result.message || "加载订单失败",
          bottom: "40%"
        });
      }
    } catch (error) {
      console.error('加载订单异常:', error);
      this.getUIContext().getPromptAction().showToast({
        message: "网络异常，请稍后重试",
        bottom: "40%"
      });
    } finally {
      this.isLoading = false;
    }
  }

  filterOrders(): void {
    if (this.currentStatus === OrderStatus.ALL) {
      this.filteredOrders = this.orders;
    } else {
      this.filteredOrders = this.orders.filter(
        (order: Order) => order.status === this.currentStatus
      );
    }
  }

  getShowTimeString(showTime: string | Date | undefined): string {
    if (!showTime) return '';
    if (typeof showTime === 'string') {
      return showTime;
    }
    return showTime.toISOString();
  }

  getFormattedShowTime(order: Order): string {
    if (!order.schedule?.showTime) return '';
    const showTimeStr = this.getShowTimeString(order.schedule.showTime);
    return formatMonthDate(showTimeStr) + ' ' + formatStartTime(showTimeStr);
  }

  getMoviePoster(order: Order): string {
    const poster = order.schedule?.moviePoster || '';
    return poster ? httpUtil.BASE_URL + poster : '';
  }

  async cancelOrder(orderId: number): Promise<void> {
    try {
      console.log('===== 取消订单 =====');
      console.log('orderId:', orderId);

      const result = await httpUtil.post<HttpResponseResult<object>>(
        `/user/order/cancel?orderId=${orderId}`,
        {}
      );

      console.log('取消订单响应:', JSON.stringify(result));

      if (result.code === 200) {
        this.getUIContext().getPromptAction().showToast({
          message: "订单已取消",
          bottom: "40%"
        });
        await this.loadOrders();
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: result.message || "取消订单失败",
          bottom: "40%"
        });
      }
    } catch (error) {
      console.error('取消订单异常:', error);
      this.getUIContext().getPromptAction().showToast({
        message: "网络异常，请稍后重试",
        bottom: "40%"
      });
    }
  }

  payOrder(order: Order): void {
    console.log('===== 支付订单 =====');
    console.log('orderId:', order.id);
    console.log('总价:', order.totalPrice);

    this.getUIContext().getPromptAction().showToast({
      message: "跳转到支付页面",
      bottom: "40%"
    });
  }

  @Builder
  buildStatusTab(tab: StatusTab) {
    Text(tab.label)
      .fontSize(14)
      .fontWeight(this.currentStatus === tab.value ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.currentStatus === tab.value ? '#1890ff' : '#666666')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .border({
        width: { bottom: this.currentStatus === tab.value ? 2 : 0 },
        color: '#1890ff'
      })
      .onClick(() => {
        this.currentStatus = tab.value;
        this.filterOrders();
      })
  }

  @Builder
  buildOrderItem(order: Order) {
    Column() {
      // 订单头部：影院名 + 状态
      Row() {
        Text(order.schedule?.cinemaName || '未知影院')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Text(getOrderStatusText(order.status))
          .fontSize(14)
          .fontColor(getOrderStatusColor(order.status))
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 8 })

      Divider()
        .height(1)
        .color('#f0f0f0')
        .margin({ left: 12, right: 12 })

      // 订单内容 - 包含海报
      Row() {
        // 电影海报
        Image(this.getMoviePoster(order))
          .width(80)
          .height(110)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
          .margin({ right: 12 })
          .alt($r('app.media.startIcon'))
          .onError(() => {
            console.log(`海报加载失败: ${this.getMoviePoster(order)}`);
          })

        // 订单信息
        Column({ space: 6 }) {
          Text(order.schedule?.movieName || '未知影片')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row() {
            Text("影厅：")
              .fontSize(13)
              .fontColor('#666666')
            Text(order.hallName || order.schedule?.hallName || '未知影厅')
              .fontSize(13)
              .fontColor('#333333')
          }
          .width('100%')

          Row() {
            Text("观影时间：")
              .fontSize(13)
              .fontColor('#666666')
            Text(this.getFormattedShowTime(order))
              .fontSize(13)
              .fontColor('#333333')
          }
          .width('100%')

          Row() {
            Text("座位：")
              .fontSize(13)
              .fontColor('#666666')
            Text(order.seatInfo || '')
              .fontSize(13)
              .fontColor('#333333')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(`(${order.amount || 0}张)`)
              .fontSize(13)
              .fontColor('#666666')
          }
          .width('100%')

          Row() {
            Text("总价格：")
              .fontSize(13)
              .fontColor('#666666')
            Text(`￥${order.totalPrice?.toFixed(2) || '0.00'}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Red)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })

      // 底部操作按钮 - 只有状态为 PENDING(1) 时才显示
      if (order.status === OrderStatus.PENDING) {
        Row() {
          Button("取消订单")
            .fontSize(14)
            .fontColor('#666666')
            .backgroundColor('#f0f0f0')
            .borderRadius(4)
            .height(32)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.cancelOrder(order.id);
            })
          Button("立即支付")
            .fontSize(14)
            .fontColor('#ffffff')
            .backgroundColor('#1890ff')
            .borderRadius(4)
            .height(32)
            .padding({ left: 16, right: 16 })
            .margin({ left: 8 })
            .onClick(() => {
              this.payOrder(order);
            })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 12 })
        .justifyContent(FlexAlign.End)
      } else {
        Row()
          .width('100%')
          .height(12)
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .backgroundColor('#ffffff')
    .borderRadius(8)
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        SymbolGlyph($r("sys.symbol.chevron_left"))
          .fontSize(24)
          .fontColor([Color.Black])
          .padding({ left: 5 })
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Text("我的订单")
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row().width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#ffffff')

      Divider().borderWidth(1)

      // 状态筛选标签 - 使用 Scroll 实现横向滚动
      Scroll() {
        Row() {
          ForEach(this.statusTabs, (tab: StatusTab) => {
            this.buildStatusTab(tab)
          })
        }
        .padding({ left: 8, right: 8 })
        .height(44)
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .backgroundColor('#ffffff')

      // 订单列表
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#1890ff')
            .margin({ top: 60 })
          Text("加载中...")
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.filteredOrders.length === 0) {
        Column() {
          SymbolGlyph($r("sys.symbol.list_bullet"))
            .fontSize(60)
            .fontColor([Color.Gray])
            .margin({ top: 60 })
          Text("暂无订单")
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 })
          Text(this.currentStatus === OrderStatus.ALL ? "快去购买电影票吧" : "该状态暂无订单")
            .fontSize(14)
            .fontColor('#bfbfbf')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.filteredOrders, (order: Order) => {
            ListItem() {
              this.buildOrderItem(order)
            }
            .margin({ left: 16, right: 16, top: 12 })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ bottom: 12 })
      }
    }
    .height("100%")
    .width("100%")
    .backgroundColor('#f5f5f5')
  }
}

export default OrderListPage;